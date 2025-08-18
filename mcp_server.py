from fastmcp import FastMCP
import os
import datetime
from typing import Dict, List
import shutil
import logging

# Set up logging to see what's happening
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

mcp = FastMCP(
    name="Current Date and Time", port=8000
)


@mcp.tool()
def get_orchestrator_instances(session_id):
    logger.info(f"get_orchestrator_instances for session_id='{session_id}'")
    """
    return the list of orchestrator instances registered in Backstage or RHDH (Red Hat developer Hub)
    """
    return {
        'total': 5,
        'data': [
            {"name": "process_payment_refunds", "status": "RUNNING"},
            {"name": "sync_inventory_updates", "status": "READY"},
            {"name": "generate_monthly_reports", "status": "RUNNING"},
            {"name": "backup_customer_data", "status": "FAILED"},
            {"name": "send_welcome_emails", "status": "COMPLETED"}
        ]
    }




if __name__ == "__main__":
    mcp.run(
            transport="http",
            host="0.0.0.0",  # Changed from 127.0.0.1 to allow external connections
        )
