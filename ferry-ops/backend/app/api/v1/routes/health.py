from fastapi import APIRouter
from app.db.database import get_connection

router = APIRouter(prefix="/api", tags=["health"])

@router.get("/health")
def health():
    conn = get_connection()
    conn.execute("SELECT 1")
    conn.close()
    return {"status": "ok", "service": "ferry-ops"}
