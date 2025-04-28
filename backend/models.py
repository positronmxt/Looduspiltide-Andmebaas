from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from .database import Base

class Photo(Base):
    __tablename__ = "photos"

    id = Column(Integer, primary_key=True, index=True)
    file_path = Column(String, unique=True, index=True)
    date = Column(String)
    location = Column(String)

    species = relationship("PhotoSpeciesRelation", back_populates="photo")

class Species(Base):
    __tablename__ = "species"

    id = Column(Integer, primary_key=True, index=True)
    scientific_name = Column(String, unique=True, index=True)
    common_name = Column(String)
    family = Column(String)

    photos = relationship("PhotoSpeciesRelation", back_populates="species")

class PhotoSpeciesRelation(Base):
    __tablename__ = "photo_species_relation"

    id = Column(Integer, primary_key=True, index=True)
    photo_id = Column(Integer, ForeignKey("photos.id"))
    species_id = Column(Integer, ForeignKey("species.id"))
    category = Column(String)

    photo = relationship("Photo", back_populates="species")
    species = relationship("Species", back_populates="photos")