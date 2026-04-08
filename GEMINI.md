# Maxima MCP Project Overview for Gemini

This document provides a comprehensive overview of the Maxima MCP (Model Context Protocol) project, derived from an analysis of its codebase and documentation. It is intended to serve as instructional context for future interactions with the Gemini CLI.

## 1. Project Overview

The Maxima MCP project is an implementation of a Model Context Protocol server specifically designed for Maxima, the powerful open-source computer algebra system. Its primary purpose is to enable AI assistants, such as Claude, to seamlessly interact with Maxima for advanced symbolic mathematics and computations.

### Key Features:
*   **Symbolic Mathematics**: Supports core operations like differentiation, integration, limits, Taylor series, sums, and products.
*   **Equation Solving**: Capable of solving algebraic equations and systems.
*   **Algebraic Manipulation**: Provides tools for simplification, factoring, expansion, and partial fraction decomposition.
*   **Linear Algebra**: Functionality for matrices, determinants, eigenvalues, inverses, and linear system solving.
*   **Calculus & Differential Equations**: Includes advanced features for ODEs, Laplace transforms, and vector calculus.
*   **Plotting**: Generates 2D/3D plots (PNG output or graphical windows where available).
*   **Session State Management**: Manages variable assignments, assumptions, and function definitions across interactions.
*   **Multiple Output Formats**: Results can be output in plain text, LaTeX, MathML, or internal Lisp representation.
*   **Multi-Lisp Support**: Developed primarily in Common Lisp, supporting various implementations including SBCL, ECL, ABCL, CLISP, CMUCL, GCL, and CCL (OpenMCL).

The project adopts a client-server architecture, where AI assistants act as clients, sending requests to the Maxima MCP server to leverage Maxima's computational capabilities.

## 2. Building and Running

### Prerequisites

*   **Common Lisp Implementation**: Depending on the desired build, one of SBCL (Steel Bank Common Lisp), ECL (Embeddable Common Lisp), or ABCL (Armed Bear Common Lisp) is required for building from source. Other Lisp implementations (CLISP, CMUCL, GCL, ACL, OpenMCL/CCL) are also supported via the Autotools configuration.
*   **Autotools**: The project uses GNU Autoconf and Automake for its build system.
*   **`makeinfo`**: Required for building documentation, with version 5.1 or newer recommended.

### Building from Source

The general build process follows standard Autotools conventions:

1.  **Generate `configure` script**:
    ```bash
    autoreconf -i
    ```
2.  **Configure the project**:
    ```bash
    ./configure
    ```
    This step can be customized with various `--enable-<lisp>` or `--with-<lisp>=<path>` options to specify the desired Lisp implementation.
    Example: `./configure --enable-sbcl`
3.  **Build the project**:
    ```bash
    make
    ```

Specific build commands for different Lisp implementations (from `README.md`):

*   **SBCL (Steel Bank Common Lisp)**:
    ```bash
    cd src/mcp
    sbcl --load build-standalone.lisp
    ```
    Build tuning can be applied using environment variables:
    ```bash
    MAXIMA_MCP_CONTROL_STACK_MB=512 \
    MAXIMA_MCP_DYNAMIC_SPACE_MB=4096 \
    MAXIMA_MCP_USE_CORE=1 \
    sbcl --load build-standalone.lisp
    ```
*   **ECL (Embeddable Common Lisp)**:
    ```bash
    cd src/mcp
    ecl --load build-standalone-ecl.lisp
    # For subprocess backend:
    ecl --load build-standalone-ecl-subprocess.lisp
    ```
*   **ABCL (Armed Bear Common Lisp)**:
    ```bash
    cd src/mcp
    abcl --load build-abcl-jar.lisp
    # For subprocess backend:
    MAXIMA_MCP_SUBPROCESS=1 abcl --load build-abcl-jar.lisp
    ```

### Usage

*   **With Claude Code (or other AI assistants)**:
    Configure your `~/.claude.json` (or equivalent for other assistants) to point to the `maxima-mcp` executable:
    ```json
    {
      "mcpServers": {
        "maxima": {
          "command": "/path/to/maxima-mcp"
        }
      }
    }
    ```
*   **Standalone Testing (JSON-RPC)**:
    ```bash
    echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"evaluate","arguments":{"expression":"diff(x^3,x)"}}}' | ./maxima-mcp
    ```

### Environment Variables

*   `MAXIMA_MCP_CONTROL_STACK_MB`, `MAXIMA_MCP_DYNAMIC_SPACE_MB`: Tune SBCL build memory.
*   `MAXIMA_MCP_USE_CORE`: Set to `1` to use an existing SBCL core (if present) and skip recompiling Maxima.
*   `MAXIMA_MCP_SUBPROCESS`: Used during ABCL build to package the subprocess backend.
*   `MAXIMA_MCP_SUBPROCESS_MODE`: Controls subprocess backend mode (`batch` or `interactive`).
*   `MAXIMA_MCP_SUBPROCESS_DEBUG`: Set to `1` for logging raw subprocess output.
*   `GCL_ANSI`: `export GCL_ANSI=t` (used on Debian-based systems for GCL).
*   `GCL_MEM_MULTIPLE`: `export GCL_MEM_MULTIPLE=0.1` (for GCL testbench on old memory management).

## 3. Development Conventions

*   **License**: The project is distributed under the GNU General Public License (GPL-2.0), consistent with Maxima itself.
*   **Build System**: Utilizes `autoconf` and `automake` (Autotools) for cross-platform compilation and configuration.
*   **Lisp Implementations**: The codebase is designed to be compatible with a broad range of Common Lisp implementations. Configuration flags (e.g., `--enable-sbcl`, `--with-clisp`) are used during `./configure` to specify the target Lisp.
*   **Subprocess Modes**: The server can operate in `batch` mode (stateless, fresh Maxima process per call) or `interactive` mode (persistent Maxima process), controlled by `MAXIMA_MCP_SUBPROCESS_MODE`. Developers should be aware of state persistence differences between these modes.
*   **Documentation Generation**: Documentation is built using `makeinfo`. The build process supports syntax highlighting for HTML documentation, configurable via `./configure --enable-syntax-highlighting` with options like `highlightjs` or `pygments`.
*   **Testing**: The project includes a `tests/` directory, and `make check` can be used to run tests. Specific considerations for Lisp implementations (e.g., GCL memory management) are handled in the `configure` script.
*   **Windows Cross-Compilation**: The `crosscompile-windows/` directory and related `Makefile.am` rules indicate support for building Windows executables, including integration with `gnuplot` and `wxMaxima`.
*   **Python Client**: A Python client library is provided in `clients/python/` for easier integration with Python applications.
