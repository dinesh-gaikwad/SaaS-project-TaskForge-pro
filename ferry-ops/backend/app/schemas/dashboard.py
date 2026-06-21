from pydantic import BaseModel

class DashboardSummary(BaseModel):
    users: int
    routes: int
    bookings: int
    alerts: int
    confirmed_seats: int
