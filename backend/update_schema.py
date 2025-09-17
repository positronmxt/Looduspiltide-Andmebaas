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

        # Add estonian_name column to species table
        logger.info("Adding estonian_name column to species table if missing...")
        connection.execute(text("""
            ALTER TABLE species
            ADD COLUMN IF NOT EXISTS estonian_name VARCHAR
        """))
        
        # Check if app_settings table exists
        logger.info("Kontrollime app_settings tabeli olemasolu...")
        result = connection.execute(text("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_name = 'app_settings'
            )
        """))
        table_exists = result.scalar()
        logger.info(f"app_settings tabel {'eksisteerib' if table_exists else 'ei eksisteeri'}")
        
        # Kui tabel ei eksisteeri, siis loome selle
        if not table_exists:
            logger.info("Loome app_settings tabeli...")
            connection.execute(text("""
                CREATE TABLE app_settings (
                    id VARCHAR(50) PRIMARY KEY,
                    key VARCHAR(100) NOT NULL UNIQUE,
                    value TEXT,
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
        else:
            # Kontrollime, kas id väli on olemas
            logger.info("Kontrollime app_settings tabeli struktuuri...")
            try:
                columns_result = connection.execute(text("""
                    SELECT column_name 
                    FROM information_schema.columns 
                    WHERE table_name = 'app_settings'
                """))
                columns = [row[0] for row in columns_result]
                
                # Kui id välja pole, lisame vajalikud väljad juurde
                if 'id' not in columns:
                    logger.info("Täiendame app_settings tabeli struktuuri...")
                    connection.execute(text("""
                        ALTER TABLE app_settings 
                        ADD COLUMN IF NOT EXISTS id VARCHAR(50) PRIMARY KEY DEFAULT '1',
                        ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    """))
            except Exception as e:
                logger.error(f"Viga tabeli struktuuri kontrollimisel: {e}")
                # Jätkame, et proovida siiski seadistusi lisada
        
        # Add default settings if needed
        logger.info("Lisame vaikimisi seaded...")
        connection.execute(text("""
            INSERT INTO app_settings (id, key, value, description)
            VALUES ('1', 'PLANT_ID_API_KEY', '', 'Plant.id API võtme väärtus')
            ON CONFLICT (key) DO NOTHING
        """))
        
        connection.execute(text("""
            INSERT INTO app_settings (id, key, value, description)
            VALUES ('2', 'ENABLE_PLANT_IDENTIFICATION', 'true', 'Kas taimeliikide automaatne tuvastamine on lubatud')
            ON CONFLICT (key) DO NOTHING
        """))
        
        connection.commit()
        logger.info("Skeemi uuendamine õnnestus!")
    except Exception as e:
        connection.rollback()
        logger.error(f"Viga skeemi uuendamisel: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    update_schema()