#!/bin/bash
# ============================================================
# FASTAPI ENTERPRISE APP - SETUP SCRIPT PART 1
# Creates: Project structure + Core files
# ============================================================

set -e
PROJECT="enterprise_app"

echo "🚀 Creating FastAPI Enterprise App..."

# ─── Directory Structure ───────────────────────────────────
mkdir -p $PROJECT/{app/{api/v1/routes,db,models,schemas,services,middleware,utils,core},\
templates/{users,departments,roles,reports,auth,partials,settings},\
static/{css,js,images},tests,scripts,logs,exports}

echo "✅ Directory structure created"

# ─── requirements.txt ─────────────────────────────────────
cat > $PROJECT/requirements.txt <<'EOF'
fastapi==0.110.0
uvicorn[standard]==0.29.0
jinja2==3.1.3
python-multipart==0.0.9
pydantic[email]==2.6.4
passlib[bcrypt]==1.7.4
python-jose[cryptography]==3.3.0
itsdangerous==2.2.0
aiosqlite==0.20.0
httpx==0.27.0
pytest==8.1.1
pytest-asyncio==0.23.6
rich==13.7.1
python-dotenv==1.0.1
EOF

echo "✅ requirements.txt created"

# ─── .env ─────────────────────────────────────────────────
cat > $PROJECT/.env <<'EOF'
APP_NAME=Enterprise Manager
APP_VERSION=1.0.0
SECRET_KEY=supersecret-key-change-in-production-123456789
DEBUG=True
DATABASE_URL=sqlite:///./enterprise.db
SESSION_MAX_AGE=3600
ADMIN_EMAIL=admin@company.com
ADMIN_PASSWORD=admin123
ADMIN_NAME=Super Admin
EOF

echo "✅ .env created"

# ─── app/__init__.py ───────────────────────────────────────
cat > $PROJECT/app/__init__.py <<'EOF'
# Enterprise App
EOF

# ─── app/core/config.py ───────────────────────────────────
cat > $PROJECT/app/core/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/core/config.py <<'EOF'
import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "Enterprise Manager")
    APP_VERSION: str = os.getenv("APP_VERSION", "1.0.0")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-this-secret")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./enterprise.db")
    SESSION_MAX_AGE: int = int(os.getenv("SESSION_MAX_AGE", "3600"))
    ADMIN_EMAIL: str = os.getenv("ADMIN_EMAIL", "admin@company.com")
    ADMIN_PASSWORD: str = os.getenv("ADMIN_PASSWORD", "admin123")
    ADMIN_NAME: str = os.getenv("ADMIN_NAME", "Super Admin")
    
    # Pagination
    PAGE_SIZE: int = 10
    MAX_PAGE_SIZE: int = 100
    
    # App Metadata
    COMPANY_NAME: str = "Acme Corporation"
    COMPANY_LOGO: str = "/static/images/logo.png"
    
    # Features
    ENABLE_AUDIT_LOG: bool = True
    ENABLE_EMAIL_NOTIFICATIONS: bool = False
    ENABLE_2FA: bool = False
    
    # File Upload
    MAX_UPLOAD_SIZE_MB: int = 10
    ALLOWED_EXTENSIONS: list = [".jpg", ".jpeg", ".png", ".pdf", ".xlsx", ".csv"]
    
    # Export
    EXPORT_DIR: str = "exports"

settings = Settings()
EOF

echo "✅ Config created"

# ─── app/core/security.py ─────────────────────────────────
cat > $PROJECT/app/core/security.py <<'EOF'
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional
from app.core.config import settings
import secrets
import hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify plain password against hashed password."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Optional[dict]:
    """Decode and validate a JWT token."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

def generate_reset_token() -> str:
    """Generate a secure password reset token."""
    return secrets.token_urlsafe(32)

def generate_api_key() -> str:
    """Generate a secure API key."""
    return "ent_" + secrets.token_hex(24)

def hash_token(token: str) -> str:
    """Hash a token for secure storage."""
    return hashlib.sha256(token.encode()).hexdigest()

def create_session_token(user_id: int, email: str) -> str:
    """Create a session token."""
    data = {
        "sub": str(user_id),
        "email": email,
        "type": "session"
    }
    return create_access_token(data, timedelta(seconds=settings.SESSION_MAX_AGE))

def verify_session_token(token: str) -> Optional[dict]:
    """Verify session token and return user data."""
    payload = decode_access_token(token)
    if payload and payload.get("type") == "session":
        return payload
    return None
EOF

echo "✅ Security module created"

# ─── app/db/database.py ───────────────────────────────────
cat > $PROJECT/app/db/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/db/database.py <<'EOF'
import sqlite3
from pathlib import Path
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

DB_PATH = "enterprise.db"

def get_connection() -> sqlite3.Connection:
    """Get a database connection with row factory."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    return conn

def execute_query(query: str, params: tuple = (), fetch: str = None):
    """Execute a query and optionally fetch results."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(query, params)
        if fetch == "one":
            result = cur.fetchone()
        elif fetch == "all":
            result = cur.fetchall()
        else:
            conn.commit()
            result = cur.lastrowid
        return result
    except Exception as e:
        conn.rollback()
        logger.error(f"Database error: {e}")
        raise
    finally:
        conn.close()

def execute_many(query: str, params_list: list):
    """Execute multiple queries in a transaction."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.executemany(query, params_list)
        conn.commit()
        return cur.rowcount
    except Exception as e:
        conn.rollback()
        logger.error(f"Database error: {e}")
        raise
    finally:
        conn.close()

def table_exists(table_name: str) -> bool:
    """Check if a table exists in the database."""
    result = execute_query(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
        fetch="one"
    )
    return result is not None

def get_table_count(table_name: str) -> int:
    """Get total count of records in a table."""
    result = execute_query(f"SELECT COUNT(*) as cnt FROM {table_name}", fetch="one")
    return result["cnt"] if result else 0
EOF

echo "✅ Database module created"

# ─── app/db/init_db.py ────────────────────────────────────
cat > $PROJECT/app/db/init_db.py <<'EOF'
import sqlite3
import logging
from app.db.database import get_connection, DB_PATH
from app.core.security import get_password_hash
from app.core.config import settings
from datetime import datetime

logger = logging.getLogger(__name__)

def init_database():
    """Initialize the database with all required tables."""
    conn = get_connection()
    cur = conn.cursor()
    
    logger.info("🗄️  Initializing database...")
    
    # ── Users Table ─────────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT 'user',
        department_id INTEGER,
        department TEXT,
        phone TEXT,
        avatar TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        last_login TEXT,
        login_count INTEGER DEFAULT 0,
        api_key TEXT UNIQUE,
        reset_token TEXT,
        reset_token_expires TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (department_id) REFERENCES departments(id)
    )""")

    # ── Departments Table ────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        code TEXT UNIQUE,
        description TEXT,
        head_user_id INTEGER,
        parent_id INTEGER,
        budget REAL DEFAULT 0,
        location TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (head_user_id) REFERENCES users(id),
        FOREIGN KEY (parent_id) REFERENCES departments(id)
    )""")

    # ── Roles Table ──────────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        description TEXT,
        permissions TEXT DEFAULT '{}',
        is_system INTEGER DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )""")

    # ── Permissions Table ────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        module TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )""")

    # ── Role Permissions ─────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS role_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id INTEGER NOT NULL,
        permission_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
        FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
        UNIQUE(role_id, permission_id)
    )""")

    # ── Audit Logs Table ─────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        user_email TEXT,
        action TEXT NOT NULL,
        module TEXT NOT NULL,
        record_id INTEGER,
        old_values TEXT,
        new_values TEXT,
        ip_address TEXT,
        user_agent TEXT,
        status TEXT DEFAULT 'success',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )""")

    # ── Sessions Table ───────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT UNIQUE NOT NULL,
        ip_address TEXT,
        user_agent TEXT,
        expires_at TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )""")

    # ── Notifications Table ──────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT DEFAULT 'info',
        is_read INTEGER DEFAULT 0,
        link TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )""")

    # ── Settings Table ───────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT,
        type TEXT DEFAULT 'string',
        description TEXT,
        group_name TEXT DEFAULT 'general',
        is_public INTEGER DEFAULT 0,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )""")

    # ── Reports Table ────────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS saved_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        report_type TEXT NOT NULL,
        query_params TEXT,
        created_by INTEGER,
        is_public INTEGER DEFAULT 0,
        last_run TEXT,
        run_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id)
    )""")

    # ── Activity Feed ────────────────────────────────────────
    cur.execute("""
    CREATE TABLE IF NOT EXISTS activity_feed (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        user_name TEXT,
        action TEXT NOT NULL,
        description TEXT,
        icon TEXT DEFAULT 'activity',
        color TEXT DEFAULT 'primary',
        link TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )""")

    conn.commit()
    logger.info("✅ All tables created")

    # ── Seed Default Data ────────────────────────────────────
    _seed_roles(cur)
    _seed_departments(cur)
    _seed_admin(cur)
    _seed_sample_users(cur)
    _seed_permissions(cur)
    _seed_settings(cur)
    
    conn.commit()
    conn.close()
    logger.info("✅ Database initialized successfully!")

def _seed_roles(cur):
    """Seed default roles."""
    roles = [
        ("admin", "Administrator", "Full system access", '["all"]', 1),
        ("manager", "Manager", "Department management access", '["users.read","users.write","reports.read","departments.read"]', 1),
        ("user", "Regular User", "Basic access", '["dashboard.read","profile.read","profile.write"]', 1),
        ("viewer", "Viewer", "Read-only access", '["dashboard.read","reports.read"]', 1),
        ("hr", "HR Manager", "HR module access", '["users.read","users.write","departments.read","reports.read"]', 1),
    ]
    for role in roles:
        cur.execute("""
            INSERT OR IGNORE INTO roles (name, display_name, description, permissions, is_system)
            VALUES (?, ?, ?, ?, ?)
        """, role)

