from sqlalchemy import Column, Integer, DateTime
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Model(Base):
    __abstract__ = True
    
    id = Column(Integer, primary_key=True)
    created_at = Column(DateTime, default=DateTime.now)
    updated_at = Column(DateTime, default=DateTime.now, onupdate=DateTime.now)
