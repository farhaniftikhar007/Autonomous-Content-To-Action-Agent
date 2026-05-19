from sqlalchemy.orm import Session
import models
from websocket.logger import log_event

def sync_threats(db: Session):
    """
    Dynamically scans the database for operational anomalies and syncs them
    with the Alert table. Automatically resolves threats when conditions improve.
    """
    # Retrieve existing unresolved alerts to check against to prevent duplication
    unresolved_alerts = db.query(models.Alert).filter(models.Alert.is_resolved == False).all()
    
    def get_alert_by_title_prefix(prefix: str):
        for alert in unresolved_alerts:
            if alert.title.startswith(prefix):
                return alert
        return None

    # 1. Stock Shortages
    inventory = db.query(models.InventoryItem).all()
    active_shortage_skus = set()
    for item in inventory:
        if item.quantity <= item.reorder_level:
            active_shortage_skus.add(item.sku)
            prefix = f"[HIGH] Stock Shortage: {item.sku}"
            alert = get_alert_by_title_prefix(prefix)
            if not alert:
                new_alert = models.Alert(
                    title=prefix,
                    message=f"Stock for '{item.name}' ({item.sku}) is at {item.quantity} units, which is below the reorder level of {item.reorder_level} units.",
                    is_resolved=False
                )
                db.add(new_alert)
                log_event(f"Threat Engine generated new alert: {prefix}", level="warning", source="system")
    
    # Auto-resolve shortage alerts
    for alert in unresolved_alerts:
        if alert.title.startswith("[HIGH] Stock Shortage:"):
            sku = alert.title.split(": ")[1]
            if sku not in active_shortage_skus:
                alert.is_resolved = True
                log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")

    # 2. Supplier Delays
    suppliers = db.query(models.Supplier).all()
    active_delay_supplier_ids = set()
    for supplier in suppliers:
        if supplier.avg_delay_days > 2.5 or supplier.reliability_score < 0.8:
            active_delay_supplier_ids.add(str(supplier.id))
            prefix = f"[MEDIUM] Supplier Disruption: {supplier.name} (ID: {supplier.id})"
            alert = get_alert_by_title_prefix(prefix)
            if not alert:
                new_alert = models.Alert(
                    title=prefix,
                    message=f"Supplier '{supplier.name}' (ID: {supplier.id}) has a high average delay of {supplier.avg_delay_days:.1f} days and reliability score of {supplier.reliability_score * 100:.0f}%.",
                    is_resolved=False
                )
                db.add(new_alert)
                log_event(f"Threat Engine generated new alert: {prefix}", level="warning", source="system")
    
    # Auto-resolve supplier alerts
    for alert in unresolved_alerts:
        if alert.title.startswith("[MEDIUM] Supplier Disruption:"):
            try:
                sup_id = alert.title.split("(ID: ")[1].strip(")")
                if sup_id not in active_delay_supplier_ids:
                    alert.is_resolved = True
                    log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")
            except:
                pass

    # 3. Failed Workflows
    # Check RecoveryAttempts
    failed_attempts = db.query(models.RecoveryAttempt).filter(models.RecoveryAttempt.final_status == "failed").all()
    active_failed_actions = set()
    for attempt in failed_attempts:
        active_failed_actions.add(str(attempt.action_id))
        prefix = f"[CRITICAL] Operational Flow Failure: Action {attempt.action_id}"
        alert = get_alert_by_title_prefix(prefix)
        if not alert:
            new_alert = models.Alert(
                title=prefix,
                message=f"Action '{attempt.action_id}' has failed to execute. Recovery attempt was unsuccessful. Reason: {attempt.failure_reason}",
                is_resolved=False
            )
            db.add(new_alert)
            log_event(f"Threat Engine generated new alert: {prefix}", level="error", source="system")
            
    # Also check Workflows table
    failed_workflows = db.query(models.Workflow).filter(models.Workflow.status == "failed").all()
    active_failed_workflows = set()
    for wf in failed_workflows:
        active_failed_workflows.add(str(wf.id))
        prefix = f"[CRITICAL] Operational Flow Failure: Workflow {wf.id}"
        alert = get_alert_by_title_prefix(prefix)
        if not alert:
            new_alert = models.Alert(
                title=prefix,
                message=f"Workflow '{wf.name}' (ID: {wf.id}) has failed to execute completed actions.",
                is_resolved=False
            )
            db.add(new_alert)
            log_event(f"Threat Engine generated new alert: {prefix}", level="error", source="system")
            
    # Auto-resolve failed workflows/actions
    for alert in unresolved_alerts:
        if alert.title.startswith("[CRITICAL] Operational Flow Failure: Action"):
            try:
                action_id = alert.title.split("Action ")[1]
                if action_id not in active_failed_actions:
                    alert.is_resolved = True
                    log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")
            except:
                pass
        elif alert.title.startswith("[CRITICAL] Operational Flow Failure: Workflow"):
            try:
                wf_id = alert.title.split("Workflow ")[1]
                if wf_id not in active_failed_workflows:
                    alert.is_resolved = True
                    log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")
            except:
                pass

    # 4. Logistics Anomalies (Complaints)
    active_anomaly_skus = set()
    for item in inventory:
        if item.complaints >= 3:
            active_anomaly_skus.add(item.sku)
            prefix = f"[MEDIUM] Logistics Anomaly: {item.sku}"
            alert = get_alert_by_title_prefix(prefix)
            if not alert:
                new_alert = models.Alert(
                    title=prefix,
                    message=f"High rate of complaints ({item.complaints}) received for SKU {item.sku} ('{item.name}'). Potential logistics/transit quality issue.",
                    is_resolved=False
                )
                db.add(new_alert)
                log_event(f"Threat Engine generated new alert: {prefix}", level="warning", source="system")
    
    # Auto-resolve logistics anomalies
    for alert in unresolved_alerts:
        if alert.title.startswith("[MEDIUM] Logistics Anomaly:"):
            sku = alert.title.split(": ")[1]
            if sku not in active_anomaly_skus:
                alert.is_resolved = True
                log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")

    # 5. Demand Spikes
    active_spike_skus = set()
    for item in inventory:
        if item.sales_last_7_days >= 35 and item.quantity < (item.sales_last_7_days * 1.5):
            active_spike_skus.add(item.sku)
            prefix = f"[CRITICAL] Demand Surge Alert: {item.sku}"
            alert = get_alert_by_title_prefix(prefix)
            if not alert:
                new_alert = models.Alert(
                    title=prefix,
                    message=f"SKU {item.sku} ('{item.name}') has experienced a spike of {item.sales_last_7_days} sales in 7 days, leaving remaining stock vulnerable.",
                    is_resolved=False
                )
                db.add(new_alert)
                log_event(f"Threat Engine generated new alert: {prefix}", level="error", source="system")
                
    # Auto-resolve demand spikes
    for alert in unresolved_alerts:
        if alert.title.startswith("[CRITICAL] Demand Surge Alert:"):
            sku = alert.title.split(": ")[1]
            if sku not in active_spike_skus:
                alert.is_resolved = True
                log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")

    # 6. Inventory Inconsistencies (Contradictions)
    contradictions = db.query(models.Contradiction).filter(models.Contradiction.status == "open").all()
    active_contradiction_ids = set()
    for contra in contradictions:
        active_contradiction_ids.add(str(contra.id))
        prefix = f"[CRITICAL] Inventory Conflict: #{contra.id}"
        alert = get_alert_by_title_prefix(prefix)
        if not alert:
            desc_short = contra.description[:40] + "..." if len(contra.description) > 40 else contra.description
            new_alert = models.Alert(
                title=prefix,
                message=f"Conflict detected: {desc_short} (Sources: {contra.sources_involved}). Confidence: {contra.confidence_score * 100:.0f}%.",
                is_resolved=False
            )
            db.add(new_alert)
            log_event(f"Threat Engine generated new alert: {prefix}", level="error", source="system")
            
    # Auto-resolve contradictions
    for alert in unresolved_alerts:
        if alert.title.startswith("[CRITICAL] Inventory Conflict: #"):
            try:
                c_id = alert.title.split("#")[1]
                if c_id not in active_contradiction_ids:
                    alert.is_resolved = True
                    log_event(f"Threat Engine auto-resolved alert: {alert.title}", level="success", source="system")
            except:
                pass

    db.commit()
