"""
Database initialization script.
Creates all database tables defined in model classes.
"""
import sys
from pathlib import Path

# Add parent directory to Python path for imports to work
sys.path.append(str(Path(__file__).parent.parent))

from database import engine
from models.base_models import Base
from models.photo_models import Photo
from models.species_models import Species
from models.relation_models import PhotoSpeciesRelation

def create_tables():
    """
    Create all tables in the database.
    """
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

if __name__ == "__main__":
    create_tables()