---
name: math
description: >
  Use when the user asks to solve equations, differentiate, integrate, compute limits,
  work with matrices, solve ODEs/PDEs, plot functions, do vector calculus, simplify
  expressions, factor polynomials, compute Fourier/Laplace transforms, find numerical
  roots, or any symbolic/numerical mathematics task. Routes to the maxima-mcp CAS tools.
version: 1.0.0
---

# Math Skill — maxima-mcp Router

You have a full Computer Algebra System (Maxima) available via MCP tools prefixed `mcp__maxima-mcp__`.
**Always prefer dedicated tools over `evaluate`.** Only fall back to `evaluate` when no specific tool exists.

---

## Quick Reference: Which Tool to Use

### Solving Equations

| Problem | Tool | Notes |
|---|---|---|
| Polynomial / algebraic equations | `solve` | `equation`: "x^2-4=0", `variable`: "x" |
| System of equations | `solve` | Use list syntax: `equation`: "[x+y=1, x-y=3]", `variable`: "[x,y]" |
| Linear system Ax=b | `solve_linear` | Pass coefficient `matrix` and RHS `vector` |
| Find all polynomial roots (numerical) | `allroots` | Returns all roots including complex |
| Numerical root of f(x)=0 | `find_root` | Bracket-based, reliable |
| Newton's method (single var) | `newton` | Needs initial `guess` |
| Newton's method (multivariate) | `mnewton` | For nonlinear systems; needs `guesses` |
| Recurrence relation | `solve_rec` | e.g. u[n] = 2*u[n-1]+3 with initial conditions |

### Calculus

| Problem | Tool | Notes |
|---|---|---|
| Derivative | `differentiate` | Set `order` for higher derivatives |
| Indefinite integral | `integrate` | Omit `lower`/`upper` |
| Definite integral | `integrate` | Provide `lower` and `upper` (use "inf"/"minf" for infinity) |
| Numerical integration | `quad_qags` | Adaptive quadrature — preferred for numerical |
| Numerical integration (simple) | `romberg` | Romberg method — simpler alternative |
| Limit | `limit` | Use `direction`: "plus"/"minus" for one-sided |
| Taylor series | `taylor` | Specify `point` and `order` |
| Sum (finite/infinite) | `sum` | Symbolic summation |
| Product | `product` | Symbolic product |

### Differential Equations

| Problem | Tool | Notes |
|---|---|---|
| 1st/2nd order ODE (symbolic) | `ode2` | Returns general solution |
| Apply 1 initial condition to ode2 result | `ic1` | Pass the `solution` string from ode2 |
| Apply 2 initial conditions to ode2 result | `ic2` | For 2nd order ODEs |
| Apply 2 boundary conditions | `bc2` | Boundary value problems |
| System of linear ODEs | `desolve` | Uses Laplace transform method |
| Numerical ODE solution | `rk` | Runge-Kutta; returns data points |
| Direction field plot | `drawdf` | Visualise ODE flow |

**Workflow for IVPs:**
1. Call `ode2` to get general solution
2. Pass the solution string to `ic1` (1st order) or `ic2` (2nd order) with initial values
3. Optionally plot the result or verify with `rk`

### Linear Algebra

| Problem | Tool | Notes |
|---|---|---|
| Create a matrix | `matrix` | `rows`: ["[1,2]", "[3,4]"] |
| Matrix multiply | `matrix_multiply` | A . B |
| Determinant | `determinant` | |
| Inverse | `invert` | |
| Eigenvalues | `eigenvalues` | Returns values and multiplicities |
| Eigenvectors | `eigenvectors` | Returns vectors and eigenvalues |
| Characteristic polynomial | `charpoly` | |
| Rank | `rank` | |
| Nullspace | `nullspace` | |
| Trace | `trace_matrix` | |
| Transpose | `transpose` | |
| Row echelon form | `echelon` | |
| Triangularize | `triangularize` | |
| Augmented coefficient matrix | `augcoefmatrix` | For linear systems |
| Coefficient matrix | `coefmatrix` | |
| Add columns | `addcol` | |

### Expression Manipulation

