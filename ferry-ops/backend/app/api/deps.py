from fastapi import Header, HTTPException

def get_current_role(authorization: str = Header(default="")):
    if not authorization.startswith("Bearer token-"):
        raise HTTPException(status_code=401, detail="Unauthorized")
    parts = authorization.replace("Bearer ", "").split("-")
    if len(parts) < 3:
        raise HTTPException(status_code=401, detail="Invalid token")
    return {"user_id": int(parts[1]), "role": parts[2]}

def require_admin(authorization: str = Header(default="")):
    user = get_current_role(authorization)
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    return user
