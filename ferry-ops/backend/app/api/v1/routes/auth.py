from fastapi import APIRouter, HTTPException
from app.db.database import get_connection
from app.schemas.auth import LoginRequest, RegisterRequest

router = APIRouter(prefix="/api/auth", tags=["auth"])

def fake_token(user_id: int, role: str):
    return f"token-{user_id}-{role}"

@router.post("/register")
def register(payload: RegisterRequest):
    conn = get_connection()
    cur = conn.cursor()
    exists = cur.execute("SELECT id FROM users WHERE email=?", (payload.email,)).fetchone()
    if exists:
        conn.close()
        raise HTTPException(status_code=400, detail="Email already registered")
    cur.execute("INSERT INTO users(name, email, role) VALUES (?, ?, ?)", (payload.name, payload.email, payload.role))
    user_id = cur.lastrowid
    conn.commit()
    conn.close()
    return {"message": "User registered successfully", "access_token": fake_token(user_id, payload.role), "token_type": "bearer"}

@router.post("/login")
def login(payload: LoginRequest):
    conn = get_connection()
    cur = conn.cursor()
    user = cur.execute("SELECT id, name, email, role FROM users WHERE email=?", (payload.email,)).fetchone()
    conn.close()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {"message": "Login successful", "access_token": fake_token(user["id"], user["role"]), "token_type": "bearer", "user": dict(user)}
