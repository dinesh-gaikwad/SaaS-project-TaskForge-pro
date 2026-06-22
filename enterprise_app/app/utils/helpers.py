from datetime import datetime
from typing import Any, Dict, List
import re
import json


def format_datetime(dt_str: str, fmt: str = "%d %b %Y, %H:%M") -> str:
    """Format datetime string to human-readable."""
    if not dt_str:
        return "—"
    try:
        dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
        return dt.strftime(fmt)
    except Exception:
        return dt_str[:16] if dt_str else "—"


def format_date(dt_str: str) -> str:
    return format_datetime(dt_str, "%d %b %Y")


def time_ago(dt_str: str) -> str:
    """Human-readable time ago string."""
    if not dt_str:
        return "Never"
    try:
        dt = datetime.fromisoformat(dt_str)
        now = datetime.utcnow()
        diff = now - dt
        
        seconds = diff.total_seconds()
        if seconds < 60:
            return "Just now"
        elif seconds < 3600:
            mins = int(seconds // 60)
            return f"{mins}m ago"
        elif seconds < 86400:
            hours = int(seconds // 3600)
            return f"{hours}h ago"
        elif seconds < 604800:
            days = int(seconds // 86400)
            return f"{days}d ago"
        else:
            return format_date(dt_str)
    except Exception:
        return dt_str[:10] if dt_str else "—"


def validate_email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def slugify(text: str) -> str:
    """Convert text to slug format."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text


def truncate(text: str, length: int = 50) -> str:
    """Truncate text to length."""
    if not text:
        return ""
    return text[:length] + "..." if len(text) > length else text


def safe_int(value: Any, default: int = 0) -> int:
    """Safely convert to int."""
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def safe_float(value: Any, default: float = 0.0) -> float:
    """Safely convert to float."""
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def paginate_range(current_page: int, total_pages: int, delta: int = 2) -> List[Any]:
    """Generate page numbers for pagination widget."""
    pages = []
    left = max(1, current_page - delta)
    right = min(total_pages, current_page + delta)
    
    if left > 1:
        pages.append(1)
        if left > 2:
            pages.append("...")
    
    pages.extend(range(left, right + 1))
    
    if right < total_pages:
        if right < total_pages - 1:
            pages.append("...")
        pages.append(total_pages)
    
    return pages


def format_currency(value: float, currency: str = "USD") -> str:
    """Format number as currency."""
    try:
        return f"${float(value):,.2f}"
    except (TypeError, ValueError):
        return "$0.00"


def get_initials(name: str) -> str:
    """Get initials from full name."""
    if not name:
        return "?"
    parts = name.strip().split()
    if len(parts) == 1:
        return parts[0][0].upper()
    return (parts[0][0] + parts[-1][0]).upper()


def role_badge_class(role: str) -> str:
    """Get Bootstrap badge class for role."""
    return {
        "admin": "danger",
        "manager": "warning",
        "hr": "info",
        "user": "primary",
        "viewer": "secondary",
    }.get(role, "secondary")


def status_badge_class(status: str) -> str:
    """Get Bootstrap badge class for status."""
    return {
        "active": "success",
        "inactive": "secondary",
        "suspended": "danger",
        "pending": "warning",
    }.get(status, "secondary")


ROLE_ICONS = {
    "admin": "shield",
    "manager": "briefcase",
    "hr": "heart",
    "user": "user",
    "viewer": "eye",
}

STATUS_ICONS = {
    "active": "check-circle",
    "inactive": "x-circle",
    "suspended": "slash",
    "pending": "clock",
}
