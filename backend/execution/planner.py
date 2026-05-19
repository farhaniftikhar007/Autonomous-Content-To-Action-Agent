from sqlalchemy.orm import Session
import models

class WorkflowPlanner:
    def __init__(self, db: Session):
        self.db = db

    def create_workflow(self, name: str) -> models.Workflow:
        workflow = models.Workflow(name=name, status="pending")
        self.db.add(workflow)
        self.db.commit()
        self.db.refresh(workflow)
        return workflow

    def create_task(self, workflow_id: int, description: str, priority: int = 1) -> models.TaskPlan:
        task = models.TaskPlan(workflow_id=workflow_id, description=description, priority=priority, status="pending")
        self.db.add(task)
        self.db.commit()
        self.db.refresh(task)
        return task

    def get_pending_tasks(self, workflow_id: int):
        return self.db.query(models.TaskPlan).filter(
            models.TaskPlan.workflow_id == workflow_id,
            models.TaskPlan.status == "pending"
        ).order_by(models.TaskPlan.priority.desc()).all()

    def update_task_status(self, task_id: int, status: str):
        task = self.db.query(models.TaskPlan).filter(models.TaskPlan.id == task_id).first()
        if task:
            task.status = status
            self.db.commit()

    def update_workflow_status(self, workflow_id: int, status: str):
        workflow = self.db.query(models.Workflow).filter(models.Workflow.id == workflow_id).first()
        if workflow:
            workflow.status = status
            self.db.commit()
