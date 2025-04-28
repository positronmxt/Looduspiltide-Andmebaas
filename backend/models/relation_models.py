"""
Relation model definition for the application.
Represents the many-to-many relationship between photos and species.
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from models.base_models import Base

class PhotoSpeciesRelation(Base):
    """Relation model linking photos with species with additional metadata."""
    __tablename__ = "photo_species_relation"

    id = Column(Integer, primary_key=True, index=True)
    photo_id = Column(Integer, ForeignKey("photos.id"))
    species_id = Column(Integer, ForeignKey("species.id"))
    category = Column(String)

    photo = relationship("Photo", back_populates="species")
    species = relationship("Species", back_populates="photos")