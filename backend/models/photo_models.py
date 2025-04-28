"""
Photo model definition for the application.
Represents photos stored in the database with their metadata.
"""
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.orm import relationship
from models.base_models import Base

class Photo(Base):
    """Photo model representing a nature photograph in the database."""
    __tablename__ = "photos"

    id = Column(Integer, primary_key=True, index=True)
    file_path = Column(String, unique=True, index=True)
    date = Column(String)
    location = Column(String)
    
    # GPS coordinates
    gps_latitude = Column(Float, nullable=True)
    gps_longitude = Column(Float, nullable=True) 
    gps_altitude = Column(Float, nullable=True)
    
    # Camera information
    camera_make = Column(String, nullable=True)
    camera_model = Column(String, nullable=True)

    species = relationship("PhotoSpeciesRelation", back_populates="photo")