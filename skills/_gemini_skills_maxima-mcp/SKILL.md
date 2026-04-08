---
name: maxima-mcp
description: Perform symbolic mathematics, calculus, algebra, and linear algebra using the Maxima Computer Algebra System. Use when you need to solve complex equations, differentiate/integrate functions, or perform matrix operations that require symbolic precision.
---

# Maxima MCP

## Overview
This skill leverages the `maxima-mcp` server to perform advanced symbolic mathematics. Maxima is a full-featured computer algebra system (CAS) that handles symbolic differentiation, integration, Taylor series, Laplace transforms, ordinary differential equations, systems of linear equations, and more.

## Core Capabilities

### 1. Calculus
Perform symbolic differentiation, integration, and limit calculations.
- **Tools**: `differentiate`, `integrate`, `limit`
- **Example**: "Differentiate x^2 * sin(x) with respect to x"
- **Example**: "Integrate 1/(1+x^2) from 0 to infinity"

### 2. Equation Solving
Solve algebraic equations and systems of equations.
- **Tools**: `solve`, `allroots`, `find_root`
- **Example**: "Solve x^2 - 5x + 6 = 0 for x"
- **Example**: "Solve the system [x+y=10, x-y=2]"

### 3. Algebraic Manipulation
Simplify, expand, factor, and perform partial fraction decomposition.
- **Tools**: `ratsimp`, `expand`, `factor`, `partfrac`
- **Example**: "Simplify (x^2-1)/(x-1)"
- **Example**: "Expand (a+b)^5"

### 4. Linear Algebra
Perform matrix operations, including determinants, inverses, and eigenvalues.
- **Tools**: `determinant`, `invert`, `eigenvalues`, `eigenvectors`
- **Example**: "Find the determinant of matrix [[1,2],[3,4]]"

### 5. Help and Discovery
Use built-in help tools to discover Maxima functions and their usage.
- **Tools**: `capabilities`, `describe`, `example`, `apropos`
- **Note**: Use `describe(topic="...")` to get detailed documentation for any Maxima function.

## Tips for Success
- **Explicit Variable Passing**: Always specify the variable of interest (e.g., `variable="x"`) to ensure correct results.
- **Check Assumptions**: Use `assume(x>0)` if you encounter issues with square roots or logs of potentially negative values.
- **Output Formats**: Use `evaluate` for general expressions and specify the `format` (e.g., "latex" or "text") as needed.
