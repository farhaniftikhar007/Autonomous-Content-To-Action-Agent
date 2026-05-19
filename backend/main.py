import os
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import models
import schemas
from database import engine, get_db

from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from utils.errors import (
    validation_exception_handler,
    http_exception_handler,
    global_exception_handler,
    create_error_response
)
from sqlalchemy.exc import SQLAlchemyError
import json
import uuid
import time

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Enterprise Operations API")

# Register global exception handlers
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(Exception, global_exception_handler)

# Global Resilient Exception Middleware
@app.middleware("http")
async def error_handling_middleware(request: Request, call_next):
    trace_id = str(uuid.uuid4())
    try:
        request.state.trace_id = trace_id
        response = await call_next(request)
        return response
    except json.JSONDecodeError as exc:
        return create_error_response(
            error_code="MALFORMED_JSON",
            message="The request payload is not a valid JSON structure.",
            details=str(exc),
            status_code=400,
            trace_id=trace_id
        )
    except SQLAlchemyError as exc:
        return create_error_response(
            error_code="DATABASE_FAILURE",
            message="A database persistence transaction failed to commit.",
            details=str(exc),
            status_code=500,
            trace_id=trace_id
        )
    except TimeoutError as exc:
        return create_error_response(
            error_code="TIMEOUT_ERROR",
            message="The requested backend operation timed out.",
            details=str(exc),
            status_code=504,
            trace_id=trace_id
        )
    except Exception as exc:
        return create_error_response(
            error_code="UNEXPECTED_FAILURE",
            message="Core execution handler caught an unhandled request exception.",
            details=str(exc),
            status_code=500,
            trace_id=trace_id
        )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Welcome to Enterprise Operations API"}

@app.get("/inventory", response_model=list[schemas.InventoryItem])
def get_inventory(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    items = db.query(models.InventoryItem).offset(skip).limit(limit).all()
    return items

@app.post("/inventory", response_model=schemas.InventoryItem)
def create_inventory_item(item: schemas.InventoryItemCreate, db: Session = Depends(get_db)):
    db_item = models.InventoryItem(**item.dict())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.get("/alerts", response_model=list[schemas.Alert])
def get_alerts(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    from routers.threat_engine import sync_threats
    sync_threats(db)
    alerts = db.query(models.Alert).offset(skip).limit(limit).all()
    return alerts

@app.post("/alerts", response_model=schemas.Alert)
def create_alert(alert: schemas.AlertCreate, db: Session = Depends(get_db)):
    db_alert = models.Alert(**alert.dict())
    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)
    return db_alert

@app.get("/action_logs", response_model=list[schemas.ActionLog])
def get_action_logs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    logs = db.query(models.ActionLog).order_by(models.ActionLog.timestamp.desc()).offset(skip).limit(limit).all()
    return logs

# Import agent router
from routers import agent_router
app.include_router(agent_router.router, prefix="/agent", tags=["agent"])

# Import ingestion router
from routers import ingestion_router
app.include_router(ingestion_router.router, tags=["ingestion"])

# Import websocket router
from routers import websocket_router
app.include_router(websocket_router.router, tags=["websocket"])

# Import analytics router
from routers import analytics_router
app.include_router(analytics_router.router, prefix="/analytics", tags=["analytics"])
