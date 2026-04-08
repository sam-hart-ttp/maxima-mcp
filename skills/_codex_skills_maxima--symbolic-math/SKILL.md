---
name: "maxima-symbolic-math"
description: "Use when the task is symbolic algebra, calculus, equation solving, simplification, limits, series, transforms, recurrences, or exact/numerical evaluation and Maxima should do the math instead of hand derivations or general-purpose code."
---

# Maxima Symbolic Math

Use the `maxima` MCP for symbolic mathematics. Prefer dedicated Maxima tools over manual derivations and over the generic `evaluate` fallback.

## Quick Start

- Reset stale session state with `mcp__maxima__reset` before unrelated work.
- Prefer the narrowest tool that matches the task: `solve`, `factor`, `expand`, `simplify`, `integrate`, `differentiate`, `limit`, `sum`, `product`, `taylor`, `laplace`, `ilt`, `ode2`, `solve_rec`, `find_root`, `newton`, `quad_qags`.
- Keep results exact until the user asks for decimals, then use `float` or `bfloat`.
- If the result depends on assumptions, encode them with `assume` and inspect them with `list_assumptions`.

## Workflow

1. Translate the request into the narrowest Maxima operation.
2. Use exact symbolic tools first.
3. Add assumptions only when they materially change the answer.
4. Fall back to `mcp__maxima__evaluate` only when no dedicated tool fits.
5. Return the result with the key expression or command shape when that helps the user audit it.

## Tool Routing

- Algebra and simplification: `factor`, `expand`, `simplify`, `ratsimp`, `fullratsimp`, `radcan`, `trigsimp`, `partfrac`, `gcd`, `realroots`, `allroots`
- Calculus: `differentiate`, `integrate`, `limit`, `taylor`, `sum`, `product`
- Differential equations and transforms: `ode2`, `ic1`, `ic2`, `bc2`, `desolve`, `laplace`, `ilt`, `solve_rec`, `rk`
- Numerical follow-up: `find_root`, `newton`, `mnewton`, `quad_qags`, `romberg`, `float`, `bfloat`
- Discovery: `describe`, `example`, `apropos`, or `read_mcp_resource` on `maxima://docs/topic/{name}`

## Quality Rules

- Do not do hand algebra when Maxima can compute it directly.
- Do not overuse `evaluate` for tasks covered by dedicated tools.
- Clear or reset session state between unrelated problems so assumptions do not leak.
