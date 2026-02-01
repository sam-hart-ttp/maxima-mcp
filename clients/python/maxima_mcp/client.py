"""
Maxima MCP Client

Provides a Python client for communicating with the Maxima MCP server
using JSON-RPC 2.0 over stdio.
"""

import json
import subprocess
import os
import select
import sys
import threading
from collections import deque
from typing import Any, Deque, Dict, List, Optional, Union


class MaximaTimeoutError(Exception):
    """Exception raised when a request times out."""
    pass


class MaximaError(Exception):
    """Exception raised for Maxima-related errors."""

    def __init__(self, message: str, code: Optional[int] = None, data: Any = None):
        super().__init__(message)
        self.code = code
        self.data = data


class MaximaMCPClient:
    """
    Client for interacting with the Maxima MCP server.

    This client manages a subprocess running the Maxima MCP server and
    communicates with it using JSON-RPC 2.0 over stdio.

    Example:
        >>> client = MaximaMCPClient()
        >>> result = client.evaluate("2 + 2")
        >>> print(result)
        4
        >>> result = client.differentiate("x^3", "x")
        >>> print(result)
        3*x^2
    """

    def __init__(
        self,
        server_command: Optional[List[str]] = None,
        server_path: Optional[str] = None,
        timeout: Optional[float] = 30.0,
    ):
        """
        Initialize the Maxima MCP client.

        Args:
            server_command: Command to run the MCP server. If not provided,
                           uses server_path or searches for 'maxima-mcp' in PATH.
            server_path: Path to the maxima-mcp executable.
            timeout: Default timeout in seconds for requests (None = no timeout).
        """
        self._process: Optional[subprocess.Popen] = None
        self._request_id = 0
        self._initialized = False
        self._stderr_thread: Optional[threading.Thread] = None
        self._stderr_buffer: Deque[str] = deque(maxlen=50)
        self._stderr_lock = threading.Lock()
        self._timeout = timeout
        self._is_windows = sys.platform == "win32"

        if server_command:
            self._server_command = server_command
        elif server_path:
            self._server_command = [server_path]
        else:
            # Try to find maxima-mcp in PATH or use a default
            self._server_command = self._find_server_command()

    def _find_server_command(self) -> List[str]:
        """Find the server command to use."""
        # Check for maxima-mcp in PATH
        import shutil

        if shutil.which("maxima-mcp"):
            return ["maxima-mcp"]

        # Check for a local build
        local_paths = [
            "./maxima-mcp",
            "../maxima-mcp",
            "../../maxima-mcp",
        ]
        for path in local_paths:
            if os.path.isfile(path) and os.access(path, os.X_OK):
                return [path]

        # Fall back to running via SBCL with quicklisp
        return [
            "sbcl",
            "--noinform",
            "--non-interactive",
            "--eval",
            "(ql:quickload :maxima-mcp)",
            "--eval",
            "(maxima-mcp:main)",
        ]

    def _ensure_connected(self):
        """Ensure the server process is running."""
        if self._process is None or self._process.poll() is not None:
            self._start_server()

    def _start_server(self):
        """Start the MCP server subprocess."""
        self._process = subprocess.Popen(
            self._server_command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,  # Line buffered
        )
        self._initialized = False
        self._start_stderr_reader()

    def _start_stderr_reader(self):
        """Drain stderr to avoid blocking the server subprocess."""
        if self._process is None or self._process.stderr is None:
            return

        def _drain():
            for line in self._process.stderr:
                if not line:
                    break
                with self._stderr_lock:
                    self._stderr_buffer.append(line.rstrip("\n"))

        self._stderr_thread = threading.Thread(target=_drain, daemon=True)
        self._stderr_thread.start()

    def _readline_with_timeout(self, timeout: Optional[float]) -> Optional[str]:
        """Read a line from stdout with optional timeout.

        Args:
            timeout: Timeout in seconds, or None for no timeout.

        Returns:
            The line read, or None if EOF.

        Raises:
            MaximaTimeoutError: If the read times out.
        """
        if self._process is None or self._process.stdout is None:
            return None

        if timeout is None or self._is_windows:
            # No timeout or Windows (select doesn't work on pipes)
            return self._process.stdout.readline()

        # Use select for timeout on Unix
        stdout_fd = self._process.stdout.fileno()
        ready, _, _ = select.select([stdout_fd], [], [], timeout)
        if not ready:
            raise MaximaTimeoutError(
                self._format_disconnect_error(f"Request timed out after {timeout} seconds")
            )
        return self._process.stdout.readline()

    def _send_request(
        self,
        method: str,
        params: Optional[Dict[str, Any]] = None,
        timeout: Optional[float] = ...,  # Use ellipsis as sentinel for "use default"
    ) -> Dict[str, Any]:
        """Send a JSON-RPC request and return the response.

        Args:
            method: The JSON-RPC method name.
            params: Optional parameters for the method.
            timeout: Timeout in seconds. Use None for no timeout,
                    or omit to use the default timeout from __init__.

        Returns:
            The result from the response.

        Raises:
            MaximaTimeoutError: If the request times out.
            MaximaError: If the server returns an error or disconnects.
        """
        self._ensure_connected()

        # Handle sentinel value for default timeout
        if timeout is ...:
            timeout = self._timeout

        self._request_id += 1
        request = {
            "jsonrpc": "2.0",
            "id": self._request_id,
            "method": method,
            "params": params or {},
        }

        # Send request
        request_json = json.dumps(request)
        self._process.stdin.write(request_json + "\n")
        self._process.stdin.flush()

        # Read response (skip blank lines, with retry limit to avoid infinite loop)
        response_line = self._readline_with_timeout(timeout)
        blank_line_count = 0
        max_blank_lines = 100
        while response_line is not None and response_line.strip() == "":
            blank_line_count += 1
            if blank_line_count > max_blank_lines:
                raise MaximaError(
                    self._format_disconnect_error(
                        f"Server sent {max_blank_lines} consecutive blank lines"
                    )
                )
            response_line = self._readline_with_timeout(timeout)

        if not response_line:
            raise MaximaError(self._format_disconnect_error("Server disconnected unexpectedly"))

        try:
            response = json.loads(response_line)
        except json.JSONDecodeError as exc:
            raise MaximaError(self._format_disconnect_error(f"Invalid JSON from server: {exc}"))

        if response.get("id") != self._request_id:
            raise MaximaError(
                self._format_disconnect_error(
                    f"Out-of-sequence response id {response.get('id')} (expected {self._request_id})"
                )
            )

        # Check for errors
        if "error" in response:
            error = response["error"]
            raise MaximaError(
                error.get("message", "Unknown error"),
                code=error.get("code"),
                data=error.get("data"),
            )

        return response.get("result", {})

    def _initialize(self):
        """Initialize the MCP connection."""
        if not self._initialized:
            self._send_request(
                "initialize",
                {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "maxima-mcp-python", "version": "0.1.0"},
                },
            )
            self._send_request("initialized", {})
            self._initialized = True

    def _call_tool(
        self,
        tool_name: str,
        arguments: Optional[Dict[str, Any]] = None,
        timeout: Optional[float] = ...,
    ) -> str:
        """Call an MCP tool and return the result text.

        Args:
            tool_name: Name of the tool to call.
            arguments: Arguments for the tool.
            timeout: Timeout in seconds. Use None for no timeout,
                    or omit to use the default timeout from __init__.
        """
        self._initialize()

        result = self._send_request(
            "tools/call", {"name": tool_name, "arguments": arguments or {}}, timeout=timeout
        )

        # Extract text content from result
        content = result.get("content", [])
        if content and isinstance(content, list):
            for item in content:
                if isinstance(item, dict) and item.get("type") == "text":
                    text = item.get("text", "")
                    # Check for error
                    if result.get("isError"):
                        raise MaximaError(text)
                    return text
        return ""

    def close(self):
        """Close the connection to the server."""
        if self._process:
            self._process.stdin.close()
            self._process.terminate()
            self._process.wait()
            self._process = None

    def _format_disconnect_error(self, message: str) -> str:
        """Attach recent stderr output to an error message."""
        with self._stderr_lock:
            if not self._stderr_buffer:
                return message
            tail = "\n".join(list(self._stderr_buffer))
        return f"{message}\n--- server stderr (tail) ---\n{tail}"

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False

    # =========================================================================
    # Core Tools
    # =========================================================================

    def evaluate(self, expression: str, format: str = "text") -> str:
        """
        Evaluate a Maxima expression.

        Args:
            expression: The Maxima expression to evaluate.
            format: Output format ('text', 'latex', 'mathml', or 'lisp').

        Returns:
            The result as a string.

        Example:
            >>> client.evaluate("2 + 2")
            '4'
            >>> client.evaluate("diff(x^2, x)")
            '2*x'
        """
        return self._call_tool("evaluate", {"expression": expression, "format": format})

    def solve(
        self, equation: str, variable: str, format: str = "text"
    ) -> str:
        """
        Solve an equation for a variable.

        Args:
            equation: The equation to solve (e.g., "x^2 - 4 = 0").
            variable: The variable to solve for.
            format: Output format.

        Returns:
            The solutions as a string.
        """
        return self._call_tool(
            "solve", {"equation": equation, "variable": variable, "format": format}
        )

    def float_(self, expression: str, format: str = "text") -> str:
        """Convert an expression to floating point."""
        return self._call_tool("float", {"expression": expression, "format": format})

    def bfloat(
        self, expression: str, precision: Optional[int] = None, format: str = "text"
    ) -> str:
        """Convert an expression to arbitrary-precision floating point."""
        args = {"expression": expression, "format": format}
        if precision is not None:
            args["precision"] = precision
        return self._call_tool("bfloat", args)

    # =========================================================================
    # Calculus Tools
    # =========================================================================

    def differentiate(
        self,
        expression: str,
        variable: str,
        order: int = 1,
        format: str = "text",
    ) -> str:
        """
        Compute the derivative of an expression.

        Args:
            expression: The expression to differentiate.
            variable: The variable to differentiate with respect to.
            order: The order of differentiation (default 1).
            format: Output format.

        Returns:
            The derivative as a string.
        """
        return self._call_tool(
            "differentiate",
            {"expression": expression, "variable": variable, "order": order, "format": format},
        )

    def integrate(
        self,
        expression: str,
        variable: str,
        lower: Optional[str] = None,
        upper: Optional[str] = None,
        format: str = "text",
    ) -> str:
        """
        Compute the integral of an expression.

        Args:
            expression: The expression to integrate.
            variable: The variable of integration.
            lower: Lower limit for definite integral (optional).
            upper: Upper limit for definite integral (optional).
            format: Output format.

        Returns:
            The integral as a string.
        """
        args = {"expression": expression, "variable": variable, "format": format}
        if lower is not None:
            args["lower"] = lower
        if upper is not None:
            args["upper"] = upper
        return self._call_tool("integrate", args)

    def limit(
        self,
        expression: str,
        variable: str,
        point: str,
        direction: Optional[str] = None,
        format: str = "text",
    ) -> str:
        """
        Compute the limit of an expression.

        Args:
            expression: The expression.
            variable: The variable approaching the limit.
            point: The point to approach (e.g., "0", "inf").
            direction: 'plus' (from above) or 'minus' (from below), optional.
            format: Output format.
        """
        args = {
            "expression": expression,
            "variable": variable,
            "point": point,
            "format": format,
        }
        if direction:
            args["direction"] = direction
        return self._call_tool("limit", args)

    def taylor(
        self,
        expression: str,
        variable: str,
        point: str,
        order: int,
        format: str = "text",
    ) -> str:
        """
        Compute the Taylor series expansion.

        Args:
            expression: The expression to expand.
            variable: The variable of expansion.
            point: The point around which to expand.
            order: The order of expansion.
            format: Output format.
        """
        return self._call_tool(
            "taylor",
            {
                "expression": expression,
                "variable": variable,
                "point": point,
                "order": order,
                "format": format,
            },
        )

    def sum(
        self,
        expression: str,
        variable: str,
        lower: str,
        upper: str,
        simpsum: bool = False,
        format: str = "text",
    ) -> str:
        """Compute a symbolic sum."""
        return self._call_tool(
            "sum",
            {
                "expression": expression,
                "variable": variable,
                "lower": lower,
                "upper": upper,
                "simpsum": simpsum,
                "format": format,
            },
        )

    def product(
        self,
        expression: str,
        variable: str,
        lower: str,
        upper: str,
        format: str = "text",
    ) -> str:
        """Compute a symbolic product."""
        return self._call_tool(
            "product",
            {
                "expression": expression,
                "variable": variable,
                "lower": lower,
                "upper": upper,
                "format": format,
            },
        )

    def laplace(
        self, expression: str, t_var: str, s_var: str, format: str = "text"
    ) -> str:
        """Compute the Laplace transform."""
        return self._call_tool(
            "laplace",
            {"expression": expression, "t_var": t_var, "s_var": s_var, "format": format},
        )

    def ilt(
        self, expression: str, s_var: str, t_var: str, format: str = "text"
    ) -> str:
        """Compute the inverse Laplace transform."""
        return self._call_tool(
            "ilt",
            {"expression": expression, "s_var": s_var, "t_var": t_var, "format": format},
        )

    # =========================================================================
    # Algebra Tools
    # =========================================================================

    def simplify(self, expression: str, format: str = "text") -> str:
        """Simplify an expression."""
        return self._call_tool("simplify", {"expression": expression, "format": format})

    def factor(self, expression: str, format: str = "text") -> str:
        """Factor a polynomial expression."""
        return self._call_tool("factor", {"expression": expression, "format": format})

    def expand(self, expression: str, format: str = "text") -> str:
        """Expand an expression."""
        return self._call_tool("expand", {"expression": expression, "format": format})

    def ratsimp(self, expression: str, format: str = "text") -> str:
        """Rational simplification."""
        return self._call_tool("ratsimp", {"expression": expression, "format": format})

    def trigsimp(self, expression: str, format: str = "text") -> str:
        """Trigonometric simplification."""
        return self._call_tool("trigsimp", {"expression": expression, "format": format})

    def trigexpand(self, expression: str, format: str = "text") -> str:
        """Expand trigonometric expressions."""
        return self._call_tool("trigexpand", {"expression": expression, "format": format})

    def trigreduce(self, expression: str, format: str = "text") -> str:
        """Reduce trigonometric expressions."""
        return self._call_tool("trigreduce", {"expression": expression, "format": format})

    def radcan(self, expression: str, format: str = "text") -> str:
        """Simplify radicals and logarithms."""
        return self._call_tool("radcan", {"expression": expression, "format": format})

    def partfrac(self, expression: str, variable: str, format: str = "text") -> str:
        """Partial fraction decomposition."""
        return self._call_tool(
            "partfrac", {"expression": expression, "variable": variable, "format": format}
        )

    def gcd(self, expr1: str, expr2: str, format: str = "text") -> str:
        """Greatest common divisor of polynomials."""
        return self._call_tool(
            "gcd", {"expr1": expr1, "expr2": expr2, "format": format}
        )

    def subst(
        self, substitution: str, expression: str, format: str = "text"
    ) -> str:
        """
        Substitute values into an expression.

        Args:
            substitution: Substitution rule(s), e.g. "x=1" or "[x=1, y=2]"
            expression: The expression to substitute into
            format: Output format

        Returns:
            The expression with substitutions applied.

        Example:
            >>> client.subst("x=2", "x^2 + y")
            'y+4'
        """
        return self._call_tool(
            "subst",
            {
                "substitution": substitution,
                "expression": expression,
                "format": format,
            },
        )

    # =========================================================================
    # Matrix Tools
    # =========================================================================

    def determinant(self, matrix: str, format: str = "text") -> str:
        """Compute matrix determinant."""
        return self._call_tool("determinant", {"matrix": matrix, "format": format})

    def invert(self, matrix: str, format: str = "text") -> str:
        """Compute matrix inverse."""
        return self._call_tool("invert", {"matrix": matrix, "format": format})

    def eigenvalues(self, matrix: str, format: str = "text") -> str:
        """Compute eigenvalues."""
        return self._call_tool("eigenvalues", {"matrix": matrix, "format": format})

    def eigenvectors(self, matrix: str, format: str = "text") -> str:
        """Compute eigenvectors."""
        return self._call_tool("eigenvectors", {"matrix": matrix, "format": format})

    def transpose(self, matrix: str, format: str = "text") -> str:
        """Compute matrix transpose."""
        return self._call_tool("transpose", {"matrix": matrix, "format": format})

    def matrix_multiply(self, matrix1: str, matrix2: str, format: str = "text") -> str:
        """Matrix multiplication."""
        return self._call_tool(
            "matrix_multiply", {"matrix1": matrix1, "matrix2": matrix2, "format": format}
        )

    def rank(self, matrix: str, format: str = "text") -> str:
        """Compute matrix rank."""
        return self._call_tool("rank", {"matrix": matrix, "format": format})

    def charpoly(self, matrix: str, variable: str, format: str = "text") -> str:
        """Compute characteristic polynomial."""
        return self._call_tool(
            "charpoly", {"matrix": matrix, "variable": variable, "format": format}
        )

    def trace_matrix(self, matrix: str, format: str = "text") -> str:
        """Compute matrix trace."""
        return self._call_tool("trace_matrix", {"matrix": matrix, "format": format})

    def nullspace(self, matrix: str, format: str = "text") -> str:
        """Compute null space."""
        return self._call_tool("nullspace", {"matrix": matrix, "format": format})

    # =========================================================================
    # Session Tools
    # =========================================================================

    def assign(self, variable: str, value: str, format: str = "text") -> str:
        """Assign a value to a variable."""
        return self._call_tool(
            "assign", {"variable": variable, "value": value, "format": format}
        )

    def get_value(self, variable: str, format: str = "text") -> str:
        """Get the value of a variable."""
        return self._call_tool("get_value", {"variable": variable, "format": format})

    def list_variables(self, format: str = "text") -> str:
        """List all defined variables."""
        return self._call_tool("list_variables", {"format": format})

    def clear(self, variables: str, format: str = "text") -> str:
        """Clear specified variables."""
        return self._call_tool("clear", {"variables": variables, "format": format})

    def reset(self, format: str = "text") -> str:
        """Reset the session."""
        return self._call_tool("reset", {"format": format})

    def assume(self, assumption: str, format: str = "text") -> str:
        """Add a mathematical assumption."""
        return self._call_tool("assume", {"assumption": assumption, "format": format})

    def forget(self, assumption: str, format: str = "text") -> str:
        """Remove an assumption."""
        return self._call_tool("forget", {"assumption": assumption, "format": format})

    def list_assumptions(self, format: str = "text") -> str:
        """List all assumptions."""
        return self._call_tool("list_assumptions", {"format": format})

    def declare(self, variable: str, property: str, format: str = "text") -> str:
        """Declare a property for a variable."""
        return self._call_tool(
            "declare", {"variable": variable, "property": property, "format": format}
        )

    def properties(self, symbol: str, format: str = "text") -> str:
        """Get properties of a symbol."""
        return self._call_tool("properties", {"symbol": symbol, "format": format})

    def set_format(self, format: str) -> str:
        """Set the default output format."""
        return self._call_tool("set_format", {"format": format})

    # =========================================================================
    # Meta Tools
    # =========================================================================

    def describe(self, topic: str) -> str:
        """Get help on a Maxima function or topic."""
        return self._call_tool("describe", {"topic": topic})

    def capabilities(self) -> str:
        """List all available tools."""
        return self._call_tool("capabilities", {})

    def example(self, function: str) -> str:
        """Show examples for a function."""
        return self._call_tool("example", {"function": function})

    def apropos(self, pattern: str) -> str:
        """Search for functions by name pattern."""
        return self._call_tool("apropos", {"pattern": pattern})

    def define_function(self, name: str, body: str, format: str = "text") -> str:
        """Define a custom function."""
        return self._call_tool(
            "define_function", {"name": name, "body": body, "format": format}
        )

    def list_functions(self, format: str = "text") -> str:
        """List user-defined functions."""
        return self._call_tool("list_functions", {"format": format})

    def version(self) -> str:
        """Get Maxima version information."""
        return self._call_tool("version", {})

    def constants(self) -> str:
        """List mathematical constants."""
        return self._call_tool("constants", {})

    # =========================================================================
    # Raw Tool Access
    # =========================================================================

    def list_tools(self) -> List[Dict[str, Any]]:
        """List all available MCP tools with their schemas."""
        self._initialize()
        result = self._send_request("tools/list", {})
        return result.get("tools", [])

    def call_tool(
        self,
        name: str,
        arguments: Optional[Dict[str, Any]] = None,
        timeout: Optional[float] = ...,
    ) -> str:
        """Call any tool by name with arbitrary arguments.

        Args:
            name: Name of the tool to call.
            arguments: Arguments for the tool.
            timeout: Timeout in seconds. Use None for no timeout,
                    or omit to use the default timeout from __init__.
        """
        return self._call_tool(name, arguments, timeout=timeout)
