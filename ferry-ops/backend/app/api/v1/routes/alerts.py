from fastapi import APIRouter, HTTPException
from app.db.database import get_connection
from app.schemas.alert import AlertCreate

router = APIRouter(prefix="/api/alerts", tags=["alerts"])

@router.get("")
def list_alerts():
    conn = get_connection()
    cur = conn.cursor()
    rows = cur.execute("SELECT * FROM alerts ORDER BY id DESC").fetchall()
    conn.close()
    return {"alerts": [dict(r) for r in rows]}

@router.post("")
def create_alert(payload: AlertCreate):
    if not payload.message.strip():
        raise HTTPException(status_code=400, detail="Alert message required")

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO alerts(level, message) VALUES (?, ?)", (payload.level, payload.message))
    conn.commit()
    conn.close()
    return {"message": "Alert created successfully"}