def _seed_departments(cur):
    """Seed default departments."""
    departments = [
        ("Engineering", "ENG", "Software Engineering Department", None, None, 500000.0, "Floor 3"),
        ("Human Resources", "HR", "People Operations", None, None, 200000.0, "Floor 1"),
        ("Finance", "FIN", "Finance & Accounting", None, None, 300000.0, "Floor 2"),
        ("Marketing", "MKT", "Marketing & Growth", None, None, 400000.0, "Floor 1"),
        ("Operations", "OPS", "Operations & Infrastructure", None, None, 350000.0, "Floor 4"),
        ("Product", "PRD", "Product Management", None, None, 250000.0, "Floor 3"),
        ("Sales", "SLS", "Sales & Business Dev", None, None, 600000.0, "Floor 2"),
        ("Customer Support", "CS", "Customer Success", None, None, 150000.0, "Floor 1"),
    ]
    for dept in departments:
        cur.execute("""
            INSERT OR IGNORE INTO departments (name, code, description, head_user_id, parent_id, budget, location)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, dept)

def _seed_admin(cur):
    """Seed admin user."""
    from app.core.security import get_password_hash, generate_api_key
    admin_exists = cur.execute("SELECT id FROM users WHERE email=?", (settings.ADMIN_EMAIL,)).fetchone()
    if not admin_exists:
        cur.execute("""
            INSERT INTO users (full_name, email, password_hash, role, department, status, api_key)
            VALUES (?, ?, ?, 'admin', 'Engineering', 'active', ?)
        """, (settings.ADMIN_NAME, settings.ADMIN_EMAIL, get_password_hash(settings.ADMIN_PASSWORD), generate_api_key()))
        logger.info(f"✅ Admin user created: {settings.ADMIN_EMAIL}")

def _seed_sample_users(cur):
    """Seed sample users for demo."""
    from app.core.security import get_password_hash
    count = cur.execute("SELECT COUNT(*) as c FROM users").fetchone()["c"]
    if count > 1:
        return
    
    sample_users = [
        ("Alice Johnson", "alice@company.com", "manager", "Engineering", "+1-555-0101"),
        ("Bob Smith", "bob@company.com", "user", "Engineering", "+1-555-0102"),
        ("Carol White", "carol@company.com", "hr", "Human Resources", "+1-555-0103"),
        ("David Brown", "david@company.com", "user", "Finance", "+1-555-0104"),
        ("Eve Davis", "eve@company.com", "manager", "Marketing", "+1-555-0105"),
        ("Frank Wilson", "frank@company.com", "user", "Operations", "+1-555-0106"),
        ("Grace Lee", "grace@company.com", "viewer", "Product", "+1-555-0107"),
        ("Henry Taylor", "henry@company.com", "user", "Sales", "+1-555-0108"),
        ("Iris Anderson", "iris@company.com", "user", "Customer Support", "+1-555-0109"),
        ("Jack Martinez", "jack@company.com", "manager", "Finance", "+1-555-0110"),
        ("Karen Thompson", "karen@company.com", "user", "Engineering", "+1-555-0111"),
        ("Liam Garcia", "liam@company.com", "user", "Marketing", "+1-555-0112"),
        ("Mia Rodriguez", "mia@company.com", "viewer", "Sales", "+1-555-0113"),
        ("Noah Harris", "noah@company.com", "user", "Operations", "+1-555-0114"),
        ("Olivia Clark", "olivia@company.com", "user", "HR", "+1-555-0115"),
    ]
    
    pwd_hash = get_password_hash("password123")
    for user in sample_users:
        cur.execute("""
            INSERT OR IGNORE INTO users (full_name, email, password_hash, role, department, phone, status)
            VALUES (?, ?, ?, ?, ?, ?, 'active')
        """, (*user, pwd_hash))
    logger.info("✅ Sample users seeded")

def _seed_permissions(cur):
    """Seed permissions."""
    permissions = [
        # Users
        ("users.read", "View Users", "users", "Can view user list and profiles"),
        ("users.write", "Create/Edit Users", "users", "Can create and edit users"),
        ("users.delete", "Delete Users", "users", "Can delete users"),
        # Departments
        ("departments.read", "View Departments", "departments", "Can view departments"),
        ("departments.write", "Create/Edit Departments", "departments", "Can manage departments"),
        ("departments.delete", "Delete Departments", "departments", "Can delete departments"),
        # Roles
        ("roles.read", "View Roles", "roles", "Can view roles"),
        ("roles.write", "Manage Roles", "roles", "Can manage roles and permissions"),
        # Reports
        ("reports.read", "View Reports", "reports", "Can view reports"),
        ("reports.export", "Export Reports", "reports", "Can export reports"),
        # Settings
        ("settings.read", "View Settings", "settings", "Can view app settings"),
        ("settings.write", "Manage Settings", "settings", "Can change app settings"),
        # Dashboard
        ("dashboard.read", "View Dashboard", "dashboard", "Can access dashboard"),
        # Audit
        ("audit.read", "View Audit Logs", "audit", "Can view audit logs"),
        # Profile
        ("profile.read", "View Own Profile", "profile", "Can view own profile"),
        ("profile.write", "Edit Own Profile", "profile", "Can edit own profile"),
    ]
    for perm in permissions:
        cur.execute("""
            INSERT OR IGNORE INTO permissions (name, display_name, module, description)
            VALUES (?, ?, ?, ?)
        """, perm)

def _seed_settings(cur):
    """Seed default app settings."""
    app_settings = [
        ("company_name", "Acme Corporation", "string", "Company name", "general", 1),
        ("company_email", "contact@acme.com", "string", "Company contact email", "general", 1),
        ("company_phone", "+1-555-0000", "string", "Company phone", "general", 1),
        ("company_address", "123 Business St, City, Country", "string", "Company address", "general", 1),
        ("max_users", "1000", "integer", "Maximum users allowed", "limits", 0),
        ("session_timeout", "3600", "integer", "Session timeout in seconds", "security", 0),
        ("enable_2fa", "false", "boolean", "Enable 2FA", "security", 0),
        ("enable_audit", "true", "boolean", "Enable audit logging", "security", 0),
        ("date_format", "YYYY-MM-DD", "string", "Date display format", "display", 1),
        ("time_format", "24h", "string", "Time format (12h/24h)", "display", 1),
        ("theme", "light", "string", "App theme", "display", 1),
        ("primary_color", "#0d6efd", "string", "Primary brand color", "display", 1),
        ("items_per_page", "10", "integer", "Items per page", "display", 1),
        ("allow_registration", "false", "boolean", "Allow self-registration", "security", 0),
        ("maintenance_mode", "false", "boolean", "Maintenance mode", "general", 0),
        ("smtp_host", "", "string", "SMTP server host", "email", 0),
        ("smtp_port", "587", "integer", "SMTP port", "email", 0),
        ("smtp_user", "", "string", "SMTP username", "email", 0),
        ("smtp_from", "noreply@acme.com", "string", "From email address", "email", 0),
        ("backup_enabled", "true", "boolean", "Enable automatic backups", "backup", 0),
    ]
    for s in app_settings:
        cur.execute("""
            INSERT OR IGNORE INTO app_settings (key, value, type, description, group_name, is_public)
            VALUES (?, ?, ?, ?, ?, ?)
        """, s)
EOF

echo "✅ Database init created"

echo ""
echo "📦 PART 1 COMPLETE!"
#!/bin/bash
# ============================================================
# FASTAPI ENTERPRISE APP - SETUP SCRIPT PART 2
# Creates: Services, Middleware, Models, Schemas
# ============================================================

PROJECT="enterprise_app"

# ─── app/services/nav_service.py ──────────────────────────
cat > $PROJECT/app/services/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/services/nav_service.py <<'EOF'
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
EOF

# ─── app/services/user_service.py ─────────────────────────
cat > $PROJECT/app/services/user_service.py <<'EOF'
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
EOF

# ─── app/services/audit_service.py ────────────────────────
cat > $PROJECT/app/services/audit_service.py <<'EOF'
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
EOF

# ─── app/services/department_service.py ───────────────────
cat > $PROJECT/app/services/department_service.py <<'EOF'
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
EOF

echo "✅ Services created"

# ─── app/services/auth_service.py ─────────────────────────
cat > $PROJECT/app/services/auth_service.py <<'EOF'
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
EOF

# ─── app/services/dashboard_service.py ────────────────────
cat > $PROJECT/app/services/dashboard_service.py <<'EOF'
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
EOF

echo "✅ All services created"
echo ""
echo "📦 PART 2 COMPLETE!"
#!/bin/bash
# ============================================================
# FASTAPI ENTERPRISE APP - SETUP SCRIPT PART 3
# Creates: API Routes, Main App, Schemas
# ============================================================

PROJECT="enterprise_app"

# ─── app/schemas/ ──────────────────────────────────────────
cat > $PROJECT/app/schemas/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/schemas/users.py <<'EOF'
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: Optional[str] = "changeme123"
    role: str = "user"
    department: Optional[str] = None
    department_id: Optional[int] = None
    phone: Optional[str] = None
    status: str = "active"


class UserUpdate(BaseModel):
    full_name: str
    email: EmailStr
    role: str
    department: Optional[str] = None
    department_id: Optional[int] = None
    phone: Optional[str] = None
    status: str = "active"


class UserRead(BaseModel):
    id: int
    full_name: str
    email: str
    role: str
    department: Optional[str] = None
    phone: Optional[str] = None
    status: str
    last_login: Optional[str] = None
    created_at: Optional[str] = None


class UserList(BaseModel):
    items: list
    total: int
    page: int
    per_page: int
    total_pages: int
    has_prev: bool
    has_next: bool


class PasswordChange(BaseModel):
    current_password: str
    new_password: str
    confirm_password: str
EOF

cat > $PROJECT/app/schemas/departments.py <<'EOF'
from pydantic import BaseModel
from typing import Optional


class DepartmentCreate(BaseModel):
    name: str
    code: Optional[str] = None
    description: Optional[str] = None
    head_user_id: Optional[int] = None
    budget: Optional[float] = 0.0
    location: Optional[str] = None
    status: str = "active"


class DepartmentUpdate(DepartmentCreate):
    pass


class DepartmentRead(BaseModel):
    id: int
    name: str
    code: Optional[str]
    description: Optional[str]
    budget: Optional[float]
    location: Optional[str]
    status: str
    user_count: Optional[int] = 0
    created_at: Optional[str]
EOF

cat > $PROJECT/app/schemas/auth.py <<'EOF'
from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    remember_me: bool = False


class LoginResponse(BaseModel):
    success: bool
    message: str
    redirect: str = "/"
EOF

echo "✅ Schemas created"

# ─── app/middleware/ ────────────────────────────────────────
cat > $PROJECT/app/middleware/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/middleware/auth.py <<'EOF'
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
EOF

echo "✅ Middleware created"

# ─── app/utils/ ────────────────────────────────────────────
cat > $PROJECT/app/utils/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/utils/helpers.py <<'EOF'
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
EOF

echo "✅ Utils created"

# ─── app/api/v1/routes/__init__.py ────────────────────────
cat > $PROJECT/app/api/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/api/v1/__init__.py <<'EOF'
EOF

cat > $PROJECT/app/api/v1/routes/__init__.py <<'EOF'
EOF

# ─── app/api/v1/routes/auth.py ────────────────────────────
cat > $PROJECT/app/api/v1/routes/auth.py <<'EOF'
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
EOF

# ─── app/api/v1/routes/dashboard.py ───────────────────────
cat > $PROJECT/app/api/v1/routes/dashboard.py <<'EOF'
from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.dashboard_service import DashboardService
from app.services.nav_service import nav_items

router = APIRouter(tags=["dashboard"])


@router.get("/", response_class=HTMLResponse)
def dashboard(request: Request):
    from app.main import templates
    user = AuthService.get_session_user(request)
    if not user:
        return RedirectResponse(url="/login", status_code=302)
    
    stats = DashboardService.get_overview_stats()
    
    return templates.TemplateResponse(
        "dashboard/index.html",
        {
            "request": request,
            "nav": nav_items("dashboard", user.get("role", "user")),
            "page_title": "Dashboard",
            "current_user": user,
            "stats": stats,
        }
    )


@router.get("/health")
def health():
    return {"status": "ok", "service": "Enterprise Manager API"}
EOF

# ─── app/api/v1/routes/users.py ───────────────────────────
cat > $PROJECT/app/api/v1/routes/users.py <<'EOF'
from fastapi import APIRouter, Request, Form, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse, Response
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.department_service import DepartmentService
from app.services.nav_service import nav_items, get_breadcrumb

router = APIRouter(tags=["users"])


def _check_auth(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(status_code=302, headers={"Location": "/login"})
    return user


@router.get("/users", response_class=HTMLResponse)
def users_list(
    request: Request,
    page: int = Query(1, ge=1),
    search: str = Query(""),
    role: str = Query(""),
    department: str = Query(""),
    status: str = Query(""),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    data = UserService.get_all(
        page=page, per_page=10, search=search,
        role=role, department=department, status=status
    )
    depts = DepartmentService.get_all_simple()
    
    return templates.TemplateResponse("users/index.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", None)),
        "page_title": "Users",
        "current_user": current_user,
        "data": data,
        "depts": depts,
        "filters": {"search": search, "role": role, "department": department, "status": status},
    })


@router.get("/users/new", response_class=HTMLResponse)
def create_user_page(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    depts = DepartmentService.get_all_simple()
    
    return templates.TemplateResponse("users/form.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", "/users"), ("New User", None)),
        "page_title": "Create User",
        "current_user": current_user,
        "user": None,
        "depts": depts,
        "error": None,
    })


@router.post("/users/create")
async def create_user(
    request: Request,
    full_name: str = Form(...),
    email: str = Form(...),
    role: str = Form("user"),
    department: str = Form(""),
    department_id: str = Form(""),
    phone: str = Form(""),
    status: str = Form("active"),
    password: str = Form("changeme123"),
):
    from app.main import templates
    current_user = _check_auth(request)
    depts = DepartmentService.get_all_simple()
    
    try:
        user_id = UserService.create({
            "full_name": full_name,
            "email": email,
            "role": role,
            "department": department,
            "department_id": int(department_id) if department_id else None,
            "phone": phone,
            "status": status,
            "password": password,
        }, created_by=current_user["id"])
        return RedirectResponse(url=f"/users/{user_id}?success=created", status_code=303)
    except ValueError as e:
        return templates.TemplateResponse("users/form.html", {
            "request": request,
            "nav": nav_items("users", current_user.get("role")),
            "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", "/users"), ("New User", None)),
            "page_title": "Create User",
            "current_user": current_user,
            "user": {"full_name": full_name, "email": email, "role": role,
                     "department": department, "phone": phone, "status": status},
            "depts": depts,
            "error": str(e),
        }, status_code=400)


@router.get("/users/{user_id}", response_class=HTMLResponse)
def user_detail(request: Request, user_id: int, success: str = ""):
    from app.main import templates
    current_user = _check_auth(request)
    
    user = UserService.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return templates.TemplateResponse("users/detail.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(("Home", "/"), ("Users", "/users"), (user["full_name"], None)),
        "page_title": user["full_name"],
        "current_user": current_user,
        "user": user,
        "success": success,
    })


@router.get("/users/{user_id}/edit", response_class=HTMLResponse)
def edit_user_page(request: Request, user_id: int):
    from app.main import templates
    current_user = _check_auth(request)
    
    user = UserService.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    depts = DepartmentService.get_all_simple()
    
    return templates.TemplateResponse("users/form.html", {
        "request": request,
        "nav": nav_items("users", current_user.get("role")),
        "breadcrumb": get_breadcrumb(
            ("Home", "/"), ("Users", "/users"),
            (user["full_name"], f"/users/{user_id}"), ("Edit", None)
        ),
        "page_title": f"Edit – {user['full_name']}",
        "current_user": current_user,
        "user": user,
        "depts": depts,
        "error": None,
    })


@router.post("/users/{user_id}/update")
async def update_user(
    request: Request,
    user_id: int,
    full_name: str = Form(...),
    email: str = Form(...),
    role: str = Form("user"),
    department: str = Form(""),
    department_id: str = Form(""),
    phone: str = Form(""),
    status: str = Form("active"),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    try:
        UserService.update(user_id, {
            "full_name": full_name,
            "email": email,
            "role": role,
            "department": department,
            "department_id": int(department_id) if department_id else None,
            "phone": phone,
            "status": status,
        }, updated_by=current_user["id"])
        return RedirectResponse(url=f"/users/{user_id}?success=updated", status_code=303)
    except ValueError as e:
        user = UserService.get_by_id(user_id)
        depts = DepartmentService.get_all_simple()
        return templates.TemplateResponse("users/form.html", {
            "request": request,
            "nav": nav_items("users", current_user.get("role")),
            "page_title": "Edit User",
            "current_user": current_user,
            "user": user,
            "depts": depts,
            "error": str(e),
        }, status_code=400)


@router.post("/users/{user_id}/delete")
def delete_user(request: Request, user_id: int):
    current_user = _check_auth(request)
    
    try:
        UserService.delete(user_id, deleted_by=current_user["id"])
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    return RedirectResponse(url="/users?success=deleted", status_code=303)


@router.post("/users/{user_id}/toggle-status")
def toggle_user_status(request: Request, user_id: int):
    current_user = _check_auth(request)
    new_status = UserService.toggle_status(user_id, actor_id=current_user["id"])
    return RedirectResponse(url=f"/users/{user_id}", status_code=303)


@router.get("/users/export/csv")
def export_users_csv(request: Request):
    current_user = _check_auth(request)
    csv_data = UserService.export_csv()
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users.csv"}
    )
EOF

# ─── app/api/v1/routes/departments.py ─────────────────────
cat > $PROJECT/app/api/v1/routes/departments.py <<'EOF'
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
EOF

# ─── app/api/v1/routes/reports.py ─────────────────────────
cat > $PROJECT/app/api/v1/routes/reports.py <<'EOF'
from fastapi import APIRouter, Request, Query, Response
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.department_service import DepartmentService
from app.services.nav_service import nav_items

router = APIRouter(tags=["reports"])


def _check_auth(request: Request):
    from fastapi import HTTPException
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    return user


@router.get("/reports", response_class=HTMLResponse)
def reports_index(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    
    user_stats = UserService.get_stats()
    dept_stats = DepartmentService.get_stats()
    
    return templates.TemplateResponse("reports/index.html", {
        "request": request,
        "nav": nav_items("reports", current_user.get("role")),
        "page_title": "Reports",
        "current_user": current_user,
        "user_stats": user_stats,
        "dept_stats": dept_stats,
    })


@router.get("/reports/users/export")
def export_users(request: Request):
    current_user = _check_auth(request)
    csv_data = UserService.export_csv()
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users_report.csv"}
    )
EOF

# ─── app/api/v1/routes/audit.py ───────────────────────────
cat > $PROJECT/app/api/v1/routes/audit.py <<'EOF'
from fastapi import APIRouter, Request, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.services.audit_service import get_audit_logs
from app.services.nav_service import nav_items

router = APIRouter(tags=["audit"])


def _check_auth(request: Request):
    from fastapi import HTTPException
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    return user


@router.get("/audit", response_class=HTMLResponse)
def audit_logs(
    request: Request,
    page: int = Query(1, ge=1),
    module: str = Query(""),
    action: str = Query(""),
    date_from: str = Query(""),
    date_to: str = Query(""),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    if current_user.get("role") != "admin":
        return RedirectResponse(url="/", status_code=302)
    
    data = get_audit_logs(
        page=page, per_page=20,
        module=module, action=action,
        date_from=date_from, date_to=date_to
    )
    
    return templates.TemplateResponse("audit/index.html", {
        "request": request,
        "nav": nav_items("audit", current_user.get("role")),
        "page_title": "Audit Logs",
        "current_user": current_user,
        "data": data,
        "filters": {"module": module, "action": action, "date_from": date_from, "date_to": date_to},
    })
EOF

# ─── app/api/v1/routes/settings.py ────────────────────────
cat > $PROJECT/app/api/v1/routes/settings.py <<'EOF'
from fastapi import APIRouter, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.db.database import get_connection
from app.services.nav_service import nav_items

router = APIRouter(tags=["settings"])


def _check_auth_admin(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    if user.get("role") != "admin":
        raise HTTPException(403, detail="Admin only")
    return user


@router.get("/settings", response_class=HTMLResponse)
def settings_page(request: Request):
    from app.main import templates
    current_user = _check_auth_admin(request)
    
    conn = get_connection()
    raw_settings = conn.execute("SELECT * FROM app_settings ORDER BY group_name, key").fetchall()
    conn.close()
    
    grouped = {}
    for s in raw_settings:
        s = dict(s)
        g = s["group_name"] or "general"
        grouped.setdefault(g, []).append(s)
    
    return templates.TemplateResponse("settings/index.html", {
        "request": request,
        "nav": nav_items("settings", current_user.get("role")),
        "page_title": "Settings",
        "current_user": current_user,
        "grouped_settings": grouped,
        "success": request.query_params.get("success", ""),
    })


@router.post("/settings/update")
async def update_settings(request: Request):
    current_user = _check_auth_admin(request)
    form = await request.form()
    
    conn = get_connection()
    cur = conn.cursor()
    
    for key, value in form.items():
        cur.execute(
            "UPDATE app_settings SET value = ? WHERE key = ?",
            (str(value), key)
        )
    
    conn.commit()
    conn.close()
    
    return RedirectResponse(url="/settings?success=1", status_code=303)
EOF

# ─── app/api/v1/routes/roles.py ───────────────────────────
cat > $PROJECT/app/api/v1/routes/roles.py <<'EOF'
from fastapi import APIRouter, Request, Form, HTTPException, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from app.services.auth_service import AuthService
from app.db.database import get_connection
from app.services.nav_service import nav_items
from datetime import datetime

router = APIRouter(tags=["roles"])


def _check_auth(request: Request):
    user = AuthService.get_session_user(request)
    if not user:
        raise HTTPException(302, headers={"Location": "/login"})
    if user.get("role") != "admin":
        raise HTTPException(403, detail="Admin only")
    return user


@router.get("/roles", response_class=HTMLResponse)
def roles_list(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    
    conn = get_connection()
    roles = conn.execute("""
        SELECT r.*, COUNT(u.id) as user_count
        FROM roles r
        LEFT JOIN users u ON u.role = r.name
        GROUP BY r.id
        ORDER BY r.id
    """).fetchall()
    conn.close()
    
    return templates.TemplateResponse("roles/index.html", {
        "request": request,
        "nav": nav_items("roles", current_user.get("role")),
        "page_title": "Roles & Permissions",
        "current_user": current_user,
        "roles": [dict(r) for r in roles],
    })


@router.get("/roles/new", response_class=HTMLResponse)
def new_role_page(request: Request):
    from app.main import templates
    current_user = _check_auth(request)
    
    return templates.TemplateResponse("roles/form.html", {
        "request": request,
        "nav": nav_items("roles", current_user.get("role")),
        "page_title": "New Role",
        "current_user": current_user,
        "role": None,
        "error": None,
    })


@router.post("/roles/create")
async def create_role(
    request: Request,
    name: str = Form(...),
    display_name: str = Form(...),
    description: str = Form(""),
    status: str = Form("active"),
):
    from app.main import templates
    current_user = _check_auth(request)
    
    conn = get_connection()
    cur = conn.cursor()
    
    exists = cur.execute("SELECT id FROM roles WHERE name = ?", (name,)).fetchone()
    if exists:
        conn.close()
        return templates.TemplateResponse("roles/form.html", {
            "request": request,
            "nav": nav_items("roles", current_user.get("role")),
            "page_title": "New Role",
            "current_user": current_user,
            "role": {"name": name, "display_name": display_name, "description": description},
            "error": f"Role '{name}' already exists",
        }, status_code=400)
    
    now = datetime.utcnow().isoformat()
    cur.execute("""
        INSERT INTO roles (name, display_name, description, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (name, display_name, description, status, now, now))
    
    conn.commit()
    conn.close()
    
    return RedirectResponse(url="/roles", status_code=303)


@router.post("/roles/{role_id}/delete")
def delete_role(request: Request, role_id: int):
    current_user = _check_auth(request)
    
    conn = get_connection()
    cur = conn.cursor()
    
    role = cur.execute("SELECT * FROM roles WHERE id = ?", (role_id,)).fetchone()
    if not role:
        conn.close()
        raise HTTPException(404, detail="Role not found")
    
    if dict(role)["is_system"]:
        conn.close()
        raise HTTPException(400, detail="Cannot delete system roles")
    
    cur.execute("DELETE FROM roles WHERE id = ?", (role_id,))
    conn.commit()
    conn.close()
    
    return RedirectResponse(url="/roles", status_code=303)
EOF

echo "✅ All routes created"
echo ""
echo "📦 PART 3 COMPLETE!"
#!/bin/bash
# ============================================================
# FASTAPI ENTERPRISE APP - SETUP SCRIPT PART 4
# Creates: Jinja2 HTML Templates
# ============================================================

PROJECT="enterprise_app"

# ─── templates/base.html ──────────────────────────────────
cat > $PROJECT/templates/base.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en" data-bs-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}{{ page_title }} | Enterprise Manager{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/feather-icons/dist/feather.min.css" rel="stylesheet">
    <link rel="stylesheet" href="/static/css/main.css">
    {% block extra_head %}{% endblock %}
</head>
<body>

{% if current_user %}
<!-- Sidebar -->
<div class="sidebar d-flex flex-column">
    <div class="sidebar-brand">
        <span class="brand-icon">⚡</span>
        <span class="brand-text">Enterprise<br><small>Manager</small></span>
    </div>
    
    <nav class="sidebar-nav flex-grow-1">
        {% for item in nav %}
        <a href="{{ item.url }}" class="nav-link {% if item.is_active %}active{% endif %}">
            <i data-feather="{{ item.icon }}" class="nav-icon"></i>
            <span>{{ item.label }}</span>
        </a>
        {% endfor %}
    </nav>
    
    <div class="sidebar-footer">
        <div class="user-info">
            <div class="user-avatar">{{ current_user.full_name[:2].upper() }}</div>
            <div class="user-details">
                <div class="user-name">{{ current_user.full_name }}</div>
                <div class="user-role badge bg-secondary">{{ current_user.role }}</div>
            </div>
        </div>
        <a href="/logout" class="btn btn-sm btn-outline-danger w-100 mt-2">
            <i data-feather="log-out" style="width:14px;height:14px"></i> Logout
        </a>
    </div>
</div>

<!-- Main Content -->
<div class="main-content">
    <!-- Top Bar -->
    <div class="topbar">
        <div class="d-flex align-items-center gap-3">
            {% if breadcrumb %}
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0">
                    {% for crumb in breadcrumb %}
                    {% if loop.last %}
                    <li class="breadcrumb-item active">{{ crumb.label }}</li>
                    {% else %}
                    <li class="breadcrumb-item"><a href="{{ crumb.url }}">{{ crumb.label }}</a></li>
                    {% endif %}
                    {% endfor %}
                </ol>
            </nav>
            {% else %}
            <h5 class="mb-0 fw-semibold">{{ page_title }}</h5>
            {% endif %}
        </div>
        <div class="d-flex align-items-center gap-2">
            <a href="/profile" class="btn btn-sm btn-light">
                <i data-feather="user" style="width:14px;height:14px"></i> Profile
            </a>
        </div>
    </div>
    
    <!-- Page Content -->
    <div class="page-content">
        {% block content %}{% endblock %}
    </div>
</div>

{% else %}
{% block auth_content %}{% endblock %}
{% endif %}

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/feather-icons/dist/feather.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>
<script src="/static/js/main.js"></script>
<script>feather.replace();</script>
{% block extra_scripts %}{% endblock %}
</body>
</html>
HTMLEOF

# ─── templates/auth/login.html ────────────────────────────
cat > $PROJECT/templates/auth/login.html <<'HTMLEOF'
{% extends "base.html" %}

{% block auth_content %}
<div class="login-wrapper">
    <div class="login-card">
        <div class="login-header">
            <div class="login-icon">⚡</div>
            <h2>Enterprise Manager</h2>
            <p class="text-muted">Sign in to your account</p>
        </div>
        
        {% if error %}
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            <i data-feather="alert-circle" style="width:16px;height:16px"></i>
            {{ error }}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        {% endif %}
        
        <form method="POST" action="/login">
            <input type="hidden" name="next_url" value="{{ next }}">
            
            <div class="mb-3">
                <label class="form-label">Email Address</label>
                <div class="input-group">
                    <span class="input-group-text"><i data-feather="mail" style="width:16px;height:16px"></i></span>
                    <input type="email" name="email" class="form-control" 
                           value="{{ email or '' }}" required placeholder="admin@company.com" autofocus>
                </div>
            </div>
            
            <div class="mb-3">
                <label class="form-label">Password</label>
                <div class="input-group">
                    <span class="input-group-text"><i data-feather="lock" style="width:16px;height:16px"></i></span>
                    <input type="password" name="password" class="form-control" 
                           required placeholder="••••••••" id="password-field">
                    <button type="button" class="btn btn-outline-secondary" onclick="togglePassword()">
                        <i data-feather="eye" style="width:14px;height:14px" id="eye-icon"></i>
                    </button>
                </div>
            </div>
            
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div class="form-check">
                    <input type="checkbox" name="remember_me" class="form-check-input" id="remember" value="1">
                    <label class="form-check-label" for="remember">Remember me</label>
                </div>
            </div>
            
            <button type="submit" class="btn btn-primary w-100 btn-lg">
                <i data-feather="log-in" style="width:16px;height:16px"></i>
                Sign In
            </button>
        </form>
        
        <div class="login-footer mt-3 text-center text-muted small">
            <p class="mb-0">Demo: <code>admin@company.com</code> / <code>admin123</code></p>
        </div>
    </div>
</div>

<script>
function togglePassword() {
    const field = document.getElementById('password-field');
    const icon = document.getElementById('eye-icon');
    if (field.type === 'password') {
        field.type = 'text';
        icon.setAttribute('data-feather', 'eye-off');
    } else {
        field.type = 'password';
        icon.setAttribute('data-feather', 'eye');
    }
    feather.replace();
}
</script>
{% endblock %}
HTMLEOF

# ─── templates/auth/profile.html ──────────────────────────
cat > $PROJECT/templates/auth/profile.html <<'HTMLEOF'
{% extends "base.html" %}

{% block content %}
<div class="row">
    <div class="col-lg-4 mb-4">
        <div class="card">
            <div class="card-body text-center py-4">
                <div class="avatar-xl mx-auto mb-3">
                    {{ user.full_name[:2].upper() }}
                </div>
                <h4 class="mb-1">{{ user.full_name }}</h4>
                <p class="text-muted mb-2">{{ user.email }}</p>
                <span class="badge bg-primary">{{ user.role | title }}</span>
                {% if user.department %}
                <span class="badge bg-secondary">{{ user.department }}</span>
                {% endif %}
            </div>
        </div>
    </div>
    
    <div class="col-lg-8">
        <div class="card mb-4">
            <div class="card-header">
                <h5 class="card-title mb-0">Account Information</h5>
            </div>
            <div class="card-body">
                <table class="table table-borderless">
                    <tr>
                        <th width="35%" class="text-muted">Full Name</th>
                        <td>{{ user.full_name }}</td>
                    </tr>
                    <tr>
                        <th class="text-muted">Email</th>
                        <td>{{ user.email }}</td>
                    </tr>
                    <tr>
                        <th class="text-muted">Role</th>
                        <td><span class="badge bg-primary">{{ user.role | title }}</span></td>
                    </tr>
                    <tr>
                        <th class="text-muted">Department</th>
                        <td>{{ user.department or "—" }}</td>
                    </tr>
                    <tr>
                        <th class="text-muted">Phone</th>
                        <td>{{ user.phone or "—" }}</td>
                    </tr>
                    <tr>
                        <th class="text-muted">Status</th>
                        <td>
                            <span class="badge bg-{{ 'success' if user.status == 'active' else 'secondary' }}">
                                {{ user.status | title }}
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <th class="text-muted">Last Login</th>
                        <td>{{ user.last_login or "—" }}</td>
                    </tr>
                    <tr>
                        <th class="text-muted">Member Since</th>
                        <td>{{ user.created_at[:10] if user.created_at else "—" }}</td>
                    </tr>
                </table>
            </div>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/dashboard/index.html ───────────────────────
cat > $PROJECT/templates/dashboard/index.html <<'HTMLEOF'
{% extends "base.html" %}

{% block content %}
<!-- Stats Row -->
<div class="row g-3 mb-4">
    <div class="col-6 col-lg-3">
        <div class="stat-card stat-card-blue">
            <div class="stat-icon"><i data-feather="users"></i></div>
            <div class="stat-value">{{ stats.total_users }}</div>
            <div class="stat-label">Total Users</div>
            <div class="stat-sub">{{ stats.active_users }} active</div>
        </div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="stat-card stat-card-green">
            <div class="stat-icon"><i data-feather="briefcase"></i></div>
            <div class="stat-value">{{ stats.total_departments }}</div>
            <div class="stat-label">Departments</div>
            <div class="stat-sub">All active</div>
        </div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="stat-card stat-card-orange">
            <div class="stat-icon"><i data-feather="user-plus"></i></div>
            <div class="stat-value">{{ stats.new_users_30d }}</div>
            <div class="stat-label">New This Month</div>
            <div class="stat-sub">Last 30 days</div>
        </div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="stat-card stat-card-purple">
            <div class="stat-icon"><i data-feather="shield"></i></div>
            <div class="stat-value">{{ stats.total_roles }}</div>
            <div class="stat-label">Roles</div>
            <div class="stat-sub">{{ stats.logins_7d }} logins/week</div>
        </div>
    </div>
</div>

<!-- Charts Row -->
<div class="row g-3 mb-4">
    <div class="col-lg-8">
        <div class="card h-100">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h6 class="card-title mb-0">Monthly User Signups</h6>
                <span class="badge bg-light text-dark">Last 6 Months</span>
            </div>
            <div class="card-body">
                <canvas id="monthlyChart" height="250"></canvas>
            </div>
        </div>
    </div>
    <div class="col-lg-4">
        <div class="card h-100">
            <div class="card-header">
                <h6 class="card-title mb-0">Users by Role</h6>
            </div>
            <div class="card-body d-flex align-items-center justify-content-center">
                <canvas id="roleChart" height="220"></canvas>
            </div>
        </div>
    </div>
</div>

<!-- Bottom Row -->
<div class="row g-3">
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h6 class="card-title mb-0">Users by Department</h6>
                <a href="/users" class="btn btn-sm btn-outline-primary">View All</a>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Department</th>
                                <th>Users</th>
                                <th>Progress</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for d in stats.by_dept %}
                            <tr>
                                <td>{{ d.department or "Unknown" }}</td>
                                <td><span class="badge bg-primary">{{ d.count }}</span></td>
                                <td width="40%">
                                    <div class="progress" style="height:6px">
                                        <div class="progress-bar" style="width:{{ ((d.count / stats.total_users) * 100) | int }}%"></div>
                                    </div>
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-lg-4">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h6 class="card-title mb-0">Recent Activity</h6>
            </div>
            <div class="card-body p-0">
                <div class="activity-list">
                    {% for item in stats.activity %}
                    <div class="activity-item">
                        <div class="activity-icon bg-{{ item.color or 'primary' }}">
                            <i data-feather="{{ item.icon or 'activity' }}" style="width:14px;height:14px"></i>
                        </div>
                        <div class="activity-details">
                            <div class="activity-text small">{{ item.description }}</div>
                            <div class="activity-time text-muted" style="font-size:11px">{{ item.created_at[:16] if item.created_at else "" }}</div>
                        </div>
                    </div>
                    {% endfor %}
                    {% if not stats.activity %}
                    <div class="p-3 text-center text-muted small">No activity yet</div>
                    {% endif %}
                </div>
            </div>
        </div>
    </div>
