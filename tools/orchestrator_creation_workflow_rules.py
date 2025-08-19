from .orchestrator_service import orchestrator_mcp
import logging
from typing import Dict, List, Any

logger = logging.getLogger(__name__)

@orchestrator_mcp.tool()
def creation_workflow_rules(session_id: str) -> Dict[str, Any]:
    """
    List all orchestrator workflow rules before creating or modify any orchestrator workflow instance.

    Args:
        session_id: The session identifier

    Returns:
        List of rules that we need to follow before creating a orchestrator-workflow
    """
    logger.info(f"orchestrator_creation_workflow_rules for session_id='{session_id}'")

    return ""