| Problem | Tool | Notes |
|---|---|---|
| Expand (multiply out) | `expand` | (x+1)^3 -> x^3+3x^2+... |
| Factor | `factor` | Over the integers |
| Simplify (rational) | `simplify` | Uses `ratsimp` internally |
| Full rational simplify | `fullratsimp` | Repeated ratsimp until stable |
| Simplify radicals/logs | `radcan` | Canonical form for exp/log/radical |
| Trig simplify | `trigsimp` | Apply trig identities |
| Trig expand | `trigexpand` | sin(a+b) -> sin(a)cos(b)+... |
| Trig reduce | `trigreduce` | Reduce powers: sin^2 -> (1-cos(2x))/2 |
| Trig rational form | `trigrat` | |
| Partial fractions | `partfrac` | Decompose rational expressions |
| Log contract | `logcontract` | Combine log terms |
| Substitution | `subst` | Replace variables/subexpressions |
| Evaluate at values | `ev` | Evaluate with flags/substitutions |
| GCD of polynomials | `gcd` | |
| Extended GCD | `gcdex` | Bezout coefficients |
| Quotient | `quotient` | Polynomial division |
| Remainder | `remainder` | Polynomial remainder |

### Transforms

| Problem | Tool | Notes |
|---|---|---|
| Laplace transform | `laplace` | Specify `t_var` and `s_var` |
| Inverse Laplace | `ilt` | Inverse transform |
| Fourier coefficients | `fourier` | Returns a0, an, bn |
| Fourier cosine coefficients | `fourcos` | |
| Fourier sine coefficients | `foursin` | |
| Full Fourier series | `totalfourier` | Complete expansion |
| Simplify Fourier result | `foursimp` | |
| Expand Fourier series | `fourexpand` | |

### Vector Calculus

| Problem | Tool | Notes |
|---|---|---|
| Gradient | `grad` | Scalar field -> vector |
| Divergence | `div` | Vector field -> scalar |
| Curl | `curl` | Vector field -> vector |
| Scalar potential | `potential` | For conservative fields |
| Vector potential | `vectorpotential` | For solenoidal fields |
| Set coordinate system | `scalefactors` | Before using grad/div/curl |
| Express in components | `express` | Convert vector operators to components |

**Important:** Call `scalefactors` first if not using Cartesian coordinates (e.g. `scalefactors("[r,theta,z]")` for cylindrical).

### Plotting

| Problem | Tool | Notes |
|---|---|---|
| 2D function plot | `plot` | `kind`: "2d", provide `x_range` |
| 3D surface plot | `plot` | `kind`: "3d", provide `x_range` and `y_range` |
| Multiple curves | `plot` | Use `expressions` array |
| Implicit curve (e.g. circle) | `implicit_plot` | Provide equation, x_range, y_range |
| Advanced 2D drawing | `draw2d` | More control: parametric, points, colors |
| Advanced 3D drawing | `draw3d` | Full draw package |
| ODE direction field | `drawdf` | Phase portraits |
| Dedicated 2D plot | `plot2d` | Alternative to `plot` |
| Dedicated 3D plot | `plot3d` | Alternative to `plot` |
| Check plotting support | `plot_capabilities` | What backends are available |

For PNG output (headless), set `output`: "png". Optionally set `width`/`height`.

### Setup & State

| Problem | Tool | Notes |
|---|---|---|
| Assign a variable | `assign` | Persists for session |
| Assume constraint | `assume` | e.g. "x>0" — affects simplification |
| Declare property | `declare` | e.g. "n", "integer" |
| Declare dependency | `depends` | e.g. f depends on x |
| Define a function | `define_function` | Reusable in later calls |
| Set boundary value | `atvalue` | For desolve |
| List assumptions | `list_assumptions` | |
| List variables | `list_variables` | |
| List functions | `list_functions` | |
| Clear/kill | `kill` | Remove definitions |
| Reset session | `reset` | Clean slate |

---

## Tips

- **Format parameter:** All tools accept `format`: "latex" for LaTeX output if the user wants formatted math.
- **Chaining results:** Many workflows require passing output from one tool as input to another (e.g. `ode2` -> `ic1`). Copy the solution string exactly.
- **Assumptions matter:** If simplification isn't working as expected, try `assume` (e.g. "x>0") or `declare` (e.g. declare n as "integer").
- **Numerical vs symbolic:** Try symbolic first (`solve`, `integrate`). Fall back to numerical (`newton`, `find_root`, `quad_qags`) when Maxima can't find a closed form.
- **`evaluate` fallback:** For anything not covered above (e.g. special functions, custom Maxima commands), use `evaluate` with raw Maxima syntax.
