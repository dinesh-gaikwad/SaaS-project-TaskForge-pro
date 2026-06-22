from pydantic import BaseModel
from typing import Optional


class DepartmentCreate(BaseModel):
    name: str
    code: Optional[str] = None
    description: Optional[str] = None
    head_user_id: Optional[int] = None
    budget: Optional[float] = 0.0
    location: Optional[str] = None
    status: str = "active"


class DepartmentUpdate(DepartmentCreate):
    pass


class DepartmentRead(BaseModel):
    id: int
    name: str
    code: Optional[str]
    description: Optional[str]
    budget: Optional[float]
    location: Optional[str]
    status: str
    user_count: Optional[int] = 0
    created_at: Optional[str]
