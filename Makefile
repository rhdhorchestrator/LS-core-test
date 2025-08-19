.PHONY: mcp-run mcp-build mcp-up mcp-down mcp-logs help

help:
	@echo "Available targets:"
	@echo "  mcp-run    - Run MCP server locally with uv"

mcp-run:
	uv run python mcp_server.py
