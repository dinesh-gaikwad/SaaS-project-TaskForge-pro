from app.db.database import get_connection
from datetime import datetime
from typing import Optional
import logging

logger = logging.getLogger(__name__)


def log_action(
    user_id: int,
    action: str,
    module: str,
    record_id: int = None,
    old_values: str = None,
    new_values: str = None,
    ip_address: str = "",
    user_agent: str = "",
    status: str = "success"
):
    """Log an action to the audit log."""
    try:
        conn = get_connection()
        cur = conn.cursor()
        
        user = cur.execute("SELECT email FROM users WHERE id = ?", (user_id,)).fetchone()
        email = user["email"] if user else "unknown"
        
        cur.execute("""
            INSERT INTO audit_logs 
            (user_id, user_email, action, module, record_id, old_values, new_values, 
             ip_address, user_agent, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            user_id, email, action, module, record_id,
            old_values, new_values, ip_address, user_agent, status,
            datetime.utcnow().isoformat()
        ))
        
        # Also add to activity feed
        action_labels = {
            "create": "created",
            "update": "updated",
            "delete": "deleted",
            "login": "logged in",
            "logout": "logged out",
            "export": "exported",
        }
        label = action_labels.get(action, action)
        
        icon_map = {
            "create": "plus-circle",
            "update": "edit",
            "delete": "trash-2",
            "login": "log-in",
            "logout": "log-out",
            "export": "download",
        }
        color_map = {
            "create": "success",
            "update": "info",
            "delete": "danger",
            "login": "primary",
            "logout": "secondary",
            "export": "warning",
        }
        
        cur.execute("""
            INSERT INTO activity_feed (user_id, user_name, action, description, icon, color, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            user_id, email, action,
            f"{email} {label} a {module} record",
            icon_map.get(action, "activity"),
            color_map.get(action, "primary"),
            datetime.utcnow().isoformat()
        ))
        
        conn.commit()
        conn.close()
    except Exception as e:
        logger.error(f"Failed to log action: {e}")


def get_audit_logs(
    page: int = 1,
    per_page: int = 20,
    module: str = "",
    action: str = "",
    user_id: int = None,
    date_from: str = "",
    date_to: str = ""
) -> dict:
    """Get paginated audit logs."""
    conn = get_connection()
    cur = conn.cursor()
    
    conditions = []
    params = []
    
    if module:
        conditions.append("module = ?")
        params.append(module)
    if action:
        conditions.append("action = ?")
        params.append(action)
    if user_id:
        conditions.append("user_id = ?")
        params.append(user_id)
    if date_from:
        conditions.append("created_at >= ?")
        params.append(date_from)
    if date_to:
        conditions.append("created_at <= ?")
        params.append(date_to + "T23:59:59")
    
    where = "WHERE " + " AND ".join(conditions) if conditions else ""
    
    total = cur.execute(f"SELECT COUNT(*) as c FROM audit_logs {where}", params).fetchone()["c"]
    offset = (page - 1) * per_page
    
    logs = cur.execute(
        f"SELECT * FROM audit_logs {where} ORDER BY id DESC LIMIT ? OFFSET ?",
        params + [per_page, offset]
    ).fetchall()
    
    conn.close()
    
    total_pages = (total + per_page - 1) // per_page
    return {
        "items": [dict(l) for l in logs],
        "total": total,
        "page": page,
        "per_page": per_page,
        "total_pages": total_pages,
        "has_prev": page > 1,
        "has_next": page < total_pages,
    }


def get_activity_feed(limit: int = 20) -> list:
    """Get recent activity feed."""
    conn = get_connection()
    items = conn.execute(
        "SELECT * FROM activity_feed ORDER BY id DESC LIMIT ?", (limit,)
    ).fetchall()
    conn.close()
    return [dict(i) for i in items]
