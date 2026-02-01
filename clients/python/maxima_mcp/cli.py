#!/usr/bin/env python3
"""
Command-line interface for the Maxima MCP client.

Provides an interactive REPL for testing the Maxima MCP server.
"""

import argparse
import json
import readline  # Enable line editing
import sys
from typing import Optional

from .client import MaximaMCPClient, MaximaError


def create_parser() -> argparse.ArgumentParser:
    """Create the argument parser."""
    parser = argparse.ArgumentParser(
        description="Maxima MCP Client - Interactive interface to Maxima via MCP",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Start interactive REPL
  maxima-mcp-client

  # Evaluate a single expression
  maxima-mcp-client -e "integrate(x^2, x)"

  # Use a specific server command
  maxima-mcp-client --server ./maxima-mcp

  # Output in LaTeX format
  maxima-mcp-client -e "diff(sin(x), x)" --format latex
""",
    )

    parser.add_argument(
        "-e",
        "--eval",
        metavar="EXPR",
        help="Evaluate a single expression and exit",
    )

    parser.add_argument(
        "--server",
        metavar="CMD",
        help="Command to run the MCP server",
    )

    parser.add_argument(
        "--format",
        choices=["text", "latex", "mathml", "lisp"],
        default="text",
        help="Output format (default: text)",
    )

    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw JSON responses",
    )

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose output",
    )

    return parser


def print_help():
    """Print REPL help message."""
    print(
        """
Maxima MCP Client - Interactive Mode

Commands:
  help, ?           Show this help message
  quit, exit, q     Exit the client
  tools             List available tools
  format <fmt>      Set output format (text, latex, mathml, lisp)

Math operations - just type Maxima expressions:
  2 + 2
  diff(x^2, x)
  integrate(sin(x), x)
  solve(x^2 - 4 = 0, x)
  factor(x^3 - 1)
  expand((x + 1)^3)
  taylor(sin(x), x, 0, 5)
  limit(sin(x)/x, x, 0)
  matrix([1,2],[3,4])
  determinant(matrix([1,2],[3,4]))
  eigenvalues(matrix([1,2],[3,4]))

Session management:
  x : 5             Assign value to variable
  assume(x > 0)     Add assumption
  forget(x > 0)     Remove assumption
  facts()           List assumptions
  values            List variables
  reset()           Reset session

Press Ctrl+D or type 'quit' to exit.
"""
    )


def repl(client: MaximaMCPClient, output_format: str = "text", json_output: bool = False):
    """Run an interactive REPL."""
    print("Maxima MCP Client")
    print("Type 'help' for commands, 'quit' to exit.\n")

    current_format = output_format

    while True:
        try:
            line = input("(%i) ").strip()
        except EOFError:
            print("\nGoodbye!")
            break
        except KeyboardInterrupt:
            print("\nInterrupted. Type 'quit' to exit.")
            continue

        if not line:
            continue

        # Handle commands
        lower_line = line.lower()
        if lower_line in ("quit", "exit", "q"):
            print("Goodbye!")
            break
        elif lower_line in ("help", "?"):
            print_help()
            continue
        elif lower_line == "tools":
            try:
                tools = client.list_tools()
                print(f"\nAvailable tools ({len(tools)}):")
                for tool in sorted(tools, key=lambda t: t.get("name", "")):
                    print(f"  {tool.get('name')}: {tool.get('description', '')[:60]}...")
                print()
            except MaximaError as e:
                print(f"Error: {e}")
            continue
        elif lower_line.startswith("format "):
            fmt = lower_line[7:].strip()
            if fmt in ("text", "latex", "mathml", "lisp"):
                current_format = fmt
                print(f"Output format set to: {fmt}")
            else:
                print("Invalid format. Use: text, latex, mathml, or lisp")
            continue

        # Evaluate expression
        try:
            result = client.evaluate(line, format=current_format)
            if json_output:
                print(json.dumps({"result": result}, indent=2))
            else:
                print(f"(%o) {result}")
        except MaximaError as e:
            if json_output:
                print(json.dumps({"error": str(e)}, indent=2))
            else:
                print(f"Error: {e}")


def main():
    """Main entry point."""
    parser = create_parser()
    args = parser.parse_args()

    # Build server command
    server_command = None
    if args.server:
        server_command = args.server.split()

    try:
        with MaximaMCPClient(server_command=server_command) as client:
            if args.eval:
                # Single expression mode
                try:
                    result = client.evaluate(args.eval, format=args.format)
                    if args.json:
                        print(json.dumps({"result": result}))
                    else:
                        print(result)
                except MaximaError as e:
                    if args.json:
                        print(json.dumps({"error": str(e)}))
                    else:
                        print(f"Error: {e}", file=sys.stderr)
                    sys.exit(1)
            else:
                # Interactive mode
                repl(client, output_format=args.format, json_output=args.json)

    except FileNotFoundError:
        print(
            "Error: Could not find maxima-mcp server. "
            "Use --server to specify the path.",
            file=sys.stderr,
        )
        sys.exit(1)
    except Exception as e:
        if args.verbose:
            import traceback
            traceback.print_exc()
        else:
            print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