</div>

<script>
const monthly = {{ stats.monthly_signups | tojson }};
const byRole  = {{ stats.by_role | tojson }};

// Monthly chart
new Chart(document.getElementById('monthlyChart'), {
    type: 'bar',
    data: {
        labels: monthly.map(m => m.month),
        datasets: [{
            label: 'New Users',
            data: monthly.map(m => m.count),
            backgroundColor: 'rgba(13,110,253,0.7)',
            borderRadius: 6,
        }]
    },
    options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
});

// Role pie chart
new Chart(document.getElementById('roleChart'), {
    type: 'doughnut',
    data: {
        labels: byRole.map(r => r.role),
        datasets: [{
            data: byRole.map(r => r.count),
            backgroundColor: ['#dc3545','#fd7e14','#0d6efd','#6c757d','#20c997'],
            borderWidth: 2,
        }]
    },
    options: { responsive: true, plugins: { legend: { position: 'bottom' } } }
});
</script>
{% endblock %}
HTMLEOF

# ─── templates/users/index.html ───────────────────────────
cat > $PROJECT/templates/users/index.html <<'HTMLEOF'
{% extends "base.html" %}

{% block content %}
<!-- Header -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="mb-0">Users</h4>
        <p class="text-muted mb-0 small">{{ data.total }} total users</p>
    </div>
    <div class="d-flex gap-2">
        <a href="/users/export/csv" class="btn btn-outline-secondary btn-sm">
            <i data-feather="download" style="width:14px;height:14px"></i> Export CSV
        </a>
        <a href="/users/new" class="btn btn-primary btn-sm">
            <i data-feather="plus" style="width:14px;height:14px"></i> New User
        </a>
    </div>
