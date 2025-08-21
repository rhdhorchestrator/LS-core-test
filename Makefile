.PHONY: mcp-run mcp-build mcp-up mcp-down mcp-logs help

help:
	@echo "Available targets:"
	@echo "  check 		   	- Run ruff check for lint issue"
	@echo "  format    		- Run ruff format"
	@echo "  mcp-run    	- Run MCP server locally with uv"
	@echo "  run-servers    - Run llamastack and lightspeed in a single command for develop"

mcp-run:
	uv run python mcp_server.py

run-servers:
	podman-compose up llama-stack lightspeed-stack

check:
	uv run ruff check . --fix

format:
	uv run ruff format

