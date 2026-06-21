from app.db.database import get_connection

def init_db():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL DEFAULT 'citizen',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS ferries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        current_route_id INTEGER,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_name TEXT NOT NULL,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        departure_time TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'scheduled'
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        passenger_name TEXT NOT NULL,
        route_id INTEGER NOT NULL,
        seats INTEGER NOT NULL,
        booking_status TEXT NOT NULL DEFAULT 'confirmed',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cur.executemany(
        "INSERT OR IGNORE INTO ferries(id, name, capacity, status, current_route_id) VALUES (?, ?, ?, ?, ?)",
        [
            (1, "Island Star", 180, "active", 1),
            (2, "Harbour Queen", 120, "active", 2),
            (3, "Bay Runner", 90, "maintenance", 3)
        ]
    )

    cur.executemany(
        "INSERT OR IGNORE INTO routes(id, route_name, origin, destination, departure_time, capacity, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
            (1, "Toronto Island Loop", "Main Terminal", "Toronto Island", "08:00", 180, "on-time"),
            (2, "Harbour Express", "East Terminal", "Harbourfront", "08:30", 120, "delayed"),
            (3, "Weekend Scenic", "West Terminal", "Island Park", "09:15", 90, "scheduled")
        ]
    )

    cur.executemany(
        "INSERT OR IGNORE INTO alerts(id, level, message) VALUES (?, ?, ?)",
        [
            (1, "Info", "Service operating normally on Route 1."),
            (2, "Warning", "Route 2 delayed by 15 minutes due to weather.")
        ]
    )

    conn.commit()
    conn.close()
