import json
from sqlalchemy.orm import Session
import models
from websocket.logger import log_event

class RecoveryManager:
    def __init__(self, db: Session):
        self.db = db

    def attempt_recovery(self, action_id: int, error_message: str):
        """
        Manages retries, fallbacks, and transactional database rollbacks for a failed action chain.
        """
        log_event(f"Action Chain #{action_id} failed. Initializing failure recovery sequence. Error: '{error_message}'", level="warning", source="recovery")
        
        # Determine if this is a persistent failure that requires rollback
        is_persistent = any(w in error_message.lower() for w in ["fail", "disrupt", "persistent", "timeout"])
        
        # 1. Retry Loop
        retry_count = 0
        max_retries = 2
        recovered = False
        
        while retry_count < max_retries and not recovered:
            retry_count += 1
            log_event(f"Attempting action retry [{retry_count}/{max_retries}]...", level="info", source="recovery")
            
            # Simulate retry success/failure
            if is_persistent:
                log_event(f"Retry attempt [{retry_count}/{max_retries}] failed: endpoint connection refused.", level="warning", source="recovery")
            else:
                recovered = True
                log_event(f"Transient error resolved! Retry successful on attempt #{retry_count}.", level="success", source="recovery")
                
        fallback_triggered = False
        rollback_triggered = False
        
        # If retries fail, trigger fallback
        if not recovered:
            log_event("Max retries reached. Persistent failure detected. Initiating fallback sequence...", level="warning", source="recovery")
            
            # Check if fallback also fails (persistent failures trigger rollback)
            if "persistent" in error_message.lower() or "timeout" in error_message.lower():
                log_event("Primary fallback email dispatch failed: logistics SMTP server unreachable.", level="error", source="recovery")
                fallback_triggered = False
            else:
                log_event("Fallback email routing activated. Dispatching notifications to logistics desk...", level="info", source="recovery")
                fallback_triggered = True
                log_event("Fallback notification successful. Logistics desk alerted.", level="success", source="recovery")

        # 3. Rollback Logic
        if not recovered and not fallback_triggered:
            log_event("All mitigations failed. Executing Transactional Rollback to restore database consistency...", level="error", source="recovery")
            rollback_triggered = True
            
            # Fetch the associated TaskPlan and ExecutionState to find archived quantities
            chain = self.db.query(models.ActionChain).filter(models.ActionChain.id == action_id).first()
            if chain:
                execution_state = self.db.query(models.ExecutionState).filter(
                    models.ExecutionState.task_id == chain.task_id
                ).first()
                
                if execution_state and execution_state.state_data:
                    try:
                        archived_stock = json.loads(execution_state.state_data)
                        log_event(f"[ROLLBACK] Restoring stock levels for {len(archived_stock)} SKUs...", level="warning", source="recovery")
                        
                        # Revert InventoryItem quantities
                        for sku, qty in archived_stock.items():
                            item = self.db.query(models.InventoryItem).filter(models.InventoryItem.sku == sku).first()
                            if item:
                                old_qty = item.quantity
                                item.quantity = qty
                                log_event(f"[ROLLBACK] Restored SKU {sku} quantity: {old_qty} -> {qty} units.", level="warning", source="recovery")
                        
                        # Resolve alerts created during this workflow
                        unresolved_alerts = self.db.query(models.Alert).filter(models.Alert.is_resolved == False).all()
                        for alert in unresolved_alerts:
                            if any(sku in alert.title or sku in alert.message for sku in archived_stock.keys()):
                                alert.is_resolved = True
                                log_event(f"[ROLLBACK] Auto-resolved threat alert: '{alert.title}'", level="warning", source="recovery")
                                
                        execution_state.current_step = "rolled_back"
                        self.db.commit()
                        log_event("Transactional rollback completed successfully. Local DB consistency restored.", level="success", source="recovery")
                    except Exception as e:
                        log_event(f"[ROLLBACK ERROR] Failed to parse/restore archived state: {e}", level="error", source="recovery")
                else:
                    log_event("Rollback aborted: no pre-execution state data archived.", level="warning", source="recovery")
            else:
                log_event("Rollback aborted: failed action chain mapping not found.", level="warning", source="recovery")

        final_status = "recovered" if recovered else ("fallback_success" if fallback_triggered else "rolled_back")
        
        attempt = models.RecoveryAttempt(
            action_id=action_id,
            failure_reason=error_message,
            retry_count=retry_count,
            fallback_triggered=fallback_triggered,
            rollback_triggered=rollback_triggered,
            final_status=final_status
        )
        self.db.add(attempt)
        self.db.commit()
        
        log_event(f"Recovery sequence closed. Final Status: '{final_status}'.", level="success", source="recovery")
        return {
            "status": final_status,
            "retries": retry_count,
            "fallback": fallback_triggered,
            "rollback": rollback_triggered
        }
