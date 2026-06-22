from app.db.database import get_connection
from app.services.audit_service import get_activity_feed
from datetime import datetime, timedelta
import json


class DashboardService:

    @staticmethod
    def get_overview_stats() -> dict:
        """Get high-level KPI stats for dashboard."""
        conn = get_connection()
        cur = conn.cursor()
        
        total_users = cur.execute("SELECT COUNT(*) as c FROM users").fetchone()["c"]
        active_users = cur.execute("SELECT COUNT(*) as c FROM users WHERE status='active'").fetchone()["c"]
        total_depts = cur.execute("SELECT COUNT(*) as c FROM departments").fetchone()["c"]
        total_roles = cur.execute("SELECT COUNT(*) as c FROM roles").fetchone()["c"]
        
        # New users last 30 days
        thirty_days_ago = (datetime.utcnow() - timedelta(days=30)).isoformat()
        new_users_30d = cur.execute(
            "SELECT COUNT(*) as c FROM users WHERE created_at >= ?", (thirty_days_ago,)
        ).fetchone()["c"]
        
        # Login activity last 7 days
        seven_days_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()
        logins_7d = cur.execute(
            "SELECT COUNT(*) as c FROM audit_logs WHERE action='login' AND created_at >= ?",
            (seven_days_ago,)
        ).fetchone()["c"]
        
        # Users by role chart data
        by_role = cur.execute("""
            SELECT role, COUNT(*) as count 
            FROM users WHERE status='active'
            GROUP BY role ORDER BY count DESC
        """).fetchall()
        
        # Users by department chart data
        by_dept = cur.execute("""
            SELECT department, COUNT(*) as count 
            FROM users WHERE status='active' AND department IS NOT NULL AND department != ''
            GROUP BY department ORDER BY count DESC LIMIT 6
        """).fetchall()
        
        # Monthly signups last 6 months
        monthly = []
        for i in range(5, -1, -1):
            d = datetime.utcnow() - timedelta(days=30 * i)
            month_start = d.replace(day=1, hour=0, minute=0, second=0).isoformat()
            next_month = (d.replace(day=28) + timedelta(days=4)).replace(day=1)
            month_end = next_month.isoformat()
            count = cur.execute(
                "SELECT COUNT(*) as c FROM users WHERE created_at >= ? AND created_at < ?",
                (month_start, month_end)
            ).fetchone()["c"]
            monthly.append({"month": d.strftime("%b"), "count": count})
        
        conn.close()
        
        return {
            "total_users": total_users,
            "active_users": active_users,
            "inactive_users": total_users - active_users,
            "total_departments": total_depts,
            "total_roles": total_roles,
            "new_users_30d": new_users_30d,
            "logins_7d": logins_7d,
            "by_role": [dict(r) for r in by_role],
            "by_dept": [dict(d) for d in by_dept],
            "monthly_signups": monthly,
            "activity": get_activity_feed(10),
        }
