import logging
from pathlib import Path

from .orchestrator_service import orchestrator_mcp

logger = logging.getLogger(__name__)

SERVERLESS_JSON_PATH = "serverless-workflow/consolidated_workflow_schema.json"

# Cache for schema content
_schema_cache = None


@orchestrator_mcp.tool()
def get_schema_rules(session_id: str) -> str:
    """
    Retrieve the complete orchestrator workflow schema for orchestrator operations.

    This tool returns the full consolidated workflow schema from the orchestrator-workflow
    specification. Use this when you need to understand the complete schema structure,
    validate workflow definitions, or reference specific schema components.

    Args:
        session_id (str): Session identifier for logging and tracking purposes

    Returns:
        str: Complete JSON schema as a string, or error message if schema cannot be loaded

    Note:
        Only request this when you need schema validation or have specific questions
        about the workflow structure, as it returns the entire schema document.
    """  # noqa: E501
    global _schema_cache

    logger.info(f"get_filtered_schema_rules for session_id='{session_id}'")

    # Return cached content if available
    if _schema_cache is not None:
        return _schema_cache

    # Load and cache the schema
    input_path = Path(SERVERLESS_JSON_PATH)
    if not input_path.exists():
        return "Error: cannot load the orchestrator-workflow schema"

    try:
        with open(input_path, "r", encoding="utf-8") as f:
            _schema_cache = f.read()
        return _schema_cache
    except Exception as e:
        logger.error(f"Error reading schema file: {e}")
        return "Error: cannot read the orchestrator-workflow schema"
