"""
Species model definition for the application.
Represents species entries stored in the database.
"""
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from models.base_models import Base

class Species(Base):
    """Species model representing a plant or animal species in the database."""
    __tablename__ = "species"

    id = Column(Integer, primary_key=True, index=True)
    scientific_name = Column(String, unique=True, index=True)
    common_name = Column(String)
    family = Column(String)
    # Estonian localized common name
    estonian_name = Column(String, nullable=True)

    photos = relationship("PhotoSpeciesRelation", back_populates="species")