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
