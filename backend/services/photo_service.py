"""
Photo service module containing business logic for photo operations.
"""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from typing import List, Optional, Dict, Any
import os
import logging

from models.photo_models import Photo
from models.species_models import Species
from models.relation_models import PhotoSpeciesRelation
from utils.exif_reader import get_image_metadata

# Set up logging
logger = logging.getLogger(__name__)

def get_photo(db: Session, photo_id: int) -> Optional[Dict[str, Any]]:
    """
    Get a single photo by ID.
    
    Args:
        db: Database session
        photo_id: ID of the photo to retrieve
        
    Returns:
        Photo object as dictionary if found, None otherwise
    """
    photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not photo:
        return None
    
    return {
        "id": photo.id,
        "file_path": photo.file_path,
        "date": photo.date,
        "location": photo.location,
        "gps_latitude": photo.gps_latitude,
        "gps_longitude": photo.gps_longitude,
        "gps_altitude": photo.gps_altitude,
        "camera_make": photo.camera_make,
        "camera_model": photo.camera_model
    }

def get_photos(
    db: Session, 
    species_id: Optional[int] = None,
    species_name: Optional[str] = None, 
    location: Optional[str] = None, 
    date: Optional[str] = None, 
    offset: int = 0, 
    limit: int = 20
) -> List[Dict[str, Any]]:
    """
    Get a list of photos with optional filtering.
    
    Args:
        db: Database session
        species_id: Optional filter by species ID
        species_name: Optional filter by species name (scientific or common name)
        location: Optional filter by location (substring match)
        date: Optional filter by date (substring match)
        offset: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List of Photo objects as dictionaries
    """
    query = db.query(Photo)
    
    # Apply filters if provided
    if species_id or species_name:
        query = query.join(PhotoSpeciesRelation).join(Species)
        
        if species_id:
            query = query.filter(PhotoSpeciesRelation.species_id == species_id)
        
        if species_name:
            query = query.filter(
                or_(
                    Species.scientific_name.ilike(f"%{species_name}%"),
                    Species.common_name.ilike(f"%{species_name}%")
                )
            )
    
    if location:
        query = query.filter(Photo.location.ilike(f"%{location}%"))
    
    if date:
        # Täiustatud kuupäeva filter, mis otsib ka osalisi kuupäevi
        query = query.filter(Photo.date.ilike(f"%{date}%"))
    
    # Order by newest photos first
    query = query.order_by(Photo.id.desc())
    
    # Eemalda duplikaadid (võib tekkida species join'i puhul)
    query = query.distinct(Photo.id)
    
    # Get photos with basic info
    photos = query.offset(offset).limit(limit).all()
    
    # Create result list
    result = []
    for photo in photos:
        # Get species for this photo
        species_relations = db.query(PhotoSpeciesRelation).filter(
            PhotoSpeciesRelation.photo_id == photo.id
        ).all()
        
        species_list = []
        for relation in species_relations:
            species = db.query(Species).filter(Species.id == relation.species_id).first()
            if species:
                species_info = {
                    "id": species.id,
                    "scientific_name": species.scientific_name,
                    "common_name": species.common_name,
                    "family": species.family
                }
                species_list.append(species_info)
        
        # Add photo with species to result
        photo_dict = {
            "id": photo.id,
            "file_path": photo.file_path,
            "date": photo.date,
            "location": photo.location,
            "species": species_list
        }
        result.append(photo_dict)
    
    return result

def get_photo_with_species(db: Session, photo_id: int) -> Optional[Dict[str, Any]]:
    """
    Get a photo with all associated species information.
    
    Args:
        db: Database session
        photo_id: ID of the photo to retrieve
        
    Returns:
        Dictionary with photo and species information
    """
    photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not photo:
        return None
    
    # Get all species associated with this photo
    species_relations = db.query(PhotoSpeciesRelation).filter(
        PhotoSpeciesRelation.photo_id == photo_id
    ).all()
    
    species_list = []
    for relation in species_relations:
        species = db.query(Species).filter(Species.id == relation.species_id).first()
        if species:
            species_info = {
                "id": species.id,
                "scientific_name": species.scientific_name,
                "common_name": species.common_name,
                "family": species.family,
                "relation_category": relation.category,
                "relation_id": relation.id
            }
            species_list.append(species_info)
    
    return {
        "id": photo.id,
        "file_path": photo.file_path,
        "date": photo.date,
        "location": photo.location,
        "gps_latitude": photo.gps_latitude,
        "gps_longitude": photo.gps_longitude,
        "gps_altitude": photo.gps_altitude,
        "camera_make": photo.camera_make,
        "camera_model": photo.camera_model,
        "species": species_list
    }

