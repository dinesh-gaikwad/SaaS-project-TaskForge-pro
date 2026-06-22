from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: Optional[str] = "changeme123"
    role: str = "user"
    department: Optional[str] = None
    department_id: Optional[int] = None
    phone: Optional[str] = None
    status: str = "active"


class UserUpdate(BaseModel):
    full_name: str
    email: EmailStr
    role: str
    department: Optional[str] = None
    department_id: Optional[int] = None
    phone: Optional[str] = None
    status: str = "active"


class UserRead(BaseModel):
    id: int
    full_name: str
    email: str
    role: str
    department: Optional[str] = None
    phone: Optional[str] = None
    status: str
    last_login: Optional[str] = None
    created_at: Optional[str] = None


class UserList(BaseModel):
    items: list
    total: int
    page: int
    per_page: int
    total_pages: int
    has_prev: bool
    has_next: bool


class PasswordChange(BaseModel):
    current_password: str
    new_password: str
    confirm_password: str
