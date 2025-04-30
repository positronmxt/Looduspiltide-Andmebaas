"""
Models package initialization.
This file makes models available for import throughout the application.
"""

# Import base models first to avoid circular imports
from .base_models import Base

# Then import specific models
# Photo and species models
from .photo_models import Photo
from .species_models import Species
from .relation_models import PhotoSpeciesRelation

# Settings models - import after base models are loaded
from .settings_models import AppSettings, AppSetting, AppSettingCreate, AppSettingUpdate, AppSettingResponse, AllSettingsResponse