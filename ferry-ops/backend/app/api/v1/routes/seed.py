from fastapi import APIRouter
from app.db.database import get_connection

router = APIRouter(prefix="/api/seed", tags=["seed"])

@router.get("/more")
def seed_more():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO alerts(level, message) VALUES (?, ?)", ("Info", "New ferry schedule released for evening service."))
    cur.execute("INSERT INTO alerts(level, message) VALUES (?, ?)", ("Warning", "Peak hour crowd expected after 6 PM."))
    cur.execute("INSERT INTO bookings(passenger_name, route_id, seats, booking_status) VALUES (?, ?, ?, ?)", ("Demo User 1", 1, 3, "confirmed"))
    cur.execute("INSERT INTO bookings(passenger_name, route_id, seats, booking_status) VALUES (?, ?, ?, ?)", ("Demo User 2", 2, 2, "pending"))
    conn.commit()
    conn.close()
    return {"message": "Extra seed data inserted"}
