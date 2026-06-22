from fastapi import APIRouter, Request, Form, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.db.database import get_connection
from app.services.nav_service import nav_items
from datetime import datetime

router = APIRouter(tags=["roles"])


def _check_auth(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    if user.get("role") != "admin":
        raise HTTPException(403, detail="Admin only")
    return user


@router.get("/roles", response_class=HTMLResponse)
def roles_list(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    
    conn = get_connection()
    roles = conn.execute("""
        SELECT r.*, COUNT(u.id) as user_count
        FROM roles r
        LEFT JOIN users u ON u.role = r.name
        GROUP BY r.id
        ORDER BY r.id
    """).fetchall()
    conn.close()
    
    return templates.TemplateResponse("roles/index.html", {
        "request": request,
        "nav": nav_items("roles", current_user.get("role")),
        "page_title": "Roles & Permissions",
        "current_user": current_user,
        "roles": [dict(r) for r in roles],
    })


@router.get("/roles/new", response_class=HTMLResponse)
def new_role_page(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    
    return templates.TemplateResponse("roles/form.html", {
        "request": request,
        "nav": nav_items("roles", current_user.get("role")),
        "page_title": "New Role",
        "current_user": current_user,
        "role": None,
        "error": None,
    })


@router.post("/roles/create")
async def create_role(
    request: Request,
    name: str = Form(...),
    display_name: str = Form(...),
    description: str = Form(""),
    status: str = Form("active"),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    conn = get_connection()
    cur = conn.cursor()
    
    exists = cur.execute("SELECT id FROM roles WHERE name = ?", (name,)).fetchone()
    if exists:
        conn.close()
        return templates.TemplateResponse("roles/form.html", {
            "request": request,
            "nav": nav_items("roles", current_user.get("role")),
            "page_title": "New Role",
            "current_user": current_user,
            "role": {"name": name, "display_name": display_name, "description": description},
            "error": f"Role '{name}' already exists",
        }, status_code=400)
    
    now = datetime.utcnow().isoformat()
    cur.execute("""
        INSERT INTO roles (name, display_name, description, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (name, display_name, description, status, now, now))
    
    conn.commit()
    conn.close()
    
    return RedirectResponse(url="/roles", status_code=303)


@router.post("/roles/{role_id}/delete")
def delete_role(request: Request, role_id: int):
    current_user = _check_auth(request)
    
    conn = get_connection()
    cur = conn.cursor()
    
    role = cur.execute("SELECT * FROM roles WHERE id = ?", (role_id,)).fetchone()
    if not role:
        conn.close()
        raise HTTPException(404, detail="Role not found")
    
    if dict(role)["is_system"]:
        conn.close()
        raise HTTPException(400, detail="Cannot delete system roles")
    
    cur.execute("DELETE FROM roles WHERE id = ?", (role_id,))
    conn.commit()
    conn.close()
    
    return RedirectResponse(url="/roles", status_code=303)