</div>

<!-- Filters -->
<div class="card mb-3">
    <div class="card-body py-2">
        <form method="GET" class="row g-2 align-items-end">
            <div class="col-md-4">
                <input type="text" name="search" class="form-control form-control-sm" 
                       placeholder="Search name, email..." value="{{ filters.search }}">
            </div>
            <div class="col-md-2">
                <select name="role" class="form-select form-select-sm">
                    <option value="">All Roles</option>
                    {% for r in ['admin','manager','hr','user','viewer'] %}
                    <option value="{{ r }}" {% if filters.role == r %}selected{% endif %}>{{ r | title }}</option>
                    {% endfor %}
                </select>
            </div>
            <div class="col-md-3">
                <select name="department" class="form-select form-select-sm">
                    <option value="">All Departments</option>
                    {% for d in depts %}
                    <option value="{{ d.name }}" {% if filters.department == d.name %}selected{% endif %}>{{ d.name }}</option>
                    {% endfor %}
                </select>
            </div>
            <div class="col-md-2">
                <select name="status" class="form-select form-select-sm">
                    <option value="">All Status</option>
                    <option value="active" {% if filters.status == 'active' %}selected{% endif %}>Active</option>
                    <option value="inactive" {% if filters.status == 'inactive' %}selected{% endif %}>Inactive</option>
                </select>
            </div>
            <div class="col-md-1 d-flex gap-1">
                <button type="submit" class="btn btn-primary btn-sm">Go</button>
                <a href="/users" class="btn btn-outline-secondary btn-sm">✕</a>
            </div>
        </form>
    </div>
</div>

<!-- Users Table -->
<div class="card">
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>User</th>
                    <th>Role</th>
                    <th>Department</th>
                    <th>Status</th>
                    <th>Joined</th>
                    <th class="text-end">Actions</th>
                </tr>
            </thead>
            <tbody>
                {% for user in data.items %}
                <tr>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <div class="avatar-sm">{{ user.full_name[:2].upper() }}</div>
                            <div>
                                <a href="/users/{{ user.id }}" class="fw-semibold text-decoration-none">
                                    {{ user.full_name }}
                                </a>
                                <div class="text-muted small">{{ user.email }}</div>
                            </div>
                        </div>
                    </td>
                    <td>
                        <span class="badge bg-{{ {'admin':'danger','manager':'warning','hr':'info','user':'primary','viewer':'secondary'}.get(user.role, 'secondary') }}">
                            {{ user.role | title }}
                        </span>
                    </td>
                    <td>{{ user.department or "—" }}</td>
                    <td>
                        <span class="badge bg-{{ 'success' if user.status == 'active' else 'secondary' }}">
                            {{ user.status | title }}
                        </span>
                    </td>
                    <td class="text-muted small">{{ user.created_at[:10] if user.created_at else "—" }}</td>
                    <td class="text-end">
                        <div class="btn-group btn-group-sm">
                            <a href="/users/{{ user.id }}" class="btn btn-outline-secondary" title="View">
                                <i data-feather="eye" style="width:14px;height:14px"></i>
                            </a>
                            <a href="/users/{{ user.id }}/edit" class="btn btn-outline-primary" title="Edit">
                                <i data-feather="edit-2" style="width:14px;height:14px"></i>
                            </a>
                            <button class="btn btn-outline-danger" title="Delete"
                                onclick="confirmDelete('/users/{{ user.id }}/delete', '{{ user.full_name }}')">
                                <i data-feather="trash-2" style="width:14px;height:14px"></i>
                            </button>
                        </div>
                    </td>
                </tr>
                {% else %}
                <tr>
                    <td colspan="6" class="text-center py-4 text-muted">No users found</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
