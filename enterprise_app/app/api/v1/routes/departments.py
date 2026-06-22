from fastapi import APIRouter, Request, Form, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.department_service import DepartmentService
from app.services.user_service import UserService
from app.services.nav_service import nav_items, get_breadcrumb

router = APIRouter(tags=["departments"])


def _check_auth(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(status_code=302, headers={"Location": "/login"})
    return user


@router.get("/departments", response_class=HTMLResponse)
def departments_list(
    request: Request,
    page: int = Query(1, ge=1),
    search: str = Query(""),
    status: str = Query(""),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    data = DepartmentService.get_all(page=page, per_page=10, search=search, status=status)
    
    return templates.TemplateResponse("departments/index.html", {
        "request": request,
        "nav": nav_items("departments", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Departments", None)),
        "page_title": "Departments",
        "current_user": current_user,
        "data": data,
        "filters": {"search": search, "status": status},
    })


@router.get("/departments/new", response_class=HTMLResponse)
def new_dept_page(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    managers = UserService.get_all(per_page=200, role="manager")
    
    return templates.TemplateResponse("departments/form.html", {
        "request": request,
        "nav": nav_items("departments", current_user.get("role")),
        "page_title": "New Department",
        "current_user": current_user,
        "dept": None,
        "managers": managers["items"],
        "error": None,
    })


@router.post("/departments/create")
async def create_dept(
    request: Request,
    name: str = Form(...),
    code: str = Form(""),
    description: str = Form(""),
    head_user_id: str = Form(""),
    budget: str = Form("0"),
    location: str = Form(""),
    status: str = Form("active"),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    try:
        dept_id = DepartmentService.create({
            "name": name,
            "code": code,
            "description": description,
            "head_user_id": int(head_user_id) if head_user_id else None,
            "budget": float(budget) if budget else 0.0,
            "location": location,
            "status": status,
        }, created_by=current_user["id"])
        return RedirectResponse(url=f"/departments/{dept_id}", status_code=303)
    except ValueError as e:
        managers = UserService.get_all(per_page=200, role="manager")
        return templates.TemplateResponse("departments/form.html", {
            "request": request,
            "nav": nav_items("departments", current_user.get("role")),
            "page_title": "New Department",
            "current_user": current_user,
            "dept": {"name": name, "code": code, "description": description},
            "managers": managers["items"],
            "error": str(e),
        }, status_code=400)


@router.get("/departments/{dept_id}", response_class=HTMLResponse)
def dept_detail(request: Request, dept_id: int):
    from app.main import templates
    current_user = _check_auth(request)
    
    dept = DepartmentService.get_by_id(dept_id)
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    users_in_dept = UserService.get_all(per_page=200, department=dept["name"])
    
    return templates.TemplateResponse("departments/detail.html", {
        "request": request,
        "nav": nav_items("departments", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Departments", "/departments"), (dept["name"], None)),
        "page_title": dept["name"],
        "current_user": current_user,
        "dept": dept,
        "users": users_in_dept["items"],
    })


@router.get("/departments/{dept_id}/edit", response_class=HTMLResponse)
def edit_dept_page(request: Request, dept_id: int):
    from app.main import templates
    current_user = _check_auth(request)
    
    dept = DepartmentService.get_by_id(dept_id)
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    managers = UserService.get_all(per_page=200, role="manager")
    
    return templates.TemplateResponse("departments/form.html", {
        "request": request,
        "nav": nav_items("departments", current_user.get("role")),
        "page_title": f"Edit – {dept['name']}",
        "current_user": current_user,
        "dept": dept,
        "managers": managers["items"],
        "error": None,
    })


@router.post("/departments/{dept_id}/update")
async def update_dept(
    request: Request,
    dept_id: int,
    name: str = Form(...),
    code: str = Form(""),
    description: str = Form(""),
    head_user_id: str = Form(""),
    budget: str = Form("0"),
    location: str = Form(""),
    status: str = Form("active"),
):
    current_user = _check_auth(request)
    
    DepartmentService.update(dept_id, {
        "name": name,
        "code": code,
        "description": description,
        "head_user_id": int(head_user_id) if head_user_id else None,
        "budget": float(budget) if budget else 0.0,
        "location": location,
        "status": status,
    }, updated_by=current_user["id"])
    
    return RedirectResponse(url=f"/departments/{dept_id}", status_code=303)


@router.post("/departments/{dept_id}/delete")
def delete_dept(request: Request, dept_id: int):
    current_user = _check_auth(request)
    
    try:
        DepartmentService.delete(dept_id, deleted_by=current_user["id"])
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    return RedirectResponse(url="/departments", status_code=303)
