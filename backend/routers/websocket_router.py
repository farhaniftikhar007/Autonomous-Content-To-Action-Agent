from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from websocket.logger import manager, log_event
import json

router = APIRouter()

@router.websocket("/ws/logs")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        # Emit a structured connection success log
        await manager.broadcast_log(
            message="Connection established: Monitoring System execution traces.",
            level="success",
            source="system"
        )
        
        while True:
            data = await websocket.receive_text()
            
            # Simple heartbeat ping/pong check to keep connection alive
            if data == "ping" or data.strip() == "":
                await websocket.send_text("pong")
                continue
                
            # Log client messages in the terminal for debug monitoring
            print(f"[WS Endpoint Received] Client payload: '{data}'")
            
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f"[WS Exception] Gracefully cleaning up websocket. Error: {e}")
        manager.disconnect(websocket)