</div>

{% include "partials/pagination.html" %}
{% endblock %}
HTMLEOF

# ─── templates/users/detail.html ──────────────────────────
cat > $PROJECT/templates/users/detail.html <<'HTMLEOF'
{% extends "base.html" %}

{% block content %}
{% if success %}
<div class="alert alert-success alert-dismissible fade show" role="alert">
    ✅ User {{ 'created' if success == 'created' else 'updated' }} successfully!
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
{% endif %}

<div class="row g-3">
    <div class="col-lg-4">
        <div class="card">
            <div class="card-body text-center py-4">
                <div class="avatar-xl mx-auto mb-3">{{ user.full_name[:2].upper() }}</div>
                <h5 class="mb-1">{{ user.full_name }}</h5>
                <p class="text-muted mb-2 small">{{ user.email }}</p>
                <div class="d-flex justify-content-center gap-1 flex-wrap">
                    <span class="badge bg-{{ {'admin':'danger','manager':'warning','hr':'info','user':'primary','viewer':'secondary'}.get(user.role,'secondary') }}">
                        {{ user.role | title }}
                    </span>
                    <span class="badge bg-{{ 'success' if user.status=='active' else 'secondary' }}">
                        {{ user.status | title }}
                    </span>
                </div>
                <div class="d-flex gap-2 justify-content-center mt-3">
                    <a href="/users/{{ user.id }}/edit" class="btn btn-primary btn-sm">
                        <i data-feather="edit-2" style="width:14px;height:14px"></i> Edit
                    </a>
                    <form method="POST" action="/users/{{ user.id }}/toggle-status" class="d-inline">
                        <button class="btn btn-outline-secondary btn-sm">
                            {% if user.status == 'active' %}Deactivate{% else %}Activate{% endif %}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><h6 class="card-title mb-0">User Details</h6></div>
            <div class="card-body">
                <dl class="row mb-0">
                    <dt class="col-sm-4 text-muted">Full Name</dt>
                    <dd class="col-sm-8">{{ user.full_name }}</dd>
                    <dt class="col-sm-4 text-muted">Email</dt>
                    <dd class="col-sm-8">{{ user.email }}</dd>
                    <dt class="col-sm-4 text-muted">Role</dt>
                    <dd class="col-sm-8">{{ user.role | title }}</dd>
                    <dt class="col-sm-4 text-muted">Department</dt>
                    <dd class="col-sm-8">{{ user.department or "—" }}</dd>
                    <dt class="col-sm-4 text-muted">Phone</dt>
                    <dd class="col-sm-8">{{ user.phone or "—" }}</dd>
                    <dt class="col-sm-4 text-muted">Status</dt>
                    <dd class="col-sm-8">
                        <span class="badge bg-{{ 'success' if user.status=='active' else 'secondary' }}">
                            {{ user.status | title }}
                        </span>
                    </dd>
                    <dt class="col-sm-4 text-muted">Last Login</dt>
                    <dd class="col-sm-8">{{ user.last_login[:16] if user.last_login else "Never" }}</dd>
                    <dt class="col-sm-4 text-muted">Login Count</dt>
                    <dd class="col-sm-8">{{ user.login_count or 0 }}</dd>
                    <dt class="col-sm-4 text-muted">Created</dt>
                    <dd class="col-sm-8">{{ user.created_at[:10] if user.created_at else "—" }}</dd>
                    <dt class="col-sm-4 text-muted">API Key</dt>
                    <dd class="col-sm-8"><code class="small">{{ user.api_key or "—" }}</code></dd>
                </dl>
            </div>
        </div>
        
        <div class="mt-3">
            <button onclick="confirmDelete('/users/{{ user.id }}/delete', '{{ user.full_name }}')" 
                    class="btn btn-outline-danger btn-sm">
                <i data-feather="trash-2" style="width:14px;height:14px"></i> Delete User
            </button>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/users/form.html ────────────────────────────
cat > $PROJECT/templates/users/form.html <<'HTMLEOF'
{% extends "base.html" %}

{% block content %}
<div class="row justify-content-center">
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header">
                <h5 class="card-title mb-0">{{ 'Edit User' if user and user.id else 'Create New User' }}</h5>
            </div>
            <div class="card-body">
                {% if error %}
                <div class="alert alert-danger">{{ error }}</div>
                {% endif %}
                
                <form method="POST" action="{{ '/users/' + user.id|string + '/update' if user and user.id else '/users/create' }}">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label">Full Name <span class="text-danger">*</span></label>
                            <input type="text" name="full_name" class="form-control" 
                                   value="{{ user.full_name if user else '' }}" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Email <span class="text-danger">*</span></label>
                            <input type="email" name="email" class="form-control" 
                                   value="{{ user.email if user else '' }}" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Role</label>
                            <select name="role" class="form-select">
                                {% for r in ['admin','manager','hr','user','viewer'] %}
                                <option value="{{ r }}" 
                                    {% if user and user.role == r %}selected{% elif r == 'user' and not user %}selected{% endif %}>
                                    {{ r | title }}
                                </option>
                                {% endfor %}
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Department</label>
                            <select name="department" class="form-select">
                                <option value="">— Select Department —</option>
                                {% for d in depts %}
                                <option value="{{ d.name }}" 
                                    {% if user and user.department == d.name %}selected{% endif %}>
                                    {{ d.name }}
                                </option>
                                {% endfor %}
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Phone</label>
                            <input type="tel" name="phone" class="form-control" 
                                   value="{{ user.phone if user else '' }}" placeholder="+1-555-0000">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Status</label>
                            <select name="status" class="form-select">
                                <option value="active" {% if not user or user.status == 'active' %}selected{% endif %}>Active</option>
                                <option value="inactive" {% if user and user.status == 'inactive' %}selected{% endif %}>Inactive</option>
                            </select>
                        </div>
                        {% if not user or not user.id %}
                        <div class="col-md-6">
                            <label class="form-label">Password</label>
                            <input type="text" name="password" class="form-control" 
                                   value="changeme123" placeholder="Initial password">
                            <div class="form-text">User should change this after first login.</div>
                        </div>
                        {% endif %}
                    </div>
                    
                    <div class="d-flex gap-2 mt-4">
                        <button type="submit" class="btn btn-primary">
                            <i data-feather="save" style="width:14px;height:14px"></i>
                            {{ 'Update User' if user and user.id else 'Create User' }}
                        </button>
                        <a href="{{ '/users/' + user.id|string if user and user.id else '/users' }}" class="btn btn-outline-secondary">
                            Cancel
                        </a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/partials/pagination.html ───────────────────
