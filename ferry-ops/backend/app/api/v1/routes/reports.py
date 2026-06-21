from fastapi import APIRouter
from app.db.database import get_connection

router = APIRouter(prefix="/api/reports", tags=["reports"])

@router.get("/capacity")
def capacity_report():
    conn = get_connection()
    cur = conn.cursor()
    rows = cur.execute("""
        SELECT
            r.id,
            r.route_name,
            r.capacity,
            COALESCE((SELECT SUM(seats) FROM bookings b WHERE b.route_id=r.id AND b.booking_status='confirmed'), 0) AS booked_seats
        FROM routes r
        ORDER BY r.id
    """).fetchall()
    conn.close()
    report = []
    for row in rows:
        report.append({
            "route_id": row["id"],
            "route_name": row["route_name"],
            "capacity": row["capacity"],
            "booked_seats": row["booked_seats"],
            "remaining_seats": row["capacity"] - row["booked_seats"]
        })
    return {"report": report}
