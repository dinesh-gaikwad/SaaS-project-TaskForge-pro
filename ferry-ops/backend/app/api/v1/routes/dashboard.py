from fastapi import APIRouter
from app.db.database import get_connection

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])

@router.get("/summary")
def summary():
    conn = get_connection()
    cur = conn.cursor()
    users = cur.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    routes = cur.execute("SELECT COUNT(*) FROM routes").fetchone()[0]
    bookings = cur.execute("SELECT COUNT(*) FROM bookings").fetchone()[0]
    alerts = cur.execute("SELECT COUNT(*) FROM alerts").fetchone()[0]
    confirmed = cur.execute("SELECT COALESCE(SUM(seats), 0) FROM bookings WHERE booking_status='confirmed'").fetchone()[0]
    conn.close()
    return {
        "users": users,
        "routes": routes,
        "bookings": bookings,
        "alerts": alerts,
        "confirmed_seats": confirmed
    }
