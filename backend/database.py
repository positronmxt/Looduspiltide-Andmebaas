"""
Database configuration for the application.
Provides database connection settings and session management.
"""
import os
import sys
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

# Try to import dotenv, but don't fail if it's not installed
try:
    from dotenv import load_dotenv
    # Lae .env fail vastavalt keskkonnale
    env_file = os.getenv("ENV_FILE", ".env")
    if os.path.exists(f"{os.path.dirname(__file__)}/.env.{os.getenv('ENVIRONMENT', 'development')}"):
        env_file = f".env.{os.getenv('ENVIRONMENT', 'development')}"
        print(f"Kasutan keskkonna konfiguratsioonifaili: {env_file}")
    
    load_dotenv(os.path.join(os.path.dirname(__file__), env_file))
except ImportError:
    print("Warning: python-dotenv not found. Environment variables must be set manually.")
    pass

# Database connection configuration with environment variables or defaults
DB_USER = os.getenv("DB_USER", "nature_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "securepassword")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "nature_photo_db")
DEBUG = os.getenv("DEBUG", "false").lower() == "true"

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Log connection info in debug mode
if DEBUG:
    print(f"Ühendun andmebaasiga: postgresql://{DB_USER}:******@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    print(f"Keskkond: {os.getenv('ENVIRONMENT', 'pole määratud')}")

# Create engine with echo mode for debugging
engine = create_engine(
    DATABASE_URL,
    echo=DEBUG,  # Logi SQL päringud, kui DEBUG=true
    pool_pre_ping=True  # Kontrolli ühendust enne kasutamist
)

# Create session
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

# Function to test database connection
def test_connection():
    """Test database connection and return status."""
    try:
        # Create a connection to test
        conn = engine.connect()
        conn.close()
        return True, "Andmebaasi ühendus toimib!"
    except Exception as e:
        error_msg = f"Andmebaasi ühenduse viga: {str(e)}"
        return False, error_msg

# Test connection if run directly
if __name__ == "__main__":
    success, message = test_connection()
    if success:
        print("\033[92m" + message + "\033[0m")  # Green text
        sys.exit(0)
    else:
        print("\033[91m" + message + "\033[0m")  # Red text
        sys.exit(1)