import logging
from pathlib import Path
from typing import Literal

from .orchestrator_service import orchestrator_mcp

logger = logging.getLogger(__name__)


EXAMPLES_DIR = Path(__file__).parent / "examples"
CATEGORIES = ("conditional_logic", "http_requests", "iteration", "scheduling")


class WorkflowExample:
    @classmethod
    def load(cls, category: str):
        input_file = EXAMPLES_DIR / f"{category}_input.txt"
        output_file = EXAMPLES_DIR / f"{category}_output.txt"

        input_text = ""
        output_text = ""

        try:
            input_text = input_file.read_text(encoding="utf-8").strip()
            output_text = output_file.read_text(encoding="utf-8").strip()
        except FileNotFoundError as e:
            logger.warning(f"Example workflow file not found: {e}")

        return cls(category, input_text, output_text)

    def __init__(self, category: str, input_text: str, output_text: str):
        self.category = category
        self.input = input_text
        self.output = output_text

    def llm_output(self) -> str:
        """Render this workflow example into a formatted string for LLM consumption."""
        output = f"## Workflow Example: {self.category.replace('_', ' ').title()}\n\n"

        output += "<input_example>\n"
        output += self.input + "\n"
        output += "</input_example>\n\n"

        output += "<output_example>\n"
        output += self.output + "\n"
        output += "</output_example>\n"

        return output


SAMPLES = {category: WorkflowExample.load(category) for category in CATEGORIES}


@orchestrator_mcp.tool()
def get_sample_workflow(
    session_id: str,
    category: Literal[CATEGORIES],
) -> str:
    """
    Get a comprehensive sample workflow with example input and expected output.

    This tool provides a complete example for the following categories:
    - http_requests: HTTP API calls with error handling and logging
    - iteration: Foreach loops and array processing
    - scheduling: Cron-based scheduled workflows
    - conditional_logic: Switch states and subflow actions

    Use this as a reference when creating new workflows to understand the complete
    structure and see how user requirements translate to workflow implementation.

    Args:
        session_id (str): Session identifier for logging and tracking purposes
        category (str): The workflow category to retrieve example for

    Returns:
        str: a string containing example input and expected workflow output
    """
    logger.info(f"orchestrator_get_sample_workflow for session_id='{session_id}'")

    sample = SAMPLES.get(category)
    if not sample:
        return f"Sample with {category} cannot be found"
    return sample.llm_output()
