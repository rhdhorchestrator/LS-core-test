import logging

from fastmcp import FastMCP

from tools.orchestrator_service import orchestrator_mcp

# Set up logging to see what's happening
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

mcp = FastMCP(name="Current Date and Time", port=8000)

# Mount the orchestrator service
mcp.mount(orchestrator_mcp, prefix="orchestrator")


if __name__ == "__main__":
    mcp.run(
        transport="http",
        host="0.0.0.0",
    )
