from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
import datetime

class InventoryItem(Base):
    __tablename__ = "inventory_items"
    id = Column(Integer, primary_key=True, index=True)
    sku = Column(String, unique=True, index=True)
    name = Column(String)
    quantity = Column(Integer, default=0)
    reorder_level = Column(Integer, default=10)
    supplier_id = Column(Integer)
    sales_last_7_days = Column(Integer, default=0)
    complaints = Column(Integer, default=0)
    last_updated = Column(String, nullable=True)

class Supplier(Base):
    __tablename__ = "suppliers"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    reliability_score = Column(Float, default=1.0) # 0.0 to 1.0
    avg_delay_days = Column(Float, default=0.0)

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    message = Column(String)
    is_resolved = Column(Boolean, default=False, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class ActionLog(Base):
    __tablename__ = "action_logs"
    id = Column(Integer, primary_key=True, index=True)
    action_type = Column(String)
    description = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, index=True)

class Workflow(Base):
    __tablename__ = "workflows"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    status = Column(String, default="pending") # pending, running, completed, failed
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    tasks = relationship("TaskPlan", back_populates="workflow")

class TaskPlan(Base):
    __tablename__ = "task_plans"
    id = Column(Integer, primary_key=True, index=True)
    workflow_id = Column(Integer, ForeignKey("workflows.id"))
    description = Column(String)
    priority = Column(Integer, default=1)
    status = Column(String, default="pending") # pending, running, completed, failed
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    workflow = relationship("Workflow", back_populates="tasks")
    execution_state = relationship("ExecutionState", back_populates="task", uselist=False)
    action_chain = relationship("ActionChain", back_populates="task", uselist=False)

class ExecutionState(Base):
    __tablename__ = "execution_states"
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("task_plans.id"))
    current_step = Column(String)
    state_data = Column(String) # JSON string
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    task = relationship("TaskPlan", back_populates="execution_state")

class ActionChain(Base):
    __tablename__ = "action_chains"
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("task_plans.id"))
    actions_json = Column(String) # JSON string
    execution_status = Column(String, default="pending") # pending, running, completed, failed
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    task = relationship("TaskPlan", back_populates="action_chain")

class IngestedData(Base):
    __tablename__ = "ingested_data"
    id = Column(Integer, primary_key=True, index=True)
    source_type = Column(String, index=True) # pdf, csv, json, url, live
    source_name = Column(String)
    raw_content = Column(String)
    parsed_data = Column(String) # JSON format
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, index=True)

class TrendMetric(Base):
    __tablename__ = "trend_metrics"
    id = Column(Integer, primary_key=True, index=True)
    metric_name = Column(String, index=True)
    value = Column(Float)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, index=True)

class Contradiction(Base):
    __tablename__ = "contradictions"
    id = Column(Integer, primary_key=True, index=True)
    description = Column(String)
    sources_involved = Column(String) # JSON array of sources
    confidence_score = Column(Float, default=0.0)
    status = Column(String, default="open", index=True) # open, resolved
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class RecoveryAttempt(Base):
    __tablename__ = "recovery_attempts"
    id = Column(Integer, primary_key=True, index=True)
    action_id = Column(Integer)
    failure_reason = Column(String)
    retry_count = Column(Integer, default=0)
    fallback_triggered = Column(Boolean, default=False)
    rollback_triggered = Column(Boolean, default=False)
    final_status = Column(String) # recovered, failed, rolled_back
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

class OperationalAnalytic(Base):
    __tablename__ = "operational_analytics"
    id = Column(Integer, primary_key=True, index=True)
    action_chain_id = Column(Integer)
    before_state = Column(String)
    after_state = Column(String)
    latency_ms = Column(Integer)
    operational_cost = Column(Float, default=0.0)
    risk_reduction_score = Column(Float, default=0.0)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
