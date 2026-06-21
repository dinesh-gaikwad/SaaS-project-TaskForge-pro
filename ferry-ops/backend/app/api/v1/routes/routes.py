from fastapi import APIRouter, HTTPException
from app.db.database import get_connection
from app.schemas.route import RouteCreate
from app.services.booking_service import available_seats

router = APIRouter(prefix="/api/routes", tags=["routes"])

@router.get("")
def list_routes():
    conn = get_connection()
    cur = conn.cursor()
    rows = cur.execute("""
        SELECT
            r.*,
            COALESCE((SELECT SUM(seats) FROM bookings b WHERE b.route_id=r.id AND b.booking_status='confirmed'), 0) AS booked_seats
        FROM routes r
        ORDER BY r.id
    """).fetchall()
    conn.close()
    return {"routes": [dict(r) for r in rows]}

@router.get("/{route_id}")
def get_route(route_id: int):
    conn = get_connection()
    cur = conn.cursor()
    row = cur.execute("""
        SELECT
            r.*,
            COALESCE((SELECT SUM(seats) FROM bookings b WHERE b.route_id=r.id AND b.booking_status='confirmed'), 0) AS booked_seats
        FROM routes r
        WHERE r.id=?
    """, (route_id,)).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Route not found")
    return dict(row)

@router.post("")
def create_route(payload: RouteCreate):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO routes(route_name, origin, destination, departure_time, capacity, status)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (payload.route_name, payload.origin, payload.destination, payload.departure_time, payload.capacity, payload.status))
    conn.commit()
    conn.close()
    return {"message": "Route created successfully"}

@router.get("/{route_id}/availability")
def route_availability(route_id: int):
    seats = available_seats(route_id)
    return {"route_id": route_id, "remaining_seats": seats}
