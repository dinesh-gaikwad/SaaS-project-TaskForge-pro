from fastapi import APIRouter, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.db.database import get_connection
from app.services.nav_service import nav_items

router = APIRouter(tags=["settings"])


def _check_auth_admin(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    if user.get("role") != "admin":
        raise HTTPException(403, detail="Admin only")
    return user


@router.get("/settings", response_class=HTMLResponse)
def settings_page(request: Request):
    from app.main import templates
    current_user = _check_auth_admin(request)
    
    conn = get_connection()
    raw_settings = conn.execute("SELECT * FROM app_settings ORDER BY group_name, key").fetchall()
    conn.close()
    
    grouped = {}
    for s in raw_settings:
        s = dict(s)
        g = s["group_name"] or "general"
        grouped.setdefault(g, []).append(s)
    
    return templates.TemplateResponse("settings/index.html", {
        "request": request,
        "nav": nav_items("settings", current_user.get("role")),
        "page_title": "Settings",
        "current_user": current_user,
        "grouped_settings": grouped,
        "success": request.query_params.get("success", ""),
    })


@router.post("/settings/update")
async def update_settings(request: Request):
    current_user = _check_auth_admin(request)
    form = await request.form()
    
    conn = get_connection()
    cur = conn.cursor()
    
    for key, value in form.items():
        cur.execute(
            "UPDATE app_settings SET value = ? WHERE key = ?",
            (str(value), key)
        )
    
    conn.commit()
    conn.close()
    
    return RedirectResponse(url="/settings?success=1", status_code=303)
