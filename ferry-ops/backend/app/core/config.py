from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Ferry Operations Platform"
    APP_VERSION: str = "1.0.0"
    SECRET_KEY: str = "change_this_secret"
    DATABASE_FILE: str = "ferry_ops.db"

settings = Settings()
