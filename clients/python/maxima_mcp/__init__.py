"""
Maxima MCP Client

A Python client for interacting with the Maxima computer algebra system
via the Model Context Protocol (MCP).
"""

from .client import MaximaMCPClient, MaximaError, MaximaTimeoutError

__version__ = "0.1.0"
__all__ = ["MaximaMCPClient", "MaximaError", "MaximaTimeoutError"]
