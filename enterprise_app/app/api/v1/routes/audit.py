from fastapi import APIRouter, Request, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.audit_service import get_audit_logs
from app.services.nav_service import nav_items

router = APIRouter(tags=["audit"])


def _check_auth(request: Request):
    from fastapi import HTTPException
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    return user


@router.get("/audit", response_class=HTMLResponse)
def audit_logs(
    request: Request,
    page: int = Query(1, ge=1),
    module: str = Query(""),
    action: str = Query(""),
    date_from: str = Query(""),
    date_to: str = Query(""),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    if current_user.get("role") != "admin":
        return RedirectResponse(url="/", status_code=302)
    
    data = get_audit_logs(
        page=page, per_page=20,
        module=module, action=action,
        date_from=date_from, date_to=date_to
    )
    
    return templates.TemplateResponse("audit/index.html", {
        "request": request,
        "nav": nav_items("audit", current_user.get("role")),
        "page_title": "Audit Logs",
        "current_user": current_user,
        "data": data,
        "filters": {"module": module, "action": action, "date_from": date_from, "date_to": date_to},
    })
