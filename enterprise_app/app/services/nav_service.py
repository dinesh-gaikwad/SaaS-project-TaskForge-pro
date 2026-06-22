from typing import Optional

NAV_STRUCTURE = [
    {
        "key": "dashboard",
        "label": "Dashboard",
        "icon": "grid",
        "url": "/",
        "roles": ["admin", "manager", "user", "viewer", "hr"],
    },
    {
        "key": "users",
        "label": "Users",
        "icon": "users",
        "url": "/users",
        "roles": ["admin", "manager", "hr"],
    },
    {
        "key": "departments",
        "label": "Departments",
        "icon": "briefcase",
        "url": "/departments",
        "roles": ["admin", "manager", "hr"],
    },
    {
        "key": "roles",
        "label": "Roles & Permissions",
        "icon": "shield",
        "url": "/roles",
        "roles": ["admin"],
    },
    {
        "key": "reports",
        "label": "Reports",
        "icon": "bar-chart-2",
        "url": "/reports",
        "roles": ["admin", "manager", "hr", "viewer"],
    },
    {
        "key": "audit",
        "label": "Audit Logs",
        "icon": "activity",
        "url": "/audit",
        "roles": ["admin"],
    },
    {
        "key": "settings",
        "label": "Settings",
        "icon": "settings",
        "url": "/settings",
        "roles": ["admin"],
    },
]

def nav_items(active_key: str = "", user_role: str = "admin") -> list:
    """Return nav items, marking the active one."""
    items = []
    for item in NAV_STRUCTURE:
        if user_role in item.get("roles", []):
            items.append({
                **item,
                "is_active": item["key"] == active_key
            })
    return items

def get_breadcrumb(*crumbs) -> list:
    """Build breadcrumb trail: [("Home", "/"), ("Users", "/users"), ("Edit", None)]"""
    return [{"label": label, "url": url} for label, url in crumbs]
