"""
AI Agent Integration for Maxima MCP

Provides a wrapper class designed for use with AI agents and LLMs,
with convenient methods and structured output.
"""

from typing import Any, Dict, List, Optional, Union
from dataclasses import dataclass
from .client import MaximaMCPClient, MaximaError


@dataclass
class MathResult:
    """A structured result from a mathematical operation."""

    expression: str
    result: str
    latex: Optional[str] = None
    success: bool = True
    error: Optional[str] = None

    def __str__(self) -> str:
        return self.result if self.success else f"Error: {self.error}"


class MaximaMathAgent:
    """
    A higher-level interface to Maxima designed for AI agent integration.

    This class provides:
    - Structured results with both text and LaTeX output
    - Error handling that returns structured errors instead of raising
    - Convenient methods for common mathematical operations
    - Context management (with statement support)

    Example:
        >>> agent = MaximaMathAgent()
        >>> result = agent.compute("integrate(x^2, x)")
        >>> print(result.result)
        x^3/3
        >>> print(result.latex)
        \\frac{x^3}{3}
    """

    def __init__(self, **kwargs):
        """
        Initialize the math agent.

        Args:
            **kwargs: Arguments passed to MaximaMCPClient
        """
        self._client = MaximaMCPClient(**kwargs)

    def close(self):
        """Close the connection."""
        self._client.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False

    def _safe_call(
        self,
        method: str,
        expression: str,
        include_latex: bool = True,
        **kwargs,
    ) -> MathResult:
        """Safely call a client method and return a structured result."""
        try:
            # Get text result
            text_result = getattr(self._client, method)(expression, format="text", **kwargs)

            # Optionally get LaTeX
            latex_result = None
            if include_latex:
                try:
                    latex_result = getattr(self._client, method)(
                        expression, format="latex", **kwargs
                    )
                except MaximaError:
                    pass  # LaTeX conversion failed, that's OK

            return MathResult(
                expression=expression,
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=expression,
                result="",
                success=False,
                error=str(e),
            )

    # =========================================================================
    # High-Level Operations
    # =========================================================================

    def compute(self, expression: str, include_latex: bool = True) -> MathResult:
        """
        Evaluate any Maxima expression.

        This is the most general method - use it for any mathematical
        computation.

        Args:
            expression: Any valid Maxima expression
            include_latex: Whether to include LaTeX output

        Returns:
            MathResult with the computation result
        """
        return self._safe_call("evaluate", expression, include_latex)

    def derivative(
        self,
        expression: str,
        variable: str = "x",
        order: int = 1,
        include_latex: bool = True,
    ) -> MathResult:
        """
        Compute a derivative.

        Args:
            expression: The expression to differentiate
            variable: Variable to differentiate with respect to
            order: Order of differentiation
            include_latex: Whether to include LaTeX output
        """
        try:
            text_result = self._client.differentiate(
                expression, variable, order, format="text"
            )
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.differentiate(
                        expression, variable, order, format="latex"
                    )
                except MaximaError:
                    pass
            return MathResult(
                expression=f"d/d{variable}({expression})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"d/d{variable}({expression})",
                result="",
                success=False,
                error=str(e),
            )

    def integral(
        self,
        expression: str,
        variable: str = "x",
        lower: Optional[str] = None,
        upper: Optional[str] = None,
        include_latex: bool = True,
    ) -> MathResult:
        """
        Compute an integral.

        Args:
            expression: The expression to integrate
            variable: Variable of integration
            lower: Lower limit (for definite integrals)
            upper: Upper limit (for definite integrals)
            include_latex: Whether to include LaTeX output
        """
        try:
            text_result = self._client.integrate(
                expression, variable, lower, upper, format="text"
            )
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.integrate(
                        expression, variable, lower, upper, format="latex"
                    )
                except MaximaError:
                    pass

            expr_str = f"integrate({expression}, {variable})"
            if lower and upper:
                expr_str = f"integrate({expression}, {variable}, {lower}, {upper})"

            return MathResult(
                expression=expr_str,
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"integrate({expression}, {variable})",
                result="",
                success=False,
                error=str(e),
            )

    def solve_equation(
        self,
        equation: str,
        variable: str = "x",
        include_latex: bool = True,
    ) -> MathResult:
        """
        Solve an equation.

        Args:
            equation: The equation to solve (e.g., "x^2 - 4 = 0")
            variable: The variable to solve for
            include_latex: Whether to include LaTeX output
        """
        try:
            text_result = self._client.solve(equation, variable, format="text")
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.solve(equation, variable, format="latex")
                except MaximaError:
                    pass
            return MathResult(
                expression=f"solve({equation}, {variable})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"solve({equation}, {variable})",
                result="",
                success=False,
                error=str(e),
            )

    def simplify_expression(
        self, expression: str, include_latex: bool = True
    ) -> MathResult:
        """Simplify an expression."""
        return self._safe_call("simplify", expression, include_latex)

    def factor_expression(
        self, expression: str, include_latex: bool = True
    ) -> MathResult:
        """Factor an expression."""
        return self._safe_call("factor", expression, include_latex)

    def expand_expression(
        self, expression: str, include_latex: bool = True
    ) -> MathResult:
        """Expand an expression."""
        return self._safe_call("expand", expression, include_latex)

    def compute_limit(
        self,
        expression: str,
        variable: str,
        point: str,
        direction: Optional[str] = None,
        include_latex: bool = True,
    ) -> MathResult:
        """
        Compute a limit.

        Args:
            expression: The expression
            variable: The variable approaching the limit
            point: The point to approach (e.g., "0", "inf")
            direction: 'plus' or 'minus' for one-sided limits
            include_latex: Whether to include LaTeX output
        """
        try:
            text_result = self._client.limit(
                expression, variable, point, direction, format="text"
            )
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.limit(
                        expression, variable, point, direction, format="latex"
                    )
                except MaximaError:
                    pass
            return MathResult(
                expression=f"limit({expression}, {variable}, {point})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"limit({expression}, {variable}, {point})",
                result="",
                success=False,
                error=str(e),
            )

    def taylor_series(
        self,
        expression: str,
        variable: str = "x",
        point: str = "0",
        order: int = 5,
        include_latex: bool = True,
    ) -> MathResult:
        """
        Compute a Taylor series expansion.

        Args:
            expression: The expression to expand
            variable: The variable
            point: The point around which to expand
            order: The order of expansion
            include_latex: Whether to include LaTeX output
        """
        try:
            text_result = self._client.taylor(
                expression, variable, point, order, format="text"
            )
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.taylor(
                        expression, variable, point, order, format="latex"
                    )
                except MaximaError:
                    pass
            return MathResult(
                expression=f"taylor({expression}, {variable}, {point}, {order})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"taylor({expression}, {variable}, {point}, {order})",
                result="",
                success=False,
                error=str(e),
            )

    # =========================================================================
    # Matrix Operations
    # =========================================================================

    def matrix_determinant(self, matrix: str, include_latex: bool = True) -> MathResult:
        """Compute the determinant of a matrix."""
        try:
            text_result = self._client.determinant(matrix, format="text")
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.determinant(matrix, format="latex")
                except MaximaError:
                    pass
            return MathResult(
                expression=f"determinant({matrix})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"determinant({matrix})",
                result="",
                success=False,
                error=str(e),
            )

    def matrix_inverse(self, matrix: str, include_latex: bool = True) -> MathResult:
        """Compute the inverse of a matrix."""
        try:
            text_result = self._client.invert(matrix, format="text")
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.invert(matrix, format="latex")
                except MaximaError:
                    pass
            return MathResult(
                expression=f"invert({matrix})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"invert({matrix})",
                result="",
                success=False,
                error=str(e),
            )

    def matrix_eigenvalues(
        self, matrix: str, include_latex: bool = True
    ) -> MathResult:
        """Compute the eigenvalues of a matrix."""
        try:
            text_result = self._client.eigenvalues(matrix, format="text")
            latex_result = None
            if include_latex:
                try:
                    latex_result = self._client.eigenvalues(matrix, format="latex")
                except MaximaError:
                    pass
            return MathResult(
                expression=f"eigenvalues({matrix})",
                result=text_result,
                latex=latex_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"eigenvalues({matrix})",
                result="",
                success=False,
                error=str(e),
            )

    # =========================================================================
    # Session Management
    # =========================================================================

    def set_variable(self, name: str, value: str) -> MathResult:
        """Set a variable to a value."""
        try:
            text_result = self._client.assign(name, value, format="text")
            return MathResult(
                expression=f"{name} : {value}",
                result=text_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"{name} : {value}",
                result="",
                success=False,
                error=str(e),
            )

    def get_variable(self, name: str) -> MathResult:
        """Get the value of a variable."""
        try:
            text_result = self._client.get_value(name, format="text")
            return MathResult(
                expression=name,
                result=text_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=name,
                result="",
                success=False,
                error=str(e),
            )

    def add_assumption(self, assumption: str) -> MathResult:
        """Add a mathematical assumption."""
        try:
            text_result = self._client.assume(assumption, format="text")
            return MathResult(
                expression=f"assume({assumption})",
                result=text_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression=f"assume({assumption})",
                result="",
                success=False,
                error=str(e),
            )

    def reset_session(self) -> MathResult:
        """Reset the entire session."""
        try:
            text_result = self._client.reset()
            return MathResult(
                expression="reset()",
                result=text_result,
                success=True,
            )
        except MaximaError as e:
            return MathResult(
                expression="reset()",
                result="",
                success=False,
                error=str(e),
            )

    # =========================================================================
    # Direct Client Access
    # =========================================================================

    @property
    def client(self) -> MaximaMCPClient:
        """Get the underlying client for direct access."""
        return self._client
