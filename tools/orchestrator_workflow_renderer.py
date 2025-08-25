import json
import logging
from pathlib import Path

from playwright.async_api import async_playwright

from .orchestrator_service import orchestrator_mcp

logger = logging.getLogger(__name__)


class WorkflowRenderer:
    def __init__(self):
        self.html_path = (
            Path(__file__).parent.parent / "assets" / "workflow-renderer" / "index.html"
        )

    async def render_workflow_to_svg(self, workflow_data: str) -> str:
        """
        Render workflow data to SVG using headless browser

        Args:
            workflow_data (str): JSON string of workflow data

        Returns:
            str: SVG content
        """
        logger.info("Starting workflow rendering process...")
        logger.info(f"HTML path: {self.html_path.absolute()}")

        async with async_playwright() as p:
            logger.info("Launching headless browser...")
            browser = await p.chromium.launch()
            page = await browser.new_page()

            page.on(
                "console",
                lambda msg: logger.info(f"Browser console [{msg.type}]: {msg.text}"),
            )
            page.on("pageerror", lambda err: logger.error(f"Browser error: {err}"))

            # Load the HTML file
            logger.info(f"Loading HTML file: file://{self.html_path.absolute()}")
            await page.goto(f"file://{self.html_path.absolute()}")

            # Wait for editor to initialize
            logger.info("Waiting for editor to initialize...")
            await page.wait_for_function("typeof render_workflow === 'function'")
            await page.wait_for_function("ready(); EditorIsReady === true")

            # Execute the workflow rendering on page load
            try:
                # Example rendering
                # await page.evaluate("""
                #     render_workflow(
                #         document.getElementById("renderWorkflow"),
                #         JSON.stringify(sample_data)
                #     );
                # """)

                await page.evaluate(f"""
                    render_workflow(
                        document.getElementById("renderWorkflow"),
                        {workflow_data}
                    );
                """)

                # Get the SVG content
                await page.wait_for_function(
                    "document.getElementById('renderWorkflow')."
                    "querySelector('svg') !== null"
                )
                svg_content = await page.evaluate(
                    "document.getElementById('renderWorkflow').innerHTML"
                )
            except Exception as e:
                logger.error(f"Error calling render_workflow: {e}")
                # Try to get any error messages from the page
                errors = await page.evaluate(
                    "document.querySelector('#renderWorkflow').innerHTML"
                )
                logger.info(f"Container content: {errors}")
                raise

            logger.info(
                f"SVG generated, length: "
                f"{len(svg_content) if svg_content else 0} characters"
            )
            await browser.close()
            logger.info("Browser closed")
            return svg_content


@orchestrator_mcp.tool()
async def orchestrator_preview_workflow(session_id: str, workflow: str) -> str:
    """
    Generate SVG preview of a orchestrator workflow.

    Args:
        session_id: Session identifier for tracking
        workflow: JSON string representing the serverless workflow

    Returns:
        str: SVG content of the rendered workflow
    """
    try:
        logger.info(f"Generating workflow preview for session {session_id}")

        # Validate that workflow is valid JSON
        try:
            json.loads(workflow)
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON workflow: {e}")
            raise ValueError(f"Invalid JSON workflow: {e}")

        # Create renderer and generate SVG
        renderer = WorkflowRenderer()
        svg_content = await renderer.render_workflow_to_svg(workflow)

        logger.info(f"Successfully generated SVG for session {session_id}")
        return svg_content

    except Exception as e:
        logger.error(f"Error generating workflow preview for session {session_id}: {e}")
        raise
