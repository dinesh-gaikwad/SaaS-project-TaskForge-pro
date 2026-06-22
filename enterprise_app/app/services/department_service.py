from app.db.database import get_connection
from typing import Dict, Any, Optional, List
from datetime import datetime
from app.services.audit_service import log_action
import logging

logger = logging.getLogger(__name__)


class DepartmentService:

    @staticmethod
    def get_all(
        page: int = 1,
        per_page: int = 10,
        search: str = "",
        status: str = ""
    ) -> Dict[str, Any]:
        """Get paginated list of departments."""
        conn = get_connection()
        cur = conn.cursor()
        
        conditions = []
        params = []
        
        if search:
            conditions.append("(d.name LIKE ? OR d.code LIKE ? OR d.description LIKE ?)")
            like = f"%{search}%"
            params.extend([like, like, like])
        
        if status:
            conditions.append("d.status = ?")
            params.append(status)
        
        where = "WHERE " + " AND ".join(conditions) if conditions else ""
        
        total = cur.execute(f"SELECT COUNT(*) as c FROM departments d {where}", params).fetchone()["c"]
        offset = (page - 1) * per_page
        
        depts = cur.execute(f"""
            SELECT d.*, 
                   COUNT(u.id) as user_count,
                   head.full_name as head_name
            FROM departments d
            LEFT JOIN users u ON u.department = d.name AND u.status = 'active'
            LEFT JOIN users head ON head.id = d.head_user_id
            {where}
            GROUP BY d.id
            ORDER BY d.name ASC
            LIMIT ? OFFSET ?
        """, params + [per_page, offset]).fetchall()
        
        conn.close()
        total_pages = (total + per_page - 1) // per_page
        
        return {
            "items": [dict(d) for d in depts],
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": total_pages,
            "has_prev": page > 1,
            "has_next": page < total_pages,
        }

    @staticmethod
    def get_by_id(dept_id: int) -> Optional[Dict]:
        conn = get_connection()
        dept = conn.execute("""
            SELECT d.*, COUNT(u.id) as user_count
            FROM departments d
            LEFT JOIN users u ON u.department = d.name AND u.status = 'active'
            WHERE d.id = ?
            GROUP BY d.id
        """, (dept_id,)).fetchone()
        conn.close()
        return dict(dept) if dept else None

    @staticmethod
    def get_all_simple() -> List[Dict]:
        """Get all departments as simple list for dropdowns."""
        conn = get_connection()
        depts = conn.execute(
            "SELECT id, name, code FROM departments WHERE status='active' ORDER BY name"
        ).fetchall()
        conn.close()
        return [dict(d) for d in depts]

    @staticmethod
    def create(data: Dict, created_by: int = None) -> int:
        conn = get_connection()
        cur = conn.cursor()
        
        exists = cur.execute("SELECT id FROM departments WHERE name = ?", (data["name"],)).fetchone()
        if exists:
            conn.close()
            raise ValueError(f"Department '{data['name']}' already exists")
        
        now = datetime.utcnow().isoformat()
        dept_id = cur.execute("""
            INSERT INTO departments (name, code, description, head_user_id, budget, location, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            data["name"],
            data.get("code", ""),
            data.get("description", ""),
            data.get("head_user_id"),
            float(data.get("budget", 0)),
            data.get("location", ""),
            data.get("status", "active"),
            now, now
        )).lastrowid
        
        conn.commit()
        conn.close()
        return dept_id

    @staticmethod
    def update(dept_id: int, data: Dict, updated_by: int = None) -> bool:
        conn = get_connection()
        cur = conn.cursor()
        
        exists = cur.execute("SELECT id FROM departments WHERE id = ?", (dept_id,)).fetchone()
        if not exists:
            conn.close()
            return False
        
        now = datetime.utcnow().isoformat()
        cur.execute("""
            UPDATE departments SET 
                name = ?, code = ?, description = ?, head_user_id = ?,
                budget = ?, location = ?, status = ?, updated_at = ?
            WHERE id = ?
        """, (
            data["name"],
            data.get("code", ""),
            data.get("description", ""),
            data.get("head_user_id"),
            float(data.get("budget", 0)),
            data.get("location", ""),
            data.get("status", "active"),
            now, dept_id
        ))
        
        conn.commit()
        conn.close()
        return True

    @staticmethod
    def delete(dept_id: int, deleted_by: int = None) -> bool:
        conn = get_connection()
        cur = conn.cursor()
        
        dept = cur.execute("SELECT * FROM departments WHERE id = ?", (dept_id,)).fetchone()
        if not dept:
            conn.close()
            return False
        
        user_count = cur.execute(
            "SELECT COUNT(*) as c FROM users WHERE department = ?", (dict(dept)["name"],)
        ).fetchone()["c"]
        
        if user_count > 0:
            conn.close()
            raise ValueError(f"Cannot delete department with {user_count} users. Reassign users first.")
        
        cur.execute("DELETE FROM departments WHERE id = ?", (dept_id,))
        conn.commit()
        conn.close()
        return True

    @staticmethod
    def get_stats() -> Dict:
        conn = get_connection()
        cur = conn.cursor()
        
        total = cur.execute("SELECT COUNT(*) as c FROM departments").fetchone()["c"]
        active = cur.execute("SELECT COUNT(*) as c FROM departments WHERE status='active'").fetchone()["c"]
        
        with_users = cur.execute("""
            SELECT d.name, COUNT(u.id) as count, d.budget
            FROM departments d
            LEFT JOIN users u ON u.department = d.name AND u.status = 'active'
            GROUP BY d.id
            ORDER BY count DESC
        """).fetchall()
        
        conn.close()
        return {
            "total": total,
            "active": active,
            "by_users": [dict(d) for d in with_users],
        }
