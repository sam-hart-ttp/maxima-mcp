# Maxima MCP Python Client

A Python client for interacting with the Maxima computer algebra system via the Model Context Protocol (MCP).

## Installation

```bash
pip install maxima-mcp
```

Or install from source:

```bash
cd clients/python
pip install -e .
```

## Requirements

- Python 3.8+
- A running `maxima-mcp` server (see the main project README for build instructions)

## Quick Start

```python
from maxima_mcp import MaximaMCPClient

# Create a client (automatically starts the server)
client = MaximaMCPClient()

# Evaluate expressions
result = client.evaluate("2 + 2")
print(result)  # "4"

# Differentiate
result = client.differentiate("x^3", "x")
print(result)  # "3*x^2"

# Integrate
result = client.integrate("x^2", "x")
print(result)  # "x^3/3"

# Solve equations
result = client.solve("x^2 - 4 = 0", "x")
print(result)  # "[x = -2, x = 2]"

# Clean up
client.close()
```

### Using Context Manager

```python
from maxima_mcp import MaximaMCPClient

with MaximaMCPClient() as client:
    print(client.evaluate("diff(sin(x), x)"))  # "cos(x)"
```

## Available Operations

### Core Operations

- `evaluate(expression)` - Evaluate any Maxima expression
- `solve(equation, variable)` - Solve equations
- `float_(expression)` - Convert to floating point
- `bfloat(expression, precision)` - Arbitrary precision float

### Calculus

- `differentiate(expression, variable, order=1)` - Compute derivatives
- `integrate(expression, variable, lower=None, upper=None)` - Compute integrals
- `limit(expression, variable, point, direction=None)` - Compute limits
- `taylor(expression, variable, point, order)` - Taylor series
- `sum(expression, variable, lower, upper)` - Symbolic sums
- `product(expression, variable, lower, upper)` - Symbolic products
- `laplace(expression, t_var, s_var)` - Laplace transform
- `ilt(expression, s_var, t_var)` - Inverse Laplace transform

### Algebra

- `simplify(expression)` - Simplify expressions
- `factor(expression)` - Factor polynomials
- `expand(expression)` - Expand expressions
- `ratsimp(expression)` - Rational simplification
- `trigsimp(expression)` - Trigonometric simplification
- `trigexpand(expression)` - Expand trig functions
- `trigreduce(expression)` - Reduce trig powers
- `radcan(expression)` - Simplify radicals/logs
- `partfrac(expression, variable)` - Partial fractions
- `gcd(expr1, expr2)` - GCD of polynomials
- `subst(replacement, variable, expression)` - Substitution

### Matrix Operations

- `determinant(matrix)` - Matrix determinant
- `invert(matrix)` - Matrix inverse
- `eigenvalues(matrix)` - Eigenvalues
- `eigenvectors(matrix)` - Eigenvectors
- `transpose(matrix)` - Matrix transpose
- `matrix_multiply(matrix1, matrix2)` - Matrix multiplication
- `rank(matrix)` - Matrix rank
- `charpoly(matrix, variable)` - Characteristic polynomial
- `trace_matrix(matrix)` - Matrix trace
- `nullspace(matrix)` - Null space

### Session Management

- `assign(variable, value)` - Assign a value
- `get_value(variable)` - Get a variable's value
- `list_variables()` - List all variables
- `clear(variables)` - Clear variables
- `reset()` - Reset the session
- `assume(assumption)` - Add an assumption
- `forget(assumption)` - Remove an assumption
- `list_assumptions()` - List assumptions
- `declare(variable, property)` - Declare properties
- `set_format(format)` - Set default output format

### Meta Operations

- `describe(topic)` - Get help on a topic
- `capabilities()` - List all tools
- `list_tools()` - Get tool schemas

## Output Formats

All operations support a `format` parameter:

- `"text"` - Plain text (default)
- `"latex"` - LaTeX markup
- `"mathml"` - MathML markup
- `"lisp"` - Lisp s-expression

```python
result = client.integrate("x^2", "x", format="latex")
print(result)  # "\\frac{x^3}{3}"
```

## AI Agent Integration

For AI agent integration, use the `MaximaMathAgent` class which provides structured results:

```python
from maxima_mcp.agent import MaximaMathAgent

with MaximaMathAgent() as agent:
    result = agent.compute("integrate(x^2, x)")
    print(result.result)  # "x^3/3"
    print(result.latex)   # "\\frac{x^3}{3}"
    print(result.success) # True
```

## Command-Line Interface

```bash
# Start interactive REPL
maxima-mcp-client

# Evaluate a single expression
maxima-mcp-client -e "integrate(x^2, x)"

# Get LaTeX output
maxima-mcp-client -e "diff(sin(x), x)" --format latex

# Use a specific server
maxima-mcp-client --server /path/to/maxima-mcp
```

## Error Handling

```python
from maxima_mcp import MaximaMCPClient, MaximaError

client = MaximaMCPClient()

try:
    result = client.evaluate("1/0")
except MaximaError as e:
    print(f"Math error: {e}")
    print(f"Error code: {e.code}")
```

## Testing

```bash
cd clients/python
pip install -e ".[dev]"
pytest tests/
```

## License

GPL-2.0 - see the main project LICENSE file.
