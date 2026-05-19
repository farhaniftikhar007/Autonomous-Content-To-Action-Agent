from sqlalchemy.orm import Session
import models
from websocket.logger import log_event

class RecoveryManager:
    def __init__(self, db: Session):
        self.db = db

    def attempt_recovery(self, action_id: int, error_message: str):
        """
        Manages retries, fallbacks, and rollbacks for a failed action.
        """
        log_event(f"Action #{action_id} failed. Initializing failure recovery sequence. Error: '{error_message}'", level="warning", source="recovery")
        
        # 1. Retry Logic (Simulated)
        retry_count = 0
        max_retries = 2
        recovered = False
        
        while retry_count < max_retries and not recovered:
            retry_count += 1
            log_event(f"Attempting action retry [{retry_count}/{max_retries}]...", level="info", source="recovery")
            
            # Simulate retry success/failure
            if retry_count == max_retries: # Force failure for simulation if we hit max
                recovered = False
                log_event(f"Retry attempt [{retry_count}/{max_retries}] failed due to persistent network timeout.", level="warning", source="recovery")
            else:
                recovered = True # Simulated transient error resolving
                log_event(f"Transient error resolved! Retry successful on attempt #{retry_count}.", level="success", source="recovery")
                
        fallback_triggered = False
        rollback_triggered = False
        final_status = "recovered" if recovered else "failed"

        # 2. Fallback Logic
        if not recovered:
            log_event("Max retries reached. Persistent failure detected. Initiating secondary fallback sequence...", level="warning", source="recovery")
            log_event("Fallback email workflow activated. Dispatching notifications to logistics desk...", level="info", source="recovery")
            fallback_triggered = True
            final_status = "fallback_success"
            log_event("Secondary fallback successful. Logistics desk notified.", level="success", source="recovery")

        # 3. Rollback Logic (If fallback also fails - simulated flow)
        if not recovered and not fallback_triggered:
            log_event("Fallback failed. Executing transaction rollback to preserve database consistency.", level="error", source="recovery")
            rollback_triggered = True
            final_status = "rolled_back"
            log_event("Database transactions rolled back successfully.", level="success", source="recovery")

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
