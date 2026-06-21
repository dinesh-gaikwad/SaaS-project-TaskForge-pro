from pydantic import BaseModel, EmailStr
from typing import Optional

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    role: str = "citizen"

class UserRead(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str
    created_at: Optional[str] = None
