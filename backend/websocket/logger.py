from fastapi import WebSocket
import datetime
import asyncio

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        # Maintain a buffer history of the last 100 execution logs
        self.log_history: list[dict] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        print(f"[WS Connect] New client connected. Streaming historical buffer of {len(self.log_history)} logs...")
        
        # Immediately replay buffered historical execution logs to the newly connected client
        for log in self.log_history:
            try:
                await websocket.send_json(log)
            except Exception as e:
                print(f"[WS Replay Error] Failed to replay logs: {e}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            print(f"[WS Disconnect] Client removed. Active connections count: {len(self.active_connections)}")

    async def broadcast_log(self, message: str, level: str = "info", source: str = "system"):
        # Format structured JSON payload
        log_payload = {
            "timestamp": datetime.datetime.now().strftime("%H:%M:%S"),
            "level": level,    # info | warning | error | success
            "source": source,  # system | recovery | execution | analysis
            "message": message
        }

        # Push to history queue
        self.log_history.append(log_payload)
        if len(self.log_history) > 100:
            self.log_history.pop(0)

        # Always print debug logs to the backend terminal
        print(f"[WS Broadcast] [{source.upper()}] [{level.upper()}] {message}")

        # Broadcast to all active clients
        dead_connections = []
        for connection in self.active_connections:
            try:
                await connection.send_json(log_payload)
            except Exception:
                dead_connections.append(connection)

        # Clear dead connections gracefully
        for dead_conn in dead_connections:
            self.disconnect(dead_conn)

manager = ConnectionManager()

def log_event(message: str, level: str = "info", source: str = "system"):
    """
    Synchronous-safe logging function that will schedule the WebSocket broadcast
    on the running FastAPI/uvicorn event loop.
    """
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.create_task(manager.broadcast_log(message, level, source))
        else:
            # Fallback if loop is configured but not running yet
            loop.run_until_complete(manager.broadcast_log(message, level, source))
    except Exception as e:
        # Fallback print if event loop is not initialized
        print(f"[WS Logger Fallback] [{source.upper()}] [{level.upper()}] {message}")
