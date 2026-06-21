from fastapi import APIRouter, HTTPException
from app.db.database import get_connection
from app.schemas.booking import BookingCreate
from app.services.booking_service import available_seats

router = APIRouter(prefix="/api/bookings", tags=["bookings"])

@router.get("")
def list_bookings():
    conn = get_connection()
    cur = conn.cursor()
    rows = cur.execute("SELECT * FROM bookings ORDER BY id DESC").fetchall()
    conn.close()
    return {"bookings": [dict(r) for r in rows]}

@router.post("")
def create_booking(payload: BookingCreate):
    if not payload.passenger_name.strip():
        raise HTTPException(status_code=400, detail="Passenger name required")
    if payload.seats < 1:
        raise HTTPException(status_code=400, detail="Seats must be >= 1")

    remaining = available_seats(payload.route_id)
    if payload.booking_status == "confirmed" and payload.seats > remaining:
        raise HTTPException(status_code=400, detail=f"Overbooking blocked. Remaining seats: {remaining}")

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO bookings(passenger_name, route_id, seats, booking_status)
        VALUES (?, ?, ?, ?)
    """, (payload.passenger_name, payload.route_id, payload.seats, payload.booking_status))
    conn.commit()
    conn.close()
    return {"message": "Booking created successfully"}
