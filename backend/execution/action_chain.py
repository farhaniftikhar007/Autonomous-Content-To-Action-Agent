import json

class ActionChainGenerator:
    def __init__(self):
        pass

    def generate_chain(self, task_description: str) -> str:
        """
        Generates a Multi-Step Action Chain based on the task description.
        Returns a JSON string representation of the chain.
        """
        # Phase 1: Mock action chain generation
        chain = []
        
        if "contradiction" in task_description.lower():
            chain = [
                {"step": 1, "action": "fetch_source_a", "status": "pending"},
                {"step": 2, "action": "fetch_source_b", "status": "pending"},
                {"step": 3, "action": "compare_timestamps", "status": "pending"}
            ]
        elif "reorder" in task_description.lower():
            chain = [
                {"step": 1, "action": "check_budget", "status": "pending"},
                {"step": 2, "action": "draft_po", "status": "pending"},
                {"step": 3, "action": "send_to_supplier", "status": "pending"}
            ]
        else:
            chain = [
                {"step": 1, "action": "log_diagnostic", "status": "pending"}
            ]
            
        return json.dumps(chain)
