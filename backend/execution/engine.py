from sqlalchemy.orm import Session
import models
import json
import time
from websocket.logger import log_event

class ActionExecutionEngine:
    def __init__(self, db: Session):
        self.db = db

    def execute_chain(self, action_chain_id: int, workflow_name: str = ""):
        log_event(f"Initializing Execution Engine for Action Chain #{action_chain_id}...", level="info", source="execution")
        chain = self.db.query(models.ActionChain).filter(models.ActionChain.id == action_chain_id).first()
        if not chain:
            log_event(f"Execution Error: Action Chain #{action_chain_id} not found in DB.", level="error", source="execution")
            return {"status": "error", "message": "Chain not found"}
            
        actions = json.loads(chain.actions_json)
        start_time = time.time()
        
        # 1. Capture and store the initial database inventory state before edits
        try:
            items = self.db.query(models.InventoryItem).all()
            initial_state = {item.sku: item.quantity for item in items}
            
            # Store initial state in ExecutionState model
            execution_state = self.db.query(models.ExecutionState).filter(
                models.ExecutionState.task_id == chain.task_id
            ).first()
            if not execution_state:
                execution_state = models.ExecutionState(
                    task_id=chain.task_id,
                    current_step="start",
                    state_data=json.dumps(initial_state)
                )
                self.db.add(execution_state)
            else:
                execution_state.state_data = json.dumps(initial_state)
            self.db.commit()
            log_event("[DATABASE] Initial stock levels archived in transactional state table.", level="info", source="execution")
        except Exception as exc:
            log_event(f"Warning: failed to archive pre-execution state: {exc}", level="warning", source="execution")
            
        try:
            alerts = self.db.query(models.Alert).filter(models.Alert.is_resolved == False).all()
            low_stock_count = len([i for i in items if i.quantity <= i.reorder_level])
            active_threats_count = len(alerts)
        except Exception:
            low_stock_count, active_threats_count = 0, 0
            
        before_state = "Vulnerable (Active Threats)" if (active_threats_count or low_stock_count) else "Routine Operation"
        
        # Determine if we should simulate a failure based on the workflow name / query
        should_simulate_failure = False
        wf_name_lower = (workflow_name or "").lower()
        if any(keyword in wf_name_lower for keyword in ["fail", "error", "simulate failure", "disrupt"]):
            should_simulate_failure = True
            log_event("[SIMULATOR] FAILURE TRIGGER DETECTED: Execution failure simulation enabled.", level="warning", source="execution")

        for idx, action in enumerate(actions):
            action_name = action.get("action")
            log_event(f"Executing action [{idx+1}/{len(actions)}]: '{action_name}'", level="info", source="execution")
            
            # Rate limit constraint simulation
            time.sleep(0.5) 
            log_event(f"[RATE LIMITER] Enforcing API rate limit constraint: throttling step '{action_name[:30]}...'", level="info", source="execution")
            
            # If simulating failure, trigger failure on step 3 (e.g. simulate emergency order / PO step)
            if should_simulate_failure and idx == 2:
                action["status"] = "failed"
                chain.actions_json = json.dumps(actions)
                self.db.commit()
                log_event(f"[API ERROR] Step '{action_name}' execution failed: supplier network timeout (PKR 50k PO limit connection timeout).", level="error", source="execution")
                return {
                    "status": "failed",
                    "step": idx + 1,
                    "error": f"Simulated emergency order notification failure: Connection timeout on step '{action_name}'"
                }

            # Simulate stock update if this is a PO replenishment step
            if "po" in action_name.lower() or "reorder" in action_name.lower():
                try:
                    for item in items:
                        if item.quantity <= item.reorder_level:
                            old_qty = item.quantity
                            item.quantity += 50
                            log_event(f"[DATABASE] Updated SKU {item.sku} quantity: {old_qty} -> {item.quantity} (mock replenishment PO).", level="success", source="execution")
                    self.db.commit()
                except Exception as e:
                    pass

            action["status"] = "completed"
            
        end_time = time.time()
        after_state = "Secure (Mitigations Executed)"
        latency_ms = int((end_time - start_time) * 1000)
        
        log_event(f"Action Chain #{action_chain_id} finished execution. Latency: {latency_ms}ms.", level="success", source="execution")
        
        operational_cost = float(len(actions) * 15.00)
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
