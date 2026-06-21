from fastapi import APIRouter, HTTPException
from app.db.database import get_connection
from app.schemas.user import UserCreate

router = APIRouter(prefix="/api/users", tags=["users"])

@router.get("")
def list_users():
    conn = get_connection()
    cur = conn.cursor()
    rows = cur.execute("SELECT id, name, email, role, created_at FROM users ORDER BY id DESC").fetchall()
    conn.close()
    return {"users": [dict(r) for r in rows]}

@router.get("/{user_id}")
def get_user(user_id: int):
    conn = get_connection()
    cur = conn.cursor()
    row = cur.execute("SELECT id, name, email, role, created_at FROM users WHERE id=?", (user_id,)).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="User not found")
    return dict(row)

@router.put("/{user_id}")
def update_user(user_id: int, payload: UserCreate):
    conn = get_connection()
    cur = conn.cursor()
    row = cur.execute("SELECT id FROM users WHERE id=?", (user_id,)).fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
    cur.execute(
        "UPDATE users SET name=?, email=?, role=? WHERE id=?",
        (payload.name, payload.email, payload.role, user_id)
    )
    conn.commit()
    conn.close()
    return {"message": "User updated successfully"}

@router.delete("/{user_id}")
def delete_user(user_id: int):
    conn = get_connection()
    cur = conn.cursor()
    row = cur.execute("SELECT id FROM users WHERE id=?", (user_id,)).fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")
    cur.execute("DELETE FROM users WHERE id=?", (user_id,))
    conn.commit()
    conn.close()
    return {"message": "User deleted successfully"}
