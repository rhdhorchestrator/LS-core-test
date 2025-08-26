import logging
import os
import subprocess
import uuid

from .orchestrator_service import orchestrator_mcp

logger = logging.getLogger(__name__)


def get_command():
    base_path = (
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        + "/serverless-workflow"
    )
    return [
        "java",
        "-cp",
        f"{base_path}/target/my-workflow-project-1.0-SNAPSHOT.jar:{base_path}/target/dependency/*",
        "com.example.DefinitionFileExecutor",
    ]


@orchestrator_mcp.tool()
def compile_workflow(session_id: str, workflow: str) -> (bool, str):
    """
    Compile and validate a rhdh orchestrator workflow by writing it to a
    temporary file and executing the validation command.

    Args:
        session_id: The session identifier
        workflow: The workflow content as a string

    Returns:
        A tuple of (success: bool, logs: str)
    """
    logger.info(f"orchestrator_compile_workflow for session_id='{session_id}'")

    # Generate unique filename using UUID
    workflow_uuid = str(uuid.uuid4())
    workflow_path = f"/tmp/workflow-{workflow_uuid}.sw.json"

    try:
        with open(workflow_path, "w") as f:
            f.write(workflow)

        cmd = get_command() + [workflow_path]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

        logs = result.stdout + result.stderr

        try:
            os.remove(workflow_path)
        except OSError:
            pass

        success = result.returncode == 0
        return success, logs

    except Exception as e:
        try:
            os.remove(workflow_path)
        except OSError:
            pass

        logger.error(f"Error compiling workflow: {e}")
        return False, f"Error: {str(e)}"