def create_photo(db: Session, file_path: str, date: str = None, location: str = None) -> Photo:
    """
    Create a new photo record.
    
    Args:
        db: Database session
        file_path: Path to the photo file
        date: Date when the photo was taken (optional, will be read from EXIF if available)
        location: Location where the photo was taken (optional, will be read from EXIF if available)
        
    Returns:
        Created Photo object
    """
    # Create basic photo record
    db_photo = Photo(file_path=file_path, date=date, location=location)
    
    # Try to extract metadata from the image
    try:
        logger.info(f"Extracting metadata from image: {file_path}")
        metadata = get_image_metadata(file_path)
        
        # Debug - print full metadata
        logger.info(f"Raw metadata result: {metadata}")
        
        # Update with metadata if available
        if metadata and len(metadata) > 0:
            logger.info(f"Found metadata for file {file_path}: {metadata.keys()}")
            
            # Only set date from EXIF if not provided by user
            if not date and "date" in metadata:
                db_photo.date = metadata["date"]
                logger.info(f"Set date from metadata: {metadata['date']}")
            
            # Only set location from EXIF if not provided by user
            if not location and "location" in metadata:
                db_photo.location = metadata["location"]
                logger.info(f"Set location from metadata: {metadata['location']}")
            
            # Always set GPS coordinates and camera info from metadata
            if "gps_latitude" in metadata:
                db_photo.gps_latitude = metadata["gps_latitude"]
                logger.info(f"Set GPS latitude from metadata: {metadata['gps_latitude']}")
                
                # If we have GPS coordinates but no location, use coordinates as location
                if not db_photo.location and "gps_longitude" in metadata:
                    db_photo.location = f"{metadata['gps_latitude']}, {metadata['gps_longitude']}"
                    logger.info(f"Set location from GPS coordinates: {db_photo.location}")
            
            if "gps_longitude" in metadata:
                db_photo.gps_longitude = metadata["gps_longitude"]
                logger.info(f"Set GPS longitude from metadata: {metadata['gps_longitude']}")
            
            if "gps_altitude" in metadata:
                db_photo.gps_altitude = metadata["gps_altitude"]
                logger.info(f"Set GPS altitude from metadata: {metadata['gps_altitude']}")
            
            if "camera_make" in metadata:
                db_photo.camera_make = metadata["camera_make"]
                logger.info(f"Set camera make from metadata: {metadata['camera_make']}")
            
            if "camera_model" in metadata:
                db_photo.camera_model = metadata["camera_model"]
                logger.info(f"Set camera model from metadata: {metadata['camera_model']}")
        else:
            logger.warning(f"No metadata extracted from image: {file_path}")
                
    except Exception as e:
        # Log error but continue with photo creation
        logger.error(f"Error reading EXIF metadata from {file_path}: {str(e)}")
        logger.exception(e)  # Log full exception traceback
    
    # Save to database
    db.add(db_photo)
    db.commit()
    db.refresh(db_photo)
    logger.info(f"Created new photo with ID: {db_photo.id}, location: {db_photo.location}, "
                f"gps_latitude: {db_photo.gps_latitude}, gps_longitude: {db_photo.gps_longitude}")
    return db_photo

def update_photo(db: Session, photo_id: int, date: Optional[str] = None, location: Optional[str] = None,
                gps_latitude: Optional[float] = None, gps_longitude: Optional[float] = None,
                gps_altitude: Optional[float] = None) -> Optional[Photo]:
    """
    Update an existing photo record.
    
    Args:
        db: Database session
        photo_id: ID of the photo to update
        date: New date for the photo
        location: New location for the photo
        gps_latitude: New GPS latitude
        gps_longitude: New GPS longitude
        gps_altitude: New GPS altitude
        
    Returns:
        Updated Photo object if found and updated, None otherwise
    """
    db_photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not db_photo:
        return None
    
    # Update fields if provided
    if date is not None:
        db_photo.date = date
    if location is not None:
        db_photo.location = location
    if gps_latitude is not None:
        db_photo.gps_latitude = gps_latitude
    if gps_longitude is not None:
        db_photo.gps_longitude = gps_longitude
    if gps_altitude is not None:
        db_photo.gps_altitude = gps_altitude
    
    db.commit()
    db.refresh(db_photo)
    return db_photo

def delete_photo(db: Session, photo_id: int, delete_file: bool = False) -> bool:
    """
    Delete a photo record and optionally the associated file.
    
    Args:
        db: Database session
        photo_id: ID of the photo to delete
        delete_file: Whether to also delete the physical file
        
    Returns:
        True if the photo was found and deleted, False otherwise
    """
    db_photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not db_photo:
        return False
    
    # Delete associated relations with species
    db.query(PhotoSpeciesRelation).filter(PhotoSpeciesRelation.photo_id == photo_id).delete()
    
    # Optionally delete the physical file
    if delete_file and db_photo.file_path and os.path.exists(db_photo.file_path):
        try:
            os.remove(db_photo.file_path)
        except Exception as e:
            # Log the error but continue with database deletion
            print(f"Error deleting file {db_photo.file_path}: {str(e)}")
    
    # Delete the photo record
    db.delete(db_photo)
    db.commit()
    return True