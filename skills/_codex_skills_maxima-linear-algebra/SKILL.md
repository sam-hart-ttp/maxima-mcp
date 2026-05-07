---
name: "maxima-linear-algebra"
description: "Use when the task is matrix algebra, determinants, inverses, eigenvalues, eigenvectors, null spaces, ranks, characteristic polynomials, traces, transposes, or linear-system solving and Maxima should perform the computation."
---

# Maxima Linear Algebra

Use the `maxima` MCP for matrix and linear-algebra work. Prefer exact symbolic answers unless the user explicitly wants floating-point output.

## Quick Start

- Build matrices explicitly with `mcp__maxima__matrix` or use existing Maxima matrix expressions.
- Reach for dedicated tools first: `determinant`, `invert`, `rank`, `echelon`, `triangularize`, `charpoly`, `eigenvalues`, `eigenvectors`, `nullspace`, `transpose`, `trace_matrix`, `matrix_multiply`, `solve_linear`, `linsolve`, `fast_linsolve`.
- Use `float` or `bfloat` only after the symbolic structure is understood.
- Reset the Maxima session if prior assignments or assumptions might contaminate the computation.
- Keep variable ordering explicit for systems, characteristic polynomials, null spaces, and eigenspaces.

## Workflow

1. Normalize the matrix or system into a Maxima-friendly representation.
2. Use the most specific matrix tool available.
3. Prefer symbolic decompositions first, then produce numeric approximations only if requested.
4. For large linear systems, try `fast_linsolve` before falling back to generic evaluation.
5. Summarize both the computed result and its mathematical meaning.

## Tool Routing

- Matrix construction and combination: `matrix`, `addcol`, `ident`, `matrix_multiply`, `transpose`
- Structural properties: `determinant`, `rank`, `trace_matrix`, `charpoly`, `nullspace`
- Row reduction and solving: `echelon`, `triangularize`, `solve_linear`, `linsolve`, `fast_linsolve`, `coefmatrix`, `augcoefmatrix`
- Spectral analysis: `eigenvalues`, `eigenvectors`
- Inverses and exact arithmetic cleanup: `invert`, `simplify`, `ratsimp`, `fullratsimp`
- Discovery: `describe`, `example`, `apropos`, or `read_mcp_resource` on `maxima://docs/topic/{name}`

## Common Workflows

- Linear system from equations: keep the variable list explicit, then use `linsolve`; use `coefmatrix`/`augcoefmatrix` when the user needs matrix form.
- Linear system from `A x = b`: use `solve_linear` with the coefficient matrix and RHS vector.
- Large or sparse linear systems: try `fast_linsolve`, then simplify the result with `ratsimp` or `fullratsimp` if needed.
- Eigen workflows: call `charpoly` when the characteristic polynomial matters; call `eigenvalues` and then `eigenvectors` for eigenspaces.
- Invertibility checks: compute `determinant` or `rank` before `invert` when singularity is plausible.

## Quality Rules

- Do not hand-compute row operations or determinants unless the user explicitly wants a worked derivation.
- Keep matrix dimensions and variable ordering explicit in the answer.
- Call out when a result depends on singularity, rank deficiency, or repeated eigenvalues.
- If the user wants a derivation, use Maxima to verify the arithmetic and present the mathematical steps separately.
