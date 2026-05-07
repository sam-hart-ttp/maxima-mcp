# Maxima MCP

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server for [Maxima](https://maxima.sourceforge.io/), the computer algebra system. This enables AI assistants like Claude to perform symbolic mathematics.

## Features

- **Symbolic Mathematics**: Differentiation, integration, limits, Taylor series, sums, products
- **Equation Solving**: Solve algebraic equations and systems
- **Algebra**: Simplification, factoring, expansion, partial fractions
- **Linear Algebra**: Matrices, determinants, eigenvalues, inverses
- **Session State**: Variable assignment, assumptions, function definitions
- **Documentation Resources**: MCP resources for docs index and topic lookups
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

#### Build Tuning (SBCL)

The standalone build recompiles Maxima and can require a larger control stack and heap.
You can tune these via environment variables:

```bash
MAXIMA_MCP_CONTROL_STACK_MB=512 \
MAXIMA_MCP_DYNAMIC_SPACE_MB=4096 \
sbcl --load build-standalone.lisp
```

If you want to skip recompiling Maxima and use an existing core (if present),
set `MAXIMA_MCP_USE_CORE=1`:

```bash
MAXIMA_MCP_USE_CORE=1 sbcl --load build-standalone.lisp
```

### ECL (Standalone)

If Maxima is not already installed as a library, Quicklisp will fetch it.

```bash
cd src/mcp
ecl --load build-standalone-ecl.lisp
```

If you want to use the subprocess backend (system `maxima` binary) instead
of the Maxima library, build the subprocess executable:

```bash
cd src/mcp
ecl --load build-standalone-ecl-subprocess.lisp
```

### ABCL (Jar / Wrapper)

ABCL does not produce a native executable. The recommended approach is
to run via `abcl` or a wrapper script.

To build jar artifacts and wrappers:

```bash
cd src/mcp
abcl --load build-abcl-jar.lisp
```

This produces:
- `maxima-mcp-lib.jar` (the packaged ASDF system)
- `maxima-mcp.jar` (a launcher jar that relies on `abcl.jar` nearby)
- `maxima-mcp-abcl` and `maxima-mcp-abcl-subprocess` wrapper scripts (recommended)

Note: `maxima-mcp.jar` starts ABCL but does not automatically invoke
`maxima-mcp:main`. Use the wrapper scripts to start the MCP server.
The wrappers expect `abcl.jar` to be alongside the jars.

If Maxima cannot be loaded as a library in ABCL, build with
`MAXIMA_MCP_SUBPROCESS=1` to package the subprocess backend instead:

```bash
MAXIMA_MCP_SUBPROCESS=1 abcl --load build-abcl-jar.lisp
```

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

### Documentation Resources (MCP)

- Resource: `maxima://docs/index`
- Resource template: `maxima://docs/topic/{name}`
- Topic docs return two content entries:
  - `text/markdown` narrative docs
  - `application/json` structured metadata (`source`, `topic`, `hasLocalDocs`, `apropos`, and markdown copy)
- Topic docs use local `./doc` files when available, with `apropos(name)` fallback.
- Optional local overrides are supported from `./doc`:
  - `doc/<topic>.md`, `doc/topics/<topic>.md`
  - `doc/<topic>.txt`, `doc/topics/<topic>.txt`

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
- `laplace` - Laplace transform
- `ilt` - Inverse Laplace transform

### Algebra
- `simplify` - Simplify expressions
- `factor` - Factor polynomials
- `expand` - Expand expressions
- `trigexpand` - Expand trigonometric functions
- `trigreduce` - Reduce trigonometric functions
- `ratsimp` - Rational simplification
- `trigsimp` - Trigonometric simplification
- `partfrac` - Partial fraction decomposition
- `radcan` - Canonicalize radicals
- `gcd` - Greatest common divisor

### Linear Algebra
- `determinant` - Matrix determinant
- `invert` - Matrix inverse
- `eigenvalues` - Eigenvalues
- `eigenvectors` - Eigenvectors
- `transpose` - Matrix transpose
- `matrix_multiply` - Matrix multiplication
- `rank` - Matrix rank
- `nullspace` - Matrix nullspace
- `linsolve` - Solve linear systems
- `fast_linsolve` - Faster linear solver (sparse-friendly)
- `augcoefmatrix` - Augmented coefficient matrix
- `coefmatrix` - Coefficient matrix
- `addcol` - Add columns to a matrix
- `triangularize` - Gaussian elimination
- `echelon` - Echelon form
- `matrix` - Construct a matrix from rows
- `charpoly` - Characteristic polynomial
- `trace_matrix` - Trace of a matrix
- `solve_linear` - Solve linear systems (matrix form)

### Differential Equations
- `ode2` - Solve a single ODE
- `ic1` - Apply one initial condition
- `ic2` - Apply two initial conditions
- `bc2` - Apply two boundary conditions
- `desolve` - Solve linear ODE systems
- `atvalue` - Define values at a point
- `printprops` - Inspect properties (e.g., atvalue)

### Vector Calculus (vect package)
- `scalefactors` - Set scale factors
- `express` - Simplify vector expressions
- `grad` - Gradient
- `div` - Divergence
- `curl` - Curl
- `potential` - Scalar potential
- `vectorpotential` - Vector potential

### Fourier Series (fourie package)
- `fourier` - Fourier coefficients
- `fourexpand` - Construct a Fourier series
- `foursimp` - Simplify Fourier terms
- `fourcos` - Fourier cosine coefficients
- `foursin` - Fourier sine coefficients
- `totalfourier` - Full Fourier expansion

### Lists and Substitution
- `makelist` - Build lists by iteration
- `subst` - Substitute expressions
- `ev` - Evaluate with substitutions/flags
- `append` - Append lists

### Misc
- `abs` - Absolute value
- `maxmod` - Maximum modulus
- `ident` - Identity matrix
- `length` - List length
- `random` - Random integer
- `evenp` - Even predicate
- `concat` / `sconcat` - String concatenation
- `cons` - Construct lists
- `facts` - List assumptions
- `kill` - Kill variables/properties
- `float` - Floating-point evaluation
- `bfloat` - Bigfloat evaluation

### Extra (OU guides/manual)
- `fullratsimp` - Full rational simplification
- `logcontract` - Combine logarithms
- `trigrat` - Simplify trig ratios
- `realroots` / `allroots` - Polynomial roots
- `multiplicities` - Root multiplicities from last solve/roots
- `rhs` / `lhs` - Equation sides
- `map` - Apply a function to a list
- `quotient` / `remainder` - Division (integer or polynomial)
- `gcdex` - Extended GCD (Bezout coefficients)
- `quad_qags` - Numerical integration
- `newton` - Newton root finder (`newton` package)
- `mnewton` - Newton solver for nonlinear systems (`mnewton` package)
- `romberg` - Romberg numerical integration
- `rk` - Runge-Kutta ODE solver
- `solve_rec` - Recurrence relation solver
- `set_plot_option` - Set global plot options
- `depends` / `dependencies` - Declare or list functional dependencies
- `remove_dependency` - Remove dependencies for a symbol
- `gradef` - Define custom derivative rules
- `propvars` - List variables with a given property

### Plotting
- `plot_capabilities` - Discover available plotting backends/outputs at runtime
- `plot` - Render 2D/3D plots to PNG (or window when available)
- `plot2d` / `plot3d` - Explicit 2D/3D plot wrappers
- `wxplot2d` / `wxplot3d` - wxMaxima-compatible plot aliases
- `implicit_plot` / `wximplicit_plot` - Implicit plotting
- `draw2d` / `draw3d` - draw package plotting
- `drawdf` - Direction field plotting (drawdf package)
- `with_slider_draw` - Interactive sliders (not supported headless)

### Session
- `assign` - Assign value to variable
- `get_value` - Get variable value
- `list_variables` - List defined variables
- `assume` - Add mathematical assumption
- `forget` - Remove assumption
- `list_assumptions` - List current assumptions
- `reset` - Reset session state
- `clear` - Clear variables

### Meta
- `describe` - Get help on Maxima functions
- `constants` - List known constants
- `define_function` - Define a function
- `example` - Show examples of a Maxima function
- `apropos` - Search for functions by name
- `fundef` - Show function definition
- `list_functions` - List defined functions
- `tool_usage_stats` - Return in-process MCP tool usage counters
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

## Tool Selection Policy

- `evaluate` is intentionally a fallback tool.
- Dedicated tools (for example `integrate`, `solve`, `factor`, `newton`) should be preferred whenever they match the task.
- During `initialize`, the server returns this guidance in the `instructions` field so MCP clients can apply it directly.
- For symbolic tools (`integrate`, `limit`, `solve`), the server emits a preflight warning when no explicit assumptions have been set in the current session.

## Observability

- The server tracks per-tool invocation counts in-process.
- With MCP debug logging enabled, it emits a periodic usage summary that includes total calls and `evaluate` call count.
- This is intended to make overuse of `evaluate` visible without changing tool semantics.
- `tool_usage_stats` also reports symbolic preflight counters:
  - `symbolic_calls`
  - `symbolic_calls_without_assumptions`
  - `symbolic_calls_without_assumptions_percent`
  - `symbolic_preflight_warnings`

### Subprocess Mode

The subprocess backend can run in two modes:

- `MAXIMA_MCP_SUBPROCESS_MODE=batch` (default) runs `maxima -q --batch-string` for each evaluation.
- `MAXIMA_MCP_SUBPROCESS_MODE=interactive` keeps a persistent Maxima process.

Debugging:

- `MAXIMA_MCP_SUBPROCESS_DEBUG=1` logs raw subprocess output to stderr.
- If SBCL cannot write under `~/.cache`, set `XDG_CACHE_HOME=/tmp` when running tests.

Batch mode statelessness:

- `batch` mode is stateless: each tool call runs in a fresh Maxima process, so assignments, assumptions, dependencies, and custom derivative rules do not persist across calls.
- If you need state to persist between calls, use `MAXIMA_MCP_SUBPROCESS_MODE=interactive`, or have the client track state and re-send it with each request.
- Symbolic preflight warnings account for this: in `batch` mode, prior `assume` calls are not treated as effective for later symbolic calls.

## License

GPL-2.0, same as Maxima.

## Acknowledgments

- [Maxima](https://maxima.sourceforge.io/) - The powerful computer algebra system
- [SBCL](http://www.sbcl.org/) - Steel Bank Common Lisp
- [yason](https://github.com/phmarek/yason) - JSON library for Common Lisp
