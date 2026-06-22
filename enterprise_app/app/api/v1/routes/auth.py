from fastapi import APIRouter, Request, Form, Response
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService

router = APIRouter(tags=["auth"])


@router.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    from app.main import templates
    user = AuthService.get_session_user(request)
    if user:
        return RedirectResponse(url="/", status_code=302)
    next_url = request.query_params.get("next", "/")
    return templates.TemplateResponse(
        "auth/login.html",
        {"request": request, "next": next_url, "page_title": "Login", "error": None}
    )


@router.post("/login")
async def login(
    request: Request,
    response: Response,
    email: str = Form(...),
    password: str = Form(...),
    remember_me: str = Form(""),
    next_url: str = Form("/")
):
    from app.main import templates
    user = AuthService.authenticate(email, password)
    
    if not user:
        return templates.TemplateResponse(
            "auth/login.html",
            {
                "request": request,
                "page_title": "Login",
                "error": "Invalid email or password",
                "email": email,
                "next": next_url
            },
            status_code=401
        )
    
    token = AuthService.create_session(user)
    max_age = 86400 * 30 if remember_me else 3600
    
    redirect = RedirectResponse(url=next_url or "/", status_code=303)
    redirect.set_cookie(
        key="session_token",
        value=token,
        max_age=max_age,
        httponly=True,
        samesite="lax"
    )
    return redirect


@router.get("/logout")
def logout(request: Request):
    user = AuthService.get_session_user(request)
    if user:
        AuthService.logout(user["id"])
    
    response = RedirectResponse(url="/login", status_code=302)
    response.delete_cookie("session_token")
    return response


@router.get("/profile", response_class=HTMLResponse)
def profile_page(request: Request):
    from app.main import templates
    from app.services.nav_service import nav_items
    user = AuthService.get_session_user(request)
    if not user:
        return RedirectResponse(url="/login", status_code=302)
    
    return templates.TemplateResponse(
        "auth/profile.html",
        {
            "request": request,
            "nav": nav_items("profile", user.get("role", "user")),
            "page_title": "My Profile",
            "user": user,
            "current_user": user,
        }
    )
