from fastmcp import FastMCP
import logging
from tools.orchestrator_service import orchestrator_mcp
import tools.get_orchestrator_instances
import tools.orchestrator_creation_workflow_rules

# Set up logging to see what's happening
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

mcp = FastMCP(
    name="Current Date and Time", port=8000
)

# Mount the orchestrator service
mcp.mount(orchestrator_mcp, prefix="orchestrator")




if __name__ == "__main__":
    mcp.run(
            transport="http",
            host="0.0.0.0",  # Changed from 127.0.0.1 to allow external connections
        )
