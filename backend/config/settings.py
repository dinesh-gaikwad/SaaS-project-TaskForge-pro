class Config:
    SQLALCHEMY_DATABASE_URI = 'sqlite:///taskforge.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = 'dev-secret-key-change-in-production'