cat > $PROJECT/templates/partials/pagination.html <<'HTMLEOF'
{% if data.total_pages > 1 %}
<div class="d-flex justify-content-between align-items-center mt-3">
    <p class="text-muted small mb-0">
        Showing {{ ((data.page - 1) * data.per_page) + 1 }}–{{ [data.page * data.per_page, data.total] | min }}
        of {{ data.total }} results
    </p>
    <nav>
        <ul class="pagination pagination-sm mb-0">
            <li class="page-item {% if not data.has_prev %}disabled{% endif %}">
                <a class="page-link" href="?page={{ data.page - 1 }}&{{ request.query_params | string | replace('page=' + data.page|string, '') }}">
                    ‹ Prev
                </a>
            </li>
            {% for p in range(1, data.total_pages + 1) %}
            {% if p == data.page or p == 1 or p == data.total_pages or (p >= data.page - 1 and p <= data.page + 1) %}
            <li class="page-item {% if p == data.page %}active{% endif %}">
                <a class="page-link" href="?page={{ p }}">{{ p }}</a>
            </li>
            {% elif p == data.page - 2 or p == data.page + 2 %}
            <li class="page-item disabled"><span class="page-link">…</span></li>
            {% endif %}
            {% endfor %}
            <li class="page-item {% if not data.has_next %}disabled{% endif %}">
                <a class="page-link" href="?page={{ data.page + 1 }}">Next ›</a>
            </li>
        </ul>
    </nav>
</div>
{% endif %}
HTMLEOF

# ─── templates/departments/index.html ─────────────────────
cat > $PROJECT/templates/departments/index.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="mb-0">Departments</h4>
        <p class="text-muted mb-0 small">{{ data.total }} total departments</p>
    </div>
    <a href="/departments/new" class="btn btn-primary btn-sm">
        <i data-feather="plus" style="width:14px;height:14px"></i> New Department
    </a>
</div>

<div class="card mb-3">
    <div class="card-body py-2">
        <form method="GET" class="row g-2 align-items-end">
            <div class="col-md-6">
                <input type="text" name="search" class="form-control form-control-sm" 
                       placeholder="Search departments..." value="{{ filters.search }}">
            </div>
            <div class="col-md-3">
                <select name="status" class="form-select form-select-sm">
                    <option value="">All Status</option>
                    <option value="active" {% if filters.status == 'active' %}selected{% endif %}>Active</option>
                    <option value="inactive" {% if filters.status == 'inactive' %}selected{% endif %}>Inactive</option>
                </select>
            </div>
            <div class="col-md-1">
                <button type="submit" class="btn btn-primary btn-sm">Go</button>
            </div>
        </form>
    </div>
</div>

<div class="row g-3">
    {% for dept in data.items %}
    <div class="col-md-6 col-lg-4">
        <div class="card h-100 dept-card">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-start">
                    <div>
                        <h6 class="mb-0">
                            <a href="/departments/{{ dept.id }}" class="text-decoration-none">{{ dept.name }}</a>
                        </h6>
                        {% if dept.code %}
                        <span class="badge bg-light text-dark small">{{ dept.code }}</span>
                        {% endif %}
                    </div>
                    <span class="badge bg-{{ 'success' if dept.status == 'active' else 'secondary' }}">
                        {{ dept.status | title }}
                    </span>
                </div>
                <p class="text-muted small mt-2 mb-2">{{ dept.description or "No description" }}</p>
                <div class="d-flex gap-3 text-muted small">
                    <span><i data-feather="users" style="width:12px;height:12px"></i> {{ dept.user_count or 0 }} users</span>
                    {% if dept.location %}
                    <span><i data-feather="map-pin" style="width:12px;height:12px"></i> {{ dept.location }}</span>
                    {% endif %}
                    {% if dept.budget %}
                    <span><i data-feather="dollar-sign" style="width:12px;height:12px"></i> ${{ '{:,.0f}'.format(dept.budget) }}</span>
                    {% endif %}
                </div>
            </div>
            <div class="card-footer bg-transparent d-flex gap-2">
                <a href="/departments/{{ dept.id }}" class="btn btn-sm btn-outline-secondary flex-grow-1">View</a>
                <a href="/departments/{{ dept.id }}/edit" class="btn btn-sm btn-outline-primary flex-grow-1">Edit</a>
                <button class="btn btn-sm btn-outline-danger" 
                        onclick="confirmDelete('/departments/{{ dept.id }}/delete', '{{ dept.name }}')">
                    <i data-feather="trash-2" style="width:14px;height:14px"></i>
                </button>
            </div>
        </div>
    </div>
    {% else %}
    <div class="col-12">
        <div class="card">
            <div class="card-body text-center py-5 text-muted">No departments found</div>
        </div>
    </div>
    {% endfor %}
</div>
{% include "partials/pagination.html" %}
{% endblock %}
HTMLEOF

# ─── templates/departments/detail.html ────────────────────
cat > $PROJECT/templates/departments/detail.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="row g-3">
    <div class="col-lg-4">
        <div class="card">
            <div class="card-body">
                <h5>{{ dept.name }}</h5>
                {% if dept.code %}<p class="badge bg-light text-dark">{{ dept.code }}</p>{% endif %}
                <p class="text-muted">{{ dept.description or "No description" }}</p>
                <dl class="row small mb-0">
                    <dt class="col-5 text-muted">Status</dt>
                    <dd class="col-7">
                        <span class="badge bg-{{ 'success' if dept.status=='active' else 'secondary' }}">{{ dept.status }}</span>
                    </dd>
                    <dt class="col-5 text-muted">Location</dt>
                    <dd class="col-7">{{ dept.location or "—" }}</dd>
                    <dt class="col-5 text-muted">Budget</dt>
                    <dd class="col-7">{{ '$' + '{:,.0f}'.format(dept.budget) if dept.budget else "—" }}</dd>
                    <dt class="col-5 text-muted">Members</dt>
                    <dd class="col-7"><span class="badge bg-primary">{{ dept.user_count or 0 }}</span></dd>
                </dl>
                <div class="d-flex gap-2 mt-3">
                    <a href="/departments/{{ dept.id }}/edit" class="btn btn-primary btn-sm">Edit</a>
                    <button onclick="confirmDelete('/departments/{{ dept.id }}/delete', '{{ dept.name }}')" class="btn btn-outline-danger btn-sm">Delete</button>
                </div>
            </div>
        </div>
    </div>
    <div class="col-lg-8">
        <div class="card">
            <div class="card-header"><h6 class="mb-0">Team Members ({{ users | length }})</h6></div>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr><th>Name</th><th>Email</th><th>Role</th><th>Status</th></tr>
                    </thead>
                    <tbody>
                        {% for u in users %}
                        <tr>
                            <td><a href="/users/{{ u.id }}">{{ u.full_name }}</a></td>
                            <td class="text-muted small">{{ u.email }}</td>
                            <td><span class="badge bg-primary">{{ u.role }}</span></td>
                            <td><span class="badge bg-{{ 'success' if u.status=='active' else 'secondary' }}">{{ u.status }}</span></td>
                        </tr>
                        {% else %}
                        <tr><td colspan="4" class="text-center text-muted py-3">No members yet</td></tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/departments/form.html ──────────────────────
cat > $PROJECT/templates/departments/form.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="row justify-content-center">
    <div class="col-lg-7">
        <div class="card">
            <div class="card-header"><h5 class="card-title mb-0">{{ 'Edit Department' if dept and dept.id else 'New Department' }}</h5></div>
            <div class="card-body">
                {% if error %}<div class="alert alert-danger">{{ error }}</div>{% endif %}
                <form method="POST" action="{{ '/departments/' + dept.id|string + '/update' if dept and dept.id else '/departments/create' }}">
                    <div class="row g-3">
                        <div class="col-md-8">
                            <label class="form-label">Name <span class="text-danger">*</span></label>
                            <input type="text" name="name" class="form-control" value="{{ dept.name if dept else '' }}" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Code</label>
                            <input type="text" name="code" class="form-control" value="{{ dept.code if dept else '' }}" placeholder="ENG">
                        </div>
                        <div class="col-12">
                            <label class="form-label">Description</label>
                            <textarea name="description" class="form-control" rows="2">{{ dept.description if dept else '' }}</textarea>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Budget ($)</label>
                            <input type="number" name="budget" class="form-control" value="{{ dept.budget if dept else '0' }}" min="0">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Location</label>
                            <input type="text" name="location" class="form-control" value="{{ dept.location if dept else '' }}" placeholder="Floor 3">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Department Head</label>
                            <select name="head_user_id" class="form-select">
                                <option value="">— None —</option>
                                {% for m in managers %}
                                <option value="{{ m.id }}" {% if dept and dept.head_user_id == m.id %}selected{% endif %}>{{ m.full_name }}</option>
                                {% endfor %}
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Status</label>
                            <select name="status" class="form-select">
                                <option value="active" {% if not dept or dept.status == 'active' %}selected{% endif %}>Active</option>
                                <option value="inactive" {% if dept and dept.status == 'inactive' %}selected{% endif %}>Inactive</option>
                            </select>
                        </div>
                    </div>
                    <div class="d-flex gap-2 mt-4">
                        <button type="submit" class="btn btn-primary">
                            {{ 'Update' if dept and dept.id else 'Create' }} Department
                        </button>
                        <a href="/departments" class="btn btn-outline-secondary">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/roles/index.html ───────────────────────────
