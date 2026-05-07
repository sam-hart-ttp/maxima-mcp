---
name: "maxima-symbolic-math"
description: "Use when the task is symbolic algebra, calculus, equation solving, simplification, limits, series, transforms, recurrences, or exact/numerical evaluation and Maxima should do the math instead of hand derivations or general-purpose code."
---

# Maxima Symbolic Math

Use the `maxima` MCP for symbolic mathematics. Prefer dedicated Maxima tools over manual derivations and over the generic `evaluate` fallback.

## Quick Start

- Reset stale session state with `mcp__maxima__reset` before unrelated work.
- Prefer the narrowest tool that matches the task: `solve`, `factor`, `expand`, `simplify`, `integrate`, `differentiate`, `limit`, `sum`, `product`, `taylor`, `laplace`, `ilt`, `ode2`, `solve_rec`, `find_root`, `newton`, `quad_qags`, `plot`, `plot_capabilities`.
- Keep results exact until the user asks for decimals, then use `float` or `bfloat`.
- State mathematical assumptions explicitly before symbolic work; encode them with `assume` and inspect them with `list_assumptions` when they affect the result.

## Workflow

1. Translate the request into the narrowest Maxima operation.
2. Use exact symbolic tools first.
3. Identify variables and assumptions before calculus, solving, simplification, or transforms.
4. Fall back to `mcp__maxima__evaluate` only when no dedicated tool fits.
5. Return the result with the key expression or command shape when that helps the user audit it.

## Tool Routing

- Solving: `solve` for symbolic equations and systems, `find_root` for bracketed numerical roots, `newton`/`mnewton` for Newton workflows, `allroots` for numerical polynomial roots
- Algebra and simplification: `factor`, `expand`, `simplify`, `ratsimp`, `fullratsimp`, `radcan`, `trigsimp`, `trigexpand`, `trigreduce`, `trigrat`, `partfrac`, `gcd`, `gcdex`, `quotient`, `remainder`
- Calculus: `differentiate`, `integrate`, `limit`, `taylor`, `sum`, `product`
- Differential equations and transforms: `ode2`, `ic1`, `ic2`, `bc2`, `desolve`, `laplace`, `ilt`, `solve_rec`, `rk`
- Numerical follow-up: `quad_qags`, `romberg`, `float`, `bfloat`
- Fourier and vector calculus: `fourier`, `fourexpand`, `foursimp`, `fourcos`, `foursin`, `totalfourier`, `scalefactors`, `grad`, `div`, `curl`, `potential`, `vectorpotential`
- Plotting: call `plot_capabilities` first when output support matters; use `plot`, `plot2d`, `plot3d`, `implicit_plot`, `draw2d`, `draw3d`, or `drawdf` as appropriate
- State and definitions: `assign`, `get_value`, `assume`, `forget`, `declare`, `depends`, `define_function`, `atvalue`, `reset`
- Discovery: `describe`, `example`, `apropos`, or `read_mcp_resource` on `maxima://docs/topic/{name}`

## Common Workflows

- Initial/boundary value ODEs: call `ode2`, then pass the exact solution string to `ic1`, `ic2`, or `bc2`.
- Nonlinear numerical solving: prefer `find_root` when a bracket is known; use `newton`/`mnewton` when an initial guess is natural.
- Plots in headless contexts: request PNG output; for interactive contexts, discover support with `plot_capabilities` before asking for a window.
- Coordinate-sensitive vector calculus: call `scalefactors` before `grad`, `div`, or `curl` when not using Cartesian coordinates.

## Quality Rules

- Do not do hand algebra when Maxima can compute it directly.
- Do not overuse `evaluate` for tasks covered by dedicated tools.
- Clear or reset session state between unrelated problems so assumptions do not leak.
- If Maxima returns a conditional, asks for assumptions, or produces a preflight warning, surface the assumption issue clearly instead of hiding it.
