from fastapi import Request, HTTPException
from fastapi.responses import RedirectResponse
from app.services.auth_service import AuthService
from typing import Optional


def get_current_user(request: Request) -> Optional[dict]:
    """Get current user from session. Returns None if not logged in."""
    return AuthService.get_session_user(request)


def require_auth(request: Request) -> dict:
    """Require authentication. Raises 401 if not logged in."""
    user = get_current_user(request)
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return user


def require_role(request: Request, allowed_roles: list) -> dict:
    """Require specific role(s)."""
    user = require_auth(request)
    if user["role"] not in allowed_roles and user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return user


def require_admin(request: Request) -> dict:
    """Require admin role."""
    return require_role(request, ["admin"])


class AuthMiddleware:
    """Middleware to check auth on protected routes."""
    
    PUBLIC_PATHS = ["/login", "/logout", "/static", "/health", "/favicon.ico"]
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            path = scope.get("path", "")
            
            is_public = any(path.startswith(pub) for pub in self.PUBLIC_PATHS)
            
            if not is_public:
                headers = dict(scope.get("headers", []))
                cookie_header = headers.get(b"cookie", b"").decode("utf-8", errors="ignore")
                
                has_session = "session_token=" in cookie_header
                
                if not has_session:
                    from starlette.responses import RedirectResponse as StarletteRedirect
                    response = StarletteRedirect(f"/login?next={path}")
                    await response(scope, receive, send)
                    return
        
        await self.app(scope, receive, send)
