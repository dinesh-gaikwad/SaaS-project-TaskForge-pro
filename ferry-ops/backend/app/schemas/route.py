from pydantic import BaseModel
from typing import Optional

class RouteCreate(BaseModel):
    route_name: str
    origin: str
    destination: str
    departure_time: str
    capacity: int
    status: str = "scheduled"

class RouteRead(BaseModel):
    id: int
    route_name: str
    origin: str
    destination: str
    departure_time: str
    capacity: int
    status: str
    booked_seats: Optional[int] = 0
