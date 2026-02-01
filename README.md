# Maxima MCP

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server for [Maxima](https://maxima.sourceforge.io/), the computer algebra system. This enables AI assistants like Claude to perform symbolic mathematics.

## Features

- **Symbolic Mathematics**: Differentiation, integration, limits, Taylor series, sums, products
- **Equation Solving**: Solve algebraic equations and systems
- **Algebra**: Simplification, factoring, expansion, partial fractions
- **Linear Algebra**: Matrices, determinants, eigenvalues, inverses
- **Session State**: Variable assignment, assumptions, function definitions
- **Multiple Output Formats**: Text, LaTeX, MathML, Lisp

## Installation

### Prerequisites

- SBCL (Steel Bank Common Lisp) - for building from source
- Or use the pre-built executable

### Building from Source

```bash
cd src/mcp
sbcl --load build-standalone.lisp
```

This creates the `maxima-mcp` executable in the project root.

### Pre-built Executable

Download from the releases page (if available).

## Usage

### With Claude Code

Add to your `~/.claude.json`:

```json
{
  "mcpServers": {
    "maxima": {
      "command": "/path/to/maxima-mcp"
    }
  }
}
```

Then Claude can use Maxima for math:

```
User: What is the derivative of x^3 sin(x)?

Claude: [Uses differentiate tool]
The derivative is 3*x^2*sin(x) + x^3*cos(x)
```

### Standalone Testing

```bash
# Test with JSON-RPC
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"evaluate","arguments":{"expression":"diff(x^3,x)"}}}' | ./maxima-mcp
```

## Available Tools

### Core
- `evaluate` - Evaluate any Maxima expression
- `solve` - Solve equations
- `find_root` - Numerical root finding

### Calculus
- `differentiate` - Symbolic differentiation
- `integrate` - Indefinite and definite integration
- `limit` - Compute limits
- `taylor` - Taylor series expansion
- `sum` - Summation
- `product` - Product

### Algebra
- `simplify` - Simplify expressions
- `factor` - Factor polynomials
- `expand` - Expand expressions
- `ratsimp` - Rational simplification
- `trigsimp` - Trigonometric simplification
- `partfrac` - Partial fraction decomposition

### Linear Algebra
- `determinant` - Matrix determinant
- `invert` - Matrix inverse
- `eigenvalues` - Eigenvalues
- `eigenvectors` - Eigenvectors
- `transpose` - Matrix transpose
- `matrix_multiply` - Matrix multiplication

### Session
- `assign` - Assign value to variable
- `get_value` - Get variable value
- `assume` - Add mathematical assumption
- `forget` - Remove assumption
- `reset` - Reset session state

### Meta
- `describe` - Get help on Maxima functions
- `capabilities` - List available tools
- `version` - Get Maxima version info

## Python Client

A Python client is included in `clients/python/`:

```python
from maxima_mcp import MaximaMCPClient

client = MaximaMCPClient("/path/to/maxima-mcp")
result = client.differentiate("x^3", "x")
print(result)  # 3*x^2
client.close()
```

## Output Formats

All tools support a `format` parameter:

- `text` (default) - Plain text: `3*x^2`
- `latex` - LaTeX: `3\,x^2`
- `mathml` - MathML markup
- `lisp` - Internal Lisp representation

## License

GPL-2.0, same as Maxima.

## Acknowledgments

- [Maxima](https://maxima.sourceforge.io/) - The powerful computer algebra system
- [SBCL](http://www.sbcl.org/) - Steel Bank Common Lisp
- [yason](https://github.com/phmarek/yason) - JSON library for Common Lisp
