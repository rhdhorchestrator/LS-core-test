from .orchestrator_service import orchestrator_mcp
import logging

logger = logging.getLogger(__name__)

@orchestrator_mcp.tool()
def get_instances(session_id):
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
