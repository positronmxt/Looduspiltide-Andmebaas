"""
Database configuration for the application.
Provides database connection settings and session management.
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# Database connection configuration
DATABASE_URL = "postgresql://nature_user:securepassword@localhost:5433/nature_photo_db"

# Create engine and session
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# For backwards compatibility with old code
Base = declarative_base()

# Database metadata
metadata = MetaData()

# Dependency to get DB session
def get_db():
    """
    Dependency function that yields a SQLAlchemy database session.
    Ensures the session is closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()