from pydantic import BaseModel

class CapacityRow(BaseModel):
    route_id: int
    route_name: str
    capacity: int
    booked_seats: int
    remaining_seats: int
