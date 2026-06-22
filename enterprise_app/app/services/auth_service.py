from app.db.database import get_connection
from app.core.security import verify_password, create_session_token, verify_session_token
from app.services.audit_service import log_action
from app.services.user_service import UserService
from datetime import datetime, timedelta
from typing import Optional, Dict
import logging

logger = logging.getLogger(__name__)


class AuthService:

    @staticmethod
    def authenticate(email: str, password: str) -> Optional[Dict]:
        """Authenticate user with email and password."""
        user = UserService.get_by_email(email)
        
        if not user:
            logger.warning(f"Login attempt for unknown email: {email}")
            return None
        
        if user["status"] != "active":
            logger.warning(f"Login attempt for inactive user: {email}")
            return None
        
        if not verify_password(password, user.get("password_hash", "")):
            logger.warning(f"Failed login attempt for: {email}")
            return None
        
        UserService.update_last_login(user["id"])
        log_action(user["id"], "login", "auth", user["id"])
        
        logger.info(f"User logged in: {email}")
        return user

    @staticmethod
    def create_session(user: Dict) -> str:
        """Create a session token for authenticated user."""
        return create_session_token(user["id"], user["email"])

    @staticmethod
    def get_current_user_from_token(token: str) -> Optional[Dict]:
        """Get current user from session token."""
        if not token:
            return None
        
        payload = verify_session_token(token)
        if not payload:
            return None
        
        user_id = int(payload.get("sub", 0))
        user = UserService.get_by_id(user_id)
        
        if not user or user["status"] != "active":
            return None
        
        return user

    @staticmethod
    def logout(user_id: int):
        """Handle user logout."""
        log_action(user_id, "logout", "auth", user_id)

    @staticmethod
    def get_session_user(request) -> Optional[Dict]:
        """Extract user from request cookie."""
        token = request.cookies.get("session_token")
        if not token:
            return None
        return AuthService.get_current_user_from_token(token)
