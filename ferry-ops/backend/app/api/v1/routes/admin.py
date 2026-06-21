from fastapi import APIRouter, Depends
from app.api.deps import require_admin
from app.db.database import get_connection

router = APIRouter(prefix="/api/admin", tags=["admin"])

@router.get("/dashboard")
def dashboard(current=Depends(require_admin)):
    conn = get_connection()
    cur = conn.cursor()
    users = cur.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    routes = cur.execute("SELECT COUNT(*) FROM routes").fetchone()[0]
    bookings = cur.execute("SELECT COUNT(*) FROM bookings").fetchone()[0]
    alerts = cur.execute("SELECT COUNT(*) FROM alerts").fetchone()[0]
    conn.close()
    return {
        "users": users,
        "routes": routes,
        "bookings": bookings,
        "alerts": alerts
    }