cat > $PROJECT/templates/roles/index.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0">Roles & Permissions</h4>
    <a href="/roles/new" class="btn btn-primary btn-sm">
        <i data-feather="plus" style="width:14px;height:14px"></i> New Role
    </a>
</div>
<div class="row g-3">
    {% for role in roles %}
    <div class="col-md-6 col-lg-4">
        <div class="card">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <h6 class="mb-0">{{ role.display_name }}</h6>
                    {% if role.is_system %}
                    <span class="badge bg-danger">System</span>
                    {% else %}
                    <span class="badge bg-secondary">Custom</span>
                    {% endif %}
                </div>
                <p class="text-muted small mb-2">{{ role.description or "No description" }}</p>
                <div class="d-flex gap-2 text-muted small">
                    <span><i data-feather="tag" style="width:12px;height:12px"></i> {{ role.name }}</span>
                    <span><i data-feather="users" style="width:12px;height:12px"></i> {{ role.user_count or 0 }} users</span>
                </div>
                {% if not role.is_system %}
                <div class="mt-2">
                    <form method="POST" action="/roles/{{ role.id }}/delete" class="d-inline">
                        <button class="btn btn-sm btn-outline-danger" onclick="return confirm('Delete role?')">Delete</button>
                    </form>
                </div>
                {% endif %}
            </div>
        </div>
    </div>
    {% endfor %}
</div>
{% endblock %}
HTMLEOF

cat > $PROJECT/templates/roles/form.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="row justify-content-center">
    <div class="col-lg-6">
        <div class="card">
            <div class="card-header"><h5 class="mb-0">New Role</h5></div>
            <div class="card-body">
                {% if error %}<div class="alert alert-danger">{{ error }}</div>{% endif %}
                <form method="POST" action="/roles/create">
                    <div class="mb-3">
                        <label class="form-label">Role Name (slug) <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control" placeholder="e.g. supervisor" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Display Name <span class="text-danger">*</span></label>
                        <input type="text" name="display_name" class="form-control" placeholder="e.g. Supervisor" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control" rows="2"></textarea>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">Create Role</button>
                        <a href="/roles" class="btn btn-outline-secondary">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/reports/index.html ─────────────────────────
cat > $PROJECT/templates/reports/index.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0">Reports</h4>
    <a href="/reports/users/export" class="btn btn-outline-success btn-sm">
        <i data-feather="download" style="width:14px;height:14px"></i> Export Users CSV
    </a>
</div>

<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="stat-card stat-card-blue">
            <div class="stat-value">{{ user_stats.total }}</div>
            <div class="stat-label">Total Users</div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="stat-card stat-card-green">
            <div class="stat-value">{{ user_stats.active }}</div>
            <div class="stat-label">Active Users</div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="stat-card stat-card-orange">
            <div class="stat-value">{{ user_stats.inactive }}</div>
            <div class="stat-label">Inactive Users</div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="stat-card stat-card-purple">
            <div class="stat-value">{{ dept_stats.total }}</div>
            <div class="stat-label">Departments</div>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-lg-6">
        <div class="card">
            <div class="card-header"><h6 class="mb-0">Users by Role</h6></div>
            <div class="card-body p-0">
                <table class="table mb-0">
                    <thead class="table-light"><tr><th>Role</th><th>Count</th><th>%</th></tr></thead>
                    <tbody>
                        {% for r in user_stats.by_role %}
                        <tr>
                            <td>{{ r.role | title }}</td>
                            <td><span class="badge bg-primary">{{ r.count }}</span></td>
                            <td>{{ ((r.count / user_stats.total) * 100) | round(1) if user_stats.total else 0 }}%</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="card">
            <div class="card-header"><h6 class="mb-0">Department Overview</h6></div>
            <div class="card-body p-0">
                <table class="table mb-0">
                    <thead class="table-light"><tr><th>Department</th><th>Users</th><th>Budget</th></tr></thead>
                    <tbody>
                        {% for d in dept_stats.by_users %}
                        <tr>
                            <td>{{ d.name }}</td>
                            <td><span class="badge bg-success">{{ d.count }}</span></td>
                            <td class="small text-muted">${{ '{:,.0f}'.format(d.budget) if d.budget else '0' }}</td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
{% endblock %}
HTMLEOF

# ─── templates/audit/index.html ───────────────────────────
cat > $PROJECT/templates/audit/index.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0">Audit Logs</h4>
    <span class="badge bg-secondary">{{ data.total }} records</span>
</div>

<div class="card mb-3">
    <div class="card-body py-2">
        <form method="GET" class="row g-2 align-items-end">
            <div class="col-md-3">
                <select name="module" class="form-select form-select-sm">
                    <option value="">All Modules</option>
                    {% for m in ['users','departments','roles','auth','settings'] %}
                    <option value="{{ m }}" {% if filters.module == m %}selected{% endif %}>{{ m | title }}</option>
                    {% endfor %}
                </select>
            </div>
            <div class="col-md-2">
                <select name="action" class="form-select form-select-sm">
                    <option value="">All Actions</option>
                    {% for a in ['create','update','delete','login','logout','export'] %}
                    <option value="{{ a }}" {% if filters.action == a %}selected{% endif %}>{{ a | title }}</option>
                    {% endfor %}
                </select>
            </div>
            <div class="col-md-2">
                <input type="date" name="date_from" class="form-control form-control-sm" value="{{ filters.date_from }}">
            </div>
            <div class="col-md-2">
                <input type="date" name="date_to" class="form-control form-control-sm" value="{{ filters.date_to }}">
            </div>
            <div class="col-md-1">
                <button type="submit" class="btn btn-primary btn-sm">Filter</button>
            </div>
            <div class="col-md-1">
                <a href="/audit" class="btn btn-outline-secondary btn-sm">Clear</a>
            </div>
        </form>
    </div>
</div>

<div class="card">
    <div class="table-responsive">
        <table class="table table-hover mb-0 small">
            <thead class="table-light">
                <tr><th>Time</th><th>User</th><th>Action</th><th>Module</th><th>Record</th><th>Status</th></tr>
            </thead>
            <tbody>
                {% for log in data.items %}
                <tr>
                    <td class="text-muted">{{ log.created_at[:16] if log.created_at else "—" }}</td>
                    <td>{{ log.user_email or "—" }}</td>
                    <td>
                        <span class="badge bg-{{ {'create':'success','update':'info','delete':'danger','login':'primary','logout':'secondary'}.get(log.action, 'secondary') }}">
                            {{ log.action | title }}
                        </span>
                    </td>
                    <td>{{ log.module | title }}</td>
                    <td>{{ log.record_id or "—" }}</td>
                    <td>
                        <span class="badge bg-{{ 'success' if log.status == 'success' else 'danger' }}">
                            {{ log.status | title }}
                        </span>
                    </td>
                </tr>
                {% else %}
                <tr><td colspan="6" class="text-center py-4 text-muted">No audit logs found</td></tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
</div>
{% include "partials/pagination.html" %}
{% endblock %}
HTMLEOF

# ─── templates/settings/index.html ────────────────────────
cat > $PROJECT/templates/settings/index.html <<'HTMLEOF'
{% extends "base.html" %}
{% block content %}
<div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0">Settings</h4>
</div>

{% if success %}
<div class="alert alert-success alert-dismissible fade show" role="alert">
    ✅ Settings saved successfully!
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
{% endif %}

<form method="POST" action="/settings/update">
    <div class="row g-3">
        {% for group, settings in grouped_settings.items() %}
        <div class="col-lg-6">
            <div class="card">
                <div class="card-header">
                    <h6 class="card-title mb-0">{{ group | title }} Settings</h6>
                </div>
                <div class="card-body">
                    {% for s in settings %}
                    <div class="mb-3">
                        <label class="form-label fw-semibold">{{ s.description or s.key }}</label>
                        {% if s.type == 'boolean' %}
                        <select name="{{ s.key }}" class="form-select form-select-sm">
                            <option value="true" {% if s.value == 'true' %}selected{% endif %}>Enabled</option>
                            <option value="false" {% if s.value != 'true' %}selected{% endif %}>Disabled</option>
                        </select>
                        {% elif s.type == 'integer' %}
                        <input type="number" name="{{ s.key }}" class="form-control form-control-sm" value="{{ s.value or '0' }}">
                        {% else %}
                        <input type="text" name="{{ s.key }}" class="form-control form-control-sm" value="{{ s.value or '' }}">
                        {% endif %}
                    </div>
                    {% endfor %}
                </div>
            </div>
        </div>
        {% endfor %}
    </div>
    <div class="mt-3">
        <button type="submit" class="btn btn-primary">
            <i data-feather="save" style="width:14px;height:14px"></i> Save All Settings
        </button>
    </div>
</form>
{% endblock %}
HTMLEOF

echo ""
echo "📦 PART 4 COMPLETE! Templates created."
