"""
Tests for the Maxima MCP client.

These tests require a running maxima-mcp server. They can be run with:
    pytest tests/test_client.py

To skip tests if the server isn't available, set MAXIMA_MCP_SKIP_INTEGRATION=1
"""

import os
import pytest
from maxima_mcp import MaximaMCPClient, MaximaError

# Skip integration tests if server not available
SKIP_INTEGRATION = os.environ.get("MAXIMA_MCP_SKIP_INTEGRATION", "0") == "1"


@pytest.fixture
def client():
    """Create a client connected to the MCP server."""
    if SKIP_INTEGRATION:
        pytest.skip("Integration tests skipped")
    try:
        c = MaximaMCPClient()
        yield c
        c.close()
    except FileNotFoundError:
        pytest.skip("maxima-mcp server not found")


class TestBasicEvaluation:
    """Test basic expression evaluation."""

    def test_simple_arithmetic(self, client):
        """Test simple arithmetic."""
        assert client.evaluate("2+2") == "4"
        assert client.evaluate("3*4") == "12"
        assert client.evaluate("10/2") == "5"

    def test_symbolic_arithmetic(self, client):
        """Test symbolic arithmetic."""
        result = client.evaluate("x + x")
        assert "2*x" in result or "2 x" in result

    def test_constants(self, client):
        """Test mathematical constants."""
        result = client.evaluate("%pi")
        assert "pi" in result.lower() or "%pi" in result

        result = client.evaluate("%e")
        assert "e" in result.lower() or "%e" in result


class TestDifferentiation:
    """Test differentiation."""

    def test_simple_derivative(self, client):
        """Test simple derivatives."""
        result = client.differentiate("x^2", "x")
        assert "2*x" in result or "2 x" in result

        result = client.differentiate("x^3", "x")
        assert "3*x^2" in result or "3 x^2" in result

    def test_trig_derivative(self, client):
        """Test trigonometric derivatives."""
        result = client.differentiate("sin(x)", "x")
        assert "cos" in result

        result = client.differentiate("cos(x)", "x")
        assert "sin" in result

    def test_higher_order_derivative(self, client):
        """Test higher-order derivatives."""
        result = client.differentiate("x^3", "x", order=2)
        assert "6*x" in result or "6 x" in result


class TestIntegration:
    """Test integration."""

    def test_indefinite_integral(self, client):
        """Test indefinite integrals."""
        result = client.integrate("x^2", "x")
        assert "x^3/3" in result or "x^3" in result

        result = client.integrate("cos(x)", "x")
        assert "sin" in result

    def test_definite_integral(self, client):
        """Test definite integrals."""
        result = client.integrate("x", "x", "0", "1")
        assert "1/2" in result or "0.5" in result


class TestSolving:
    """Test equation solving."""

    def test_linear_equation(self, client):
        """Test solving linear equations."""
        result = client.solve("x + 2 = 5", "x")
        assert "3" in result

    def test_quadratic_equation(self, client):
        """Test solving quadratic equations."""
        result = client.solve("x^2 - 4 = 0", "x")
        assert "2" in result
        assert "-2" in result


class TestAlgebra:
    """Test algebraic operations."""

    def test_factor(self, client):
        """Test factoring."""
        result = client.factor("x^2 - 1")
        assert "x-1" in result.replace(" ", "") or "(x - 1)" in result
        assert "x+1" in result.replace(" ", "") or "(x + 1)" in result

    def test_expand(self, client):
        """Test expansion."""
        result = client.expand("(x+1)^2")
        assert "x^2" in result
        assert "2*x" in result or "2 x" in result

    def test_simplify(self, client):
        """Test simplification."""
        result = client.simplify("(x^2 - 1)/(x - 1)")
        assert "x+1" in result.replace(" ", "") or "x + 1" in result


class TestLimits:
    """Test limit computation."""

    def test_simple_limit(self, client):
        """Test simple limits."""
        result = client.limit("sin(x)/x", "x", "0")
        assert "1" in result

    def test_infinity_limit(self, client):
        """Test limits at infinity."""
        result = client.limit("1/x", "x", "inf")
        assert "0" in result


class TestTaylor:
    """Test Taylor series."""

    def test_exponential_taylor(self, client):
        """Test Taylor series of e^x."""
        result = client.taylor("exp(x)", "x", "0", 3)
        # Should contain 1, x, x^2/2
        assert "1" in result
        assert "x" in result


class TestMatrix:
    """Test matrix operations."""

    def test_determinant(self, client):
        """Test matrix determinant."""
        result = client.determinant("matrix([1,2],[3,4])")
        assert "-2" in result

    def test_transpose(self, client):
        """Test matrix transpose."""
        result = client.transpose("matrix([1,2],[3,4])")
        assert "matrix" in result.lower()

    def test_eigenvalues(self, client):
        """Test eigenvalue computation."""
        result = client.eigenvalues("matrix([1,0],[0,2])")
        assert "1" in result
        assert "2" in result


class TestSession:
    """Test session management."""

    def test_assign_and_retrieve(self, client):
        """Test variable assignment and retrieval."""
        client.assign("x", "5")
        result = client.get_value("x")
        assert "5" in result

    def test_assumptions(self, client):
        """Test assumptions."""
        client.assume("x > 0")
        result = client.list_assumptions()
        # Result should contain something about x > 0
        assert "x" in result


class TestFormat:
    """Test output formats."""

    def test_latex_output(self, client):
        """Test LaTeX output."""
        result = client.integrate("x^2", "x", format="latex")
        # LaTeX should contain frac or similar
        assert "\\" in result or "frac" in result or "^" in result

    def test_lisp_output(self, client):
        """Test Lisp output."""
        result = client.evaluate("x + 1", format="lisp")
        # Lisp output should have parentheses
        assert "(" in result


class TestErrors:
    """Test error handling."""

    def test_parse_error(self, client):
        """Test that parse errors are raised."""
        with pytest.raises(MaximaError):
            client.evaluate("1 + (")

    def test_undefined_variable(self, client):
        """Test undefined variable access."""
        # Note: In Maxima, undefined variables just return themselves
        result = client.get_value("undefined_var_xyz")
        assert "undefined_var_xyz" in result


class TestToolListing:
    """Test tool listing functionality."""

    def test_list_tools(self, client):
        """Test that tools can be listed."""
        tools = client.list_tools()
        assert isinstance(tools, list)
        assert len(tools) > 0

        # Check for expected tools
        tool_names = [t.get("name") for t in tools]
        assert "evaluate" in tool_names
        assert "differentiate" in tool_names
        assert "integrate" in tool_names
        assert "solve" in tool_names
