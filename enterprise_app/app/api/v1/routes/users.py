from fastapi import APIRouter, Request, Form, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse, Response
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.department_service import DepartmentService
from app.services.nav_service import nav_items, get_breadcrumb

router = APIRouter(tags=["users"])


def _check_auth(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(status_code=302, headers={"Location": "/login"})
    return user


@router.get("/users", response_class=HTMLResponse)
def users_list(
    request: Request,
    page: int = Query(1, ge=1),
    search: str = Query(""),
    role: str = Query(""),
    department: str = Query(""),
    status: str = Query(""),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    data = UserService.get_all(
        page=page, per_page=10, search=search,
        role=role, department=department, status=status
    )
    depts = DepartmentService.get_all_simple()
    
    return templates.TemplateResponse("users/index.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", None)),
        "page_title": "Users",
        "current_user": current_user,
        "data": data,
        "depts": depts,
        "filters": {"search": search, "role": role, "department": department, "status": status},
    })


@router.get("/users/new", response_class=HTMLResponse)
def create_user_page(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    depts = DepartmentService.get_all_simple()
    
    return templates.TemplateResponse("users/form.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", "/users"), ("New User", None)),
        "page_title": "Create User",
        "current_user": current_user,
        "user": None,
        "depts": depts,
        "error": None,
    })


@router.post("/users/create")
async def create_user(
    request: Request,
    full_name: str = Form(...),
    email: str = Form(...),
    role: str = Form("user"),
    department: str = Form(""),
    department_id: str = Form(""),
    phone: str = Form(""),
    status: str = Form("active"),
    password: str = Form("changeme123"),
):
    from app.main import templates
    current_user = _check_auth(request)
    depts = DepartmentService.get_all_simple()
    
    try:
        user_id = UserService.create({
            "full_name": full_name,
            "email": email,
            "role": role,
            "department": department,
            "department_id": int(department_id) if department_id else None,
            "phone": phone,
            "status": status,
            "password": password,
        }, created_by=current_user["id"])
        return RedirectResponse(url=f"/users/{user_id}?success=created", status_code=303)
    except ValueError as e:
        return templates.TemplateResponse("users/form.html", {
            "request": request,
            "nav": nav_items("users", current_user.get("role")),
            "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", "/users"), ("New User", None)),
            "page_title": "Create User",
            "current_user": current_user,
            "user": {"full_name": full_name, "email": email, "role": role,
                     "department": department, "phone": phone, "status": status},
            "depts": depts,
            "error": str(e),
        }, status_code=400)


@router.get("/users/{user_id}", response_class=HTMLResponse)
def user_detail(request: Request, user_id: int, success: str = ""):
    from app.main import templates
    current_user = _check_auth(request)
    
    user = UserService.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return templates.TemplateResponse("users/detail.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", "/users"), (user["full_name"], None)),
        "page_title": user["full_name"],
        "current_user": current_user,
        "user": user,
        "success": success,
    })


@router.get("/users/{user_id}/edit", response_class=HTMLResponse)
def edit_user_page(request: Request, user_id: int):
    from app.main import templates
    current_user = _check_auth(request)
    
    user = UserService.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    depts = DepartmentService.get_all_simple()
    
    return templates.TemplateResponse("users/form.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(
            ("Home", "/"), ("Users", "/users"),
            (user["full_name"], f"/users/{user_id}"), ("Edit", None)
        ),
        "page_title": f"Edit – {user['full_name']}",
        "current_user": current_user,
        "user": user,
        "depts": depts,
        "error": None,
    })


@router.post("/users/{user_id}/update")
async def update_user(
    request: Request,
    user_id: int,
    full_name: str = Form(...),
    email: str = Form(...),
    role: str = Form("user"),
    department: str = Form(""),
    department_id: str = Form(""),
    phone: str = Form(""),
    status: str = Form("active"),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    try:
        UserService.update(user_id, {
            "full_name": full_name,
            "email": email,
            "role": role,
            "department": department,
            "department_id": int(department_id) if department_id else None,
            "phone": phone,
            "status": status,
        }, updated_by=current_user["id"])
        return RedirectResponse(url=f"/users/{user_id}?success=updated", status_code=303)
    except ValueError as e:
        user = UserService.get_by_id(user_id)
        depts = DepartmentService.get_all_simple()
        return templates.TemplateResponse("users/form.html", {
            "request": request,
            "nav": nav_items("users", current_user.get("role")),
            "page_title": "Edit User",
            "current_user": current_user,
            "user": user,
            "depts": depts,
            "error": str(e),
        }, status_code=400)


@router.post("/users/{user_id}/delete")
def delete_user(request: Request, user_id: int):
    current_user = _check_auth(request)
    
    try:
        UserService.delete(user_id, deleted_by=current_user["id"])
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    return RedirectResponse(url="/users?success=deleted", status_code=303)


@router.post("/users/{user_id}/toggle-status")
def toggle_user_status(request: Request, user_id: int):
    current_user = _check_auth(request)
    new_status = UserService.toggle_status(user_id, actor_id=current_user["id"])
    return RedirectResponse(url=f"/users/{user_id}", status_code=303)


@router.get("/users/export/csv")
def export_users_csv(request: Request):
    current_user = _check_auth(request)
    csv_data = UserService.export_csv()
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users.csv"}
    )
