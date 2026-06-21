from pydantic import BaseModel
from typing import Optional

class BookingCreate(BaseModel):
    passenger_name: str
    route_id: int
    seats: int = 1
    booking_status: str = "confirmed"

class BookingRead(BaseModel):
    id: int
    passenger_name: str
    route_id: int
    seats: int
    booking_status: str
    created_at: Optional[str] = None
