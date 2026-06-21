from app.db.database import get_connection

def available_seats(route_id: int) -> int:
    conn = get_connection()
    cur = conn.cursor()
    route = cur.execute("SELECT capacity FROM routes WHERE id=?", (route_id,)).fetchone()
    if not route:
        conn.close()
        return 0
    booked = cur.execute("""
        SELECT COALESCE(SUM(seats), 0)
        FROM bookings
        WHERE route_id=? AND booking_status='confirmed'
    """, (route_id,)).fetchone()[0]
    conn.close()
    return route["capacity"] - booked
