from fastapi import APIRouter, Request, Query, Response
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.department_service import DepartmentService
from app.services.nav_service import nav_items

router = APIRouter(tags=["reports"])


def _check_auth(request: Request):
    from fastapi import HTTPException
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    return user


@router.get("/reports", response_class=HTMLResponse)
def reports_index(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    
    user_stats = UserService.get_stats()
    dept_stats = DepartmentService.get_stats()
    
    return templates.TemplateResponse("reports/index.html", {
        "request": request,
        "nav": nav_items("reports", current_user.get("role")),
        "page_title": "Reports",
        "current_user": current_user,
        "user_stats": user_stats,
        "dept_stats": dept_stats,
    })


@router.get("/reports/users/export")
def export_users(request: Request):
    current_user = _check_auth(request)
    csv_data = UserService.export_csv()
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users_report.csv"}
    )
