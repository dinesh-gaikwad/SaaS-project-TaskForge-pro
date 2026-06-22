import sqlite3
import csv
import io
from typing import Optional, List, Dict, Any
from datetime import datetime
from app.db.database import get_connection
from app.core.security import get_password_hash, generate_api_key
from app.services.audit_service import log_action
import logging

logger = logging.getLogger(__name__)


class UserService:

    @staticmethod
    def get_all(
        page: int = 1,
        per_page: int = 10,
        search: str = "",
        role: str = "",
        department: str = "",
        status: str = ""
    ) -> Dict[str, Any]:
        """Get paginated list of users with filters."""
        conn = get_connection()
        cur = conn.cursor()
        
        conditions = []
        params = []
        
        if search:
            conditions.append("(u.full_name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?)")
            like = f"%{search}%"
            params.extend([like, like, like])
        
        if role:
            conditions.append("u.role = ?")
            params.append(role)
        
        if department:
            conditions.append("u.department = ?")
            params.append(department)
        
        if status:
            conditions.append("u.status = ?")
            params.append(status)
        
        where = "WHERE " + " AND ".join(conditions) if conditions else ""
        
        total = cur.execute(
            f"SELECT COUNT(*) as c FROM users u {where}", params
        ).fetchone()["c"]
        
        offset = (page - 1) * per_page
        users = cur.execute(
            f"""SELECT u.*, d.name as dept_name 
                FROM users u 
                LEFT JOIN departments d ON u.department_id = d.id
                {where} 
                ORDER BY u.id DESC 
                LIMIT ? OFFSET ?""",
            params + [per_page, offset]
        ).fetchall()
        
        conn.close()
        
        total_pages = (total + per_page - 1) // per_page
        
        return {
            "items": [dict(u) for u in users],
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": total_pages,
            "has_prev": page > 1,
            "has_next": page < total_pages,
        }

    @staticmethod
    def get_by_id(user_id: int) -> Optional[Dict]:
        """Get user by ID."""
        conn = get_connection()
        user = conn.execute(
            "SELECT * FROM users WHERE id = ?", (user_id,)
        ).fetchone()
        conn.close()
        return dict(user) if user else None

    @staticmethod
    def get_by_email(email: str) -> Optional[Dict]:
        """Get user by email."""
        conn = get_connection()
        user = conn.execute(
            "SELECT * FROM users WHERE email = ?", (email,)
        ).fetchone()
        conn.close()
        return dict(user) if user else None

    @staticmethod
    def create(data: Dict, created_by: int = None) -> int:
        """Create a new user."""
        conn = get_connection()
        cur = conn.cursor()
        
        exists = cur.execute(
            "SELECT id FROM users WHERE email = ?", (data["email"],)
        ).fetchone()
        if exists:
            conn.close()
            raise ValueError(f"Email '{data['email']}' already exists")
        
        now = datetime.utcnow().isoformat()
        user_id = cur.execute("""
            INSERT INTO users (
                full_name, email, password_hash, role, department,
                department_id, phone, status, api_key, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            data["full_name"],
            data["email"],
            get_password_hash(data.get("password", "changeme123")),
            data.get("role", "user"),
            data.get("department", ""),
            data.get("department_id"),
            data.get("phone", ""),
            data.get("status", "active"),
            generate_api_key(),
            now,
            now
        )).lastrowid
        
        conn.commit()
        conn.close()
        
        if created_by:
            log_action(created_by, "create", "users", user_id, new_values=str(data))
        
        logger.info(f"User created: {data['email']} (id={user_id})")
        return user_id

    @staticmethod
    def update(user_id: int, data: Dict, updated_by: int = None) -> bool:
        """Update an existing user."""
        conn = get_connection()
        cur = conn.cursor()
        
        old = cur.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if not old:
            conn.close()
            return False
        
        email_conflict = cur.execute(
            "SELECT id FROM users WHERE email = ? AND id != ?",
            (data["email"], user_id)
        ).fetchone()
        if email_conflict:
            conn.close()
            raise ValueError(f"Email '{data['email']}' is taken by another user")
        
        now = datetime.utcnow().isoformat()
        cur.execute("""
            UPDATE users SET
                full_name = ?, email = ?, role = ?,
                department = ?, department_id = ?, phone = ?,
                status = ?, updated_at = ?
            WHERE id = ?
        """, (
            data["full_name"],
            data["email"],
            data.get("role", "user"),
            data.get("department", ""),
            data.get("department_id"),
            data.get("phone", ""),
            data.get("status", "active"),
            now,
            user_id
        ))
        
        conn.commit()
        conn.close()
        
        if updated_by:
            log_action(updated_by, "update", "users", user_id,
                       old_values=str(dict(old)), new_values=str(data))
        
        return True

    @staticmethod
    def delete(user_id: int, deleted_by: int = None) -> bool:
        """Delete a user."""
        conn = get_connection()
        cur = conn.cursor()
        
        user = cur.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if not user:
            conn.close()
            return False
        
        if dict(user).get("role") == "admin":
            admin_count = cur.execute(
                "SELECT COUNT(*) as c FROM users WHERE role = 'admin' AND status = 'active'"
            ).fetchone()["c"]
            if admin_count <= 1:
                conn.close()
                raise ValueError("Cannot delete the last admin user")
        
        cur.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
        conn.close()
        
        if deleted_by:
            log_action(deleted_by, "delete", "users", user_id, old_values=str(dict(user)))
        
        return True

    @staticmethod
    def toggle_status(user_id: int, actor_id: int = None) -> str:
        """Toggle user active/inactive status."""
        conn = get_connection()
        cur = conn.cursor()
        user = cur.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if not user:
            conn.close()
            raise ValueError("User not found")
        
        new_status = "inactive" if dict(user)["status"] == "active" else "active"
        cur.execute(
            "UPDATE users SET status = ?, updated_at = ? WHERE id = ?",
            (new_status, datetime.utcnow().isoformat(), user_id)
        )
        conn.commit()
        conn.close()
        return new_status

    @staticmethod
    def export_csv(filters: Dict = {}) -> str:
        """Export users to CSV string."""
        conn = get_connection()
        users = conn.execute("""
            SELECT id, full_name, email, role, department, phone, status, created_at
            FROM users ORDER BY id
        """).fetchall()
        conn.close()
        
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=[
            "id", "full_name", "email", "role", "department", "phone", "status", "created_at"
        ])
        writer.writeheader()
        for user in users:
            writer.writerow(dict(user))
        
        return output.getvalue()

    @staticmethod
    def get_stats() -> Dict:
        """Get user statistics."""
        conn = get_connection()
        cur = conn.cursor()
        
        total = cur.execute("SELECT COUNT(*) as c FROM users").fetchone()["c"]
        active = cur.execute("SELECT COUNT(*) as c FROM users WHERE status='active'").fetchone()["c"]
        inactive = cur.execute("SELECT COUNT(*) as c FROM users WHERE status='inactive'").fetchone()["c"]
        
        by_role = cur.execute("""
            SELECT role, COUNT(*) as count FROM users GROUP BY role ORDER BY count DESC
        """).fetchall()
        
        by_dept = cur.execute("""
            SELECT department, COUNT(*) as count FROM users 
            WHERE department IS NOT NULL AND department != ''
            GROUP BY department ORDER BY count DESC LIMIT 8
        """).fetchall()
        
        recent = cur.execute("""
            SELECT * FROM users ORDER BY created_at DESC LIMIT 5
        """).fetchall()
        
        conn.close()
        
        return {
            "total": total,
            "active": active,
            "inactive": inactive,
            "by_role": [dict(r) for r in by_role],
            "by_dept": [dict(d) for d in by_dept],
            "recent": [dict(u) for u in recent],
        }

    @staticmethod
    def update_last_login(user_id: int, ip: str = ""):
        """Update user's last login time."""
        conn = get_connection()
        conn.execute("""
            UPDATE users SET last_login = ?, login_count = login_count + 1 WHERE id = ?
        """, (datetime.utcnow().isoformat(), user_id))
        conn.commit()
        conn.close()

    @staticmethod
    def update_password(user_id: int, new_password: str) -> bool:
        """Update user password."""
        conn = get_connection()
        conn.execute(
            "UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?",
            (get_password_hash(new_password), datetime.utcnow().isoformat(), user_id)
        )
        conn.commit()
        conn.close()
        return True
