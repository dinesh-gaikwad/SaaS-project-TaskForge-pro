from pydantic import BaseModel
from typing import Optional

class AlertCreate(BaseModel):
    level: str = "Info"
    message: str

class AlertRead(BaseModel):
    id: int
    level: str
    message: str
    created_at: Optional[str] = None
