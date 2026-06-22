from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.dashboard_service import DashboardService
from app.services.nav_service import nav_items

router = APIRouter(tags=["dashboard"])


@router.get("/", response_class=HTMLResponse)
def dashboard(request: Request):
    from app.main import templates
    user = AuthService.get_session_user(request)
    if not user:
        return RedirectResponse(url="/login", status_code=302)
    
    stats = DashboardService.get_overview_stats()
    
    return templates.TemplateResponse(
        "dashboard/index.html",
        {
            "request": request,
            "nav": nav_items("dashboard", user.get("role", "user")),
            "page_title": "Dashboard",
            "current_user": user,
            "stats": stats,
        }
    )


@router.get("/health")
def health():
    return {"status": "ok", "service": "Enterprise Manager API"}
