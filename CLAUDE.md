# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Maxima MCP is a Model Context Protocol (MCP) server that exposes Maxima (a computer algebra system) as a tool for AI assistants. It enables symbolic mathematics operations through JSON-RPC 2.0 over stdio.

## Build Commands

### SBCL (primary)
```bash
cd src/mcp
sbcl --load build-standalone.lisp
```

Build tuning environment variables:
- `MAXIMA_MCP_CONTROL_STACK_MB=512` - control stack size
- `MAXIMA_MCP_DYNAMIC_SPACE_MB=4096` - heap size
- `MAXIMA_MCP_USE_CORE=1` - use existing Maxima core if available

### ECL (library mode)
```bash
cd src/mcp
ecl --load build-standalone-ecl.lisp
```

### ECL (subprocess mode)
```bash
cd src/mcp
ecl --load build-standalone-ecl-subprocess.lisp
```

### ABCL
```bash
cd src/mcp
abcl --load build-abcl-jar.lisp
```

## Testing

```bash
cd clients/python
pip install -e ".[dev]"
pytest tests/
```

Manual JSON-RPC testing:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"evaluate","arguments":{"expression":"diff(x^3,x)"}}}' | ./maxima-mcp
```

## Architecture

### Two Runtime Modes

1. **Library Mode** (SBCL/ECL/ABCL default): Loads Maxima as a Common Lisp library. Persistent session state, faster execution. Core files: `main.lisp`, `session.lisp`, `tools*.lisp`

2. **Subprocess Mode**: Spawns system `maxima` binary. Has two sub-modes:
   - `batch` (default) - stateless, fresh process per call
   - `interactive` - persistent Maxima process
   Core files: `main-subprocess.lisp`, `maxima-subprocess.lisp`

### Source Structure (`src/mcp/`)

- `package.lisp` - Package definitions
- `main.lisp` - Entry point, executable builds
- `protocol.lisp` - MCP protocol (JSON-RPC 2.0 dispatch)
- `transport.lisp` - Stdio message I/O
- `json.lisp` - JSON encoding/decoding (yason library)
- `session.lisp` - Session state management
- `format.lisp` - Output formatting (text/latex/mathml/lisp)
- `tools.lisp` - Tool registry infrastructure with `define-mcp-tool` macro
- `tools-*.lisp` - Tool implementations organized by category (core, calculus, algebra, matrix, linear, ode, vector, fourier, list, misc, extra, plot, session, meta)
- `errors.lisp` - Error handling with MCP error codes
- `maxima-mcp.asd` - ASDF system definition
- `build-standalone*.lisp` - Build scripts for different Lisp implementations

### Protocol Flow

```
stdin → transport.lisp → protocol.lisp → tool handlers → Maxima → format.lisp → stdout
```

### Tool System

Tools are registered in `*mcp-tools*` hash-table. Each tool is an `mcp-tool` struct with name, description, input-schema (JSON schema), and handler function. Use `define-mcp-tool` macro to add new tools.

### Session State

`mcp-session` struct tracks: id, variables (hash-table), default-format, and created-at timestamp.

## Dependencies

**Lisp**: maxima, yason, uiop

**Python client**: stdlib only (pytest for dev)

## Environment Variables

Subprocess mode:
- `MAXIMA_MCP_SUBPROCESS_MODE=batch|interactive`
- `MAXIMA_MCP_SUBPROCESS_DEBUG=1` - log raw output to stderr

Build:
- `MAXIMA_MCP_SUBPROCESS=1` - build subprocess backend (ABCL)
