from sqlalchemy.orm import Session
import models
from datetime import datetime, timedelta
from websocket.logger import log_event

class TemporalAnalyzer:
    def __init__(self, db: Session):
        self.db = db

    def store_metric(self, name: str, value: float):
        metric = models.TrendMetric(metric_name=name, value=value)
        self.db.add(metric)
        self.db.commit()

    def analyze_trend(self, metric_name: str, timeframe_hours: int = 48) -> dict:
        """
        Analyzes the trend of a given metric over the past X hours.
        """
        log_event(f"Initiating temporal trend analysis for metric '{metric_name}' over past {timeframe_hours}h...", level="info", source="analysis")
        
        cutoff_time = datetime.utcnow() - timedelta(hours=timeframe_hours)
        
        metrics = self.db.query(models.TrendMetric).filter(
            models.TrendMetric.metric_name == metric_name,
            models.TrendMetric.timestamp >= cutoff_time
        ).order_by(models.TrendMetric.timestamp.asc()).all()

        if not metrics:
            log_event("Temporal trend analysis: Insufficient metric data points compiled to compute gradient.", level="warning", source="analysis")
            return {"status": "insufficient_data", "message": "Not enough data for trend analysis."}

        values = [m.value for m in metrics]
        initial_value = values[0]
        latest_value = values[-1]
        
        if initial_value == 0:
            pct_change = 100.0 if latest_value > 0 else 0.0
        else:
            pct_change = ((latest_value - initial_value) / initial_value) * 100

        log_event(f"Temporal calculations: Computed initial value: {initial_value}, latest value: {latest_value}, change: {pct_change:.2f}%.", level="info", source="analysis")

        insight = ""
        level = "info"
        if pct_change > 100:
            insight = f"{metric_name} increased {pct_change:.1f}% in {timeframe_hours} hours. Anomaly detected."
            level = "warning"
        elif pct_change < -50:
            insight = f"{metric_name} dropped by {abs(pct_change):.1f}%. Depletion accelerating."
            level = "warning"
        else:
            insight = f"{metric_name} is stable (Change: {pct_change:.1f}%)."
            level = "success"

        log_event(f"Temporal Insight generated: '{insight}'", level=level, source="analysis")

        return {
            "status": "success",
            "metric": metric_name,
            "pct_change": pct_change,
            "insight": insight,
            "data_points": len(values)
        }
