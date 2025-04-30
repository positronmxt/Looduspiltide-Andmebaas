"""
Rakenduse seadistuste teenus.
"""
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from database import get_db
import logging
from models.settings_models import AppSettings

logger = logging.getLogger(__name__)

class SettingsService:
    """Teenus rakenduse seadistuste haldamiseks."""

    @staticmethod
    async def get_all_settings():
        """Tagastab kõik rakenduse seadistused."""
        db = next(get_db())
        try:
            settings = db.query(AppSettings).all()
            return [
                {"key": setting.key, "value": setting.value, "description": setting.description}
                for setting in settings
            ]
        except Exception as e:
            logger.error(f"Viga seadistuste lugemisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def get_setting(key: str):
        """Tagastab ühe seadistuse võtme järgi."""
        db = next(get_db())
        try:
            setting = db.query(AppSettings).filter(AppSettings.key == key).first()
            
            if not setting:
                return None
            
            return {"key": setting.key, "value": setting.value, "description": setting.description}
        except Exception as e:
            logger.error(f"Viga seadistuse '{key}' lugemisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def update_setting(key: str, value: str, description: Optional[str] = None):
        """Uuendab olemasolevat seadistust. Kui seadistust ei ole, siis loob selle."""
        db = next(get_db())
        try:
            # Kontrollime, kas seadistus eksisteerib
            setting = db.query(AppSettings).filter(AppSettings.key == key).first()
            
            if not setting:
                # Kui seadistust ei ole, siis loome selle
                logger.info(f"Seadistust '{key}' ei leitud, loome uue")
                auto_description = description or f"Automaatselt loodud seadistus: {key}"
                return await SettingsService.create_setting(key, value, auto_description)
            
            # Uuendame väärtuse
            setting.value = value
            
            # Kui uus kirjeldus on antud, uuendame seda
            if description is not None:
                setting.description = description
            
            db.commit()
            return await SettingsService.get_setting(key)
        except Exception as e:
            db.rollback()
            logger.error(f"Viga seadistuse '{key}' uuendamisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def create_setting(key: str, value: str, description: str):
        """Loob uue seadistuse."""
        db = next(get_db())
        try:
            # Kontrollime, kas seadistus juba eksisteerib
            existing = db.query(AppSettings).filter(AppSettings.key == key).first()
            
            if existing:
                raise ValueError(f"Seadistus võtmega '{key}' juba eksisteerib")
            
            # Genereerime uue ID
            import uuid
            new_id = str(uuid.uuid4())
            
            # Loome uue seadistuse
            new_setting = AppSettings(
                id=new_id,
                key=key,
                value=value,
                description=description
            )
            
            db.add(new_setting)
            db.commit()
            
            return await SettingsService.get_setting(key)
        except Exception as e:
            db.rollback()
            logger.error(f"Viga seadistuse '{key}' loomisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def delete_setting(key: str):
        """Kustutab seadistuse."""
        db = next(get_db())
        try:
            # Kontrollime, kas seadistus eksisteerib
            setting = db.query(AppSettings).filter(AppSettings.key == key).first()
            
            if not setting:
                raise ValueError(f"Seadistust võtmega '{key}' ei leitud")
            
            db.delete(setting)
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"Viga seadistuse '{key}' kustutamisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def get_plant_id_api_key():
        """Tagastab Plant.id API võtme."""
        setting = await SettingsService.get_setting("PLANT_ID_API_KEY")
        return setting["value"] if setting else ""