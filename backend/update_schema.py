"""
Script to update the database schema for photo metadata fields.
Run this to add GPS and camera info columns to the photos table.
"""
from sqlalchemy import create_engine, text
import logging

# Import database connection URL from your config
from database import DATABASE_URL

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def update_schema():
    """Update the database schema to include new metadata columns."""
    # Connect to database
    engine = create_engine(DATABASE_URL)
    connection = engine.connect()
    
    try:
        # Add GPS coordinate columns
        logger.info("Adding GPS coordinate columns to photos table...")
        connection.execute(text("""
            ALTER TABLE photos 
            ADD COLUMN IF NOT EXISTS gps_latitude FLOAT,
            ADD COLUMN IF NOT EXISTS gps_longitude FLOAT,
            ADD COLUMN IF NOT EXISTS gps_altitude FLOAT
        """))
        
        # Add camera info columns
        logger.info("Adding camera info columns to photos table...")
        connection.execute(text("""
            ALTER TABLE photos 
            ADD COLUMN IF NOT EXISTS camera_make VARCHAR,
            ADD COLUMN IF NOT EXISTS camera_model VARCHAR
        """))
        
        connection.commit()
        logger.info("Schema updated successfully!")
    except Exception as e:
        connection.rollback()
        logger.error(f"Error updating schema: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    update_schema()