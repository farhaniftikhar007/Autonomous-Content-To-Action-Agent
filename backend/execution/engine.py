from sqlalchemy.orm import Session
import models
import json
import time
from websocket.logger import log_event

class ActionExecutionEngine:
    def __init__(self, db: Session):
        self.db = db

    def execute_chain(self, action_chain_id: int):
        log_event(f"Initializing Execution Engine for Action Chain #{action_chain_id}...", level="info", source="execution")
        chain = self.db.query(models.ActionChain).filter(models.ActionChain.id == action_chain_id).first()
        if not chain:
            log_event(f"Execution Error: Action Chain #{action_chain_id} not found in DB.", level="error", source="execution")
            return {"status": "error", "message": "Chain not found"}
            
        actions = json.loads(chain.actions_json)
        
        start_time = time.time()
        
        # Dynamically evaluate the DB state to determine the before state
        try:
            inventory = self.db.query(models.InventoryItem).all()
            alerts = self.db.query(models.Alert).filter(models.Alert.is_resolved == False).all()
            low_stock_count = len([i for i in inventory if i.quantity <= i.reorder_level])
            active_threats_count = len(alerts)
        except Exception:
            low_stock_count, active_threats_count = 0, 0
            
        before_state = "Vulnerable (Active Threats)" if (active_threats_count or low_stock_count) else "Routine Operation"
        
        for idx, action in enumerate(actions):
            # Simulated Execution logic
            action_name = action.get("action")
            log_event(f"Executing action [{idx+1}/{len(actions)}]: '{action_name}'", level="info", source="execution")
            
            # Simulate execution time
            time.sleep(0.5) 
            
            action["status"] = "completed"
            
        end_time = time.time()
        after_state = "Secure (Mitigations Executed)"
        latency_ms = int((end_time - start_time) * 1000)
        
        log_event(f"Action Chain #{action_chain_id} finished execution. Latency: {latency_ms}ms.", level="success", source="execution")
        
        # Compute dynamic metrics
        # Operational cost depends on steps executed (e.g. 15.00 PKR per step)
        operational_cost = float(len(actions) * 15.00)
        
        # Risk reduction starts high and is reduced slightly by remaining unmitigated issues
        risk_reduction_score = 0.98 - (active_threats_count * 0.04) - (low_stock_count * 0.015)
        risk_reduction_score = max(0.10, min(0.99, risk_reduction_score))
        
        # Log analytics
        analytic = models.OperationalAnalytic(
            action_chain_id=action_chain_id,
            before_state=before_state,
            after_state=after_state,
            latency_ms=latency_ms,
            operational_cost=operational_cost,
            risk_reduction_score=risk_reduction_score
        )
        self.db.add(analytic)
        
        chain.actions_json = json.dumps(actions)
        chain.execution_status = "completed"
        self.db.commit()
        
        log_event(
            message=f"Logging execution analytics. Risk Reduction Score calculated: {risk_reduction_score*100:.1f}% reduction. Latency: {latency_ms}ms. Est. cost: PKR {operational_cost:,.2f}",
            level="success",
            source="execution"
        )
        
        return {
            "status": "success", 
            "latency_ms": latency_ms,
            "analytic_id": analytic.id
        }
