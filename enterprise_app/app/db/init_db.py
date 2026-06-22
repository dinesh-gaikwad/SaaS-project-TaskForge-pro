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
