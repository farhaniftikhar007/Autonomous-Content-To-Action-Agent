from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import datetime
import uuid
import traceback

# Structured Error Response Generator
def create_error_response(
    error_code: str,
    message: str,
    details: str = None,
    status_code: int = 500,
    trace_id: str = None
) -> JSONResponse:
    payload = {
        "success": False,
        "error_code": error_code,
        "message": message,
        "details": details or "",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "trace_id": trace_id or str(uuid.uuid4())
    }
    
    # Print structured trace to backend console
    print(f"[ERROR TRACE] [{payload['trace_id']}] Code: {error_code} | Msg: {message} | Details: {details}")
    return JSONResponse(status_code=status_code, content=payload)

# Exception Handlers
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    details = str(exc.errors())
    return create_error_response(
        error_code="VALIDATION_ERROR",
        message="Request payload validation failed.",
        details=details,
        status_code=422
    )

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return create_error_response(
        error_code=f"HTTP_EXCEPTION_{exc.status_code}",
        message=exc.detail,
        details=f"Starlette HTTP exception raised.",
        status_code=exc.status_code
    )

async def global_exception_handler(request: Request, exc: Exception):
    trace_id = str(uuid.uuid4())
    tb_str = "".join(traceback.format_exception(type(exc), exc, exc.__traceback__))
    
    # Critical error log (prevents crashes from unhandled async exceptions)
    print(f"[FATAL EXCEPTION] Trace ID: {trace_id}\n{tb_str}")
    
    return create_error_response(
        error_code="INTERNAL_SERVER_ERROR",
        message="An unexpected system failure occurred in our core runtime.",
        details=str(exc),
        status_code=500,
        trace_id=trace_id
    )
