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

## Quality Rules

- Do not hand-compute row operations or determinants unless the user explicitly wants a worked derivation.
- Keep matrix dimensions and variable ordering explicit in the answer.
- Call out when a result depends on singularity, rank deficiency, or repeated eigenvalues.
