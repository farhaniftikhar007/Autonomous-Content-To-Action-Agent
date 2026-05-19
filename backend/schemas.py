from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class InventoryItemBase(BaseModel):
    sku: str
    name: str
    quantity: int
    reorder_level: int
    supplier_id: int
    sales_last_7_days: Optional[int] = 0
    complaints: Optional[int] = 0
    last_updated: Optional[str] = None

class InventoryItemCreate(InventoryItemBase):
    pass

class InventoryItem(InventoryItemBase):
    id: int

    class Config:
        from_attributes = True

class SupplierBase(BaseModel):
    name: str
    reliability_score: float
    avg_delay_days: float

class SupplierCreate(SupplierBase):
    pass

class Supplier(SupplierBase):
    id: int

    class Config:
        from_attributes = True

class AlertBase(BaseModel):
    title: str
    message: str

class AlertCreate(AlertBase):
    pass

class Alert(AlertBase):
    id: int
    is_resolved: bool
    created_at: datetime

    class Config:
        from_attributes = True

class ActionLogBase(BaseModel):
    action_type: str
    description: str

class ActionLogCreate(ActionLogBase):
    pass

class ActionLog(ActionLogBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class ExecutionStateBase(BaseModel):
    current_step: str
    state_data: str

class ExecutionStateCreate(ExecutionStateBase):
    task_id: int

class ExecutionState(ExecutionStateBase):
    id: int
    task_id: int
    updated_at: datetime

    class Config:
        from_attributes = True

class ActionChainBase(BaseModel):
    actions_json: str
    execution_status: str = "pending"

class ActionChainCreate(ActionChainBase):
    task_id: int

class ActionChain(ActionChainBase):
    id: int
    task_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class TaskPlanBase(BaseModel):
    description: str
    priority: int = 1
    status: str = "pending"

class TaskPlanCreate(TaskPlanBase):
    workflow_id: int

class TaskPlan(TaskPlanBase):
    id: int
    workflow_id: int
    created_at: datetime
    execution_state: Optional[ExecutionState] = None
    action_chain: Optional[ActionChain] = None

    class Config:
        from_attributes = True

class WorkflowBase(BaseModel):
    name: str
    status: str = "pending"

class WorkflowCreate(WorkflowBase):
    pass

class Workflow(WorkflowBase):
    id: int
    created_at: datetime
    updated_at: datetime
    tasks: List[TaskPlan] = []

    class Config:
        from_attributes = True

class IngestedDataBase(BaseModel):
    source_type: str
    source_name: str
    raw_content: str
    parsed_data: str

class IngestedDataCreate(IngestedDataBase):
    pass

class IngestedData(IngestedDataBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class TrendMetricBase(BaseModel):
    metric_name: str
    value: float

class TrendMetricCreate(TrendMetricBase):
    pass

class TrendMetric(TrendMetricBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class ContradictionBase(BaseModel):
    description: str
    sources_involved: str
    confidence_score: float
    status: str = "open"

class ContradictionCreate(ContradictionBase):
    pass

class Contradiction(ContradictionBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class RecoveryAttemptBase(BaseModel):
    action_id: int
    failure_reason: str
    retry_count: int = 0
    fallback_triggered: bool = False
    rollback_triggered: bool = False
    final_status: str

class RecoveryAttemptCreate(RecoveryAttemptBase):
    pass

class RecoveryAttempt(RecoveryAttemptBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True

class OperationalAnalyticBase(BaseModel):
    action_chain_id: int
    before_state: str
    after_state: str
    latency_ms: int
    operational_cost: float = 0.0
    risk_reduction_score: float = 0.0

class OperationalAnalyticCreate(OperationalAnalyticBase):
    pass

class OperationalAnalytic(OperationalAnalyticBase):
    id: int
    timestamp: datetime

    class Config:
        from_attributes = True
