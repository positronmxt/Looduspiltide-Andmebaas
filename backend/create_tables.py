"""
Database initialization script.
Creates all database tables defined in model classes.
"""
import sys
from pathlib import Path

# Add parent directory to Python path for imports to work
sys.path.append(str(Path(__file__).parent.parent))

from database import engine, Base

# Import all model classes to ensure they're registered with SQLAlchemy
from models.photo_models import Photo
from models.species_models import Species
from models.relation_models import PhotoSpeciesRelation
from models.settings_models import AppSettings

def create_tables():
    """
    Create all tables in the database.
    """
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

if __name__ == "__main__":
    try:
        create_tables()
    except Exception as e:
        print(f"VIGA: Andmebaasi tabelite loomine ebaõnnestus: {str(e)}")
        print("\nKontrollige, kas PostgreSQL teenus on käivitatud:")
        print("sudo systemctl status postgresql")
        print("\nKui teenus pole aktiivne, käivitage see:")
        print("sudo systemctl start postgresql")
        sys.exit(1)