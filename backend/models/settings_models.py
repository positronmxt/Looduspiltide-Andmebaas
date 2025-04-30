"""
Rakenduse seadistuste mudelid.
"""
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.sql import func
from models.base_models import Base

# SQLAlchemy mudel andmebaasi jaoks
class AppSettings(Base):
    """Rakenduse seadistus andmebaasis."""
    __tablename__ = "app_settings"

    id = Column(String(50), primary_key=True)
    key = Column(String(100), unique=True, nullable=False, index=True)
    value = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

# Pydantic mudelid API jaoks
class AppSetting(BaseModel):
    """Rakenduse seadistus andmebaasis."""
    key: str
    value: str
    description: str

class AppSettingCreate(BaseModel):
    """Seadistuse loomise skeem."""
    key: str
    value: str
    description: str

class AppSettingUpdate(BaseModel):
    """Seadistuse uuendamise skeem."""
    value: str
    description: Optional[str] = None

class AppSettingResponse(BaseModel):
    """Seadistuse vastuse skeem."""
    key: str
    value: str
    description: str

    class Config:
        from_attributes = True

class AllSettingsResponse(BaseModel):
    """Kõikide seadistuste vastuse skeem."""
    settings: List[AppSettingResponse]