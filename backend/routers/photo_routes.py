"""
API routes for photo operations.
Provides endpoints for CRUD operations on photos.
"""
from fastapi import APIRouter, Depends, HTTPException, Body, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
import os
import shutil
import uuid
from datetime import datetime
import logging
from tempfile import NamedTemporaryFile
import re

from database import get_db
from services import photo_service
from models.photo_models import Photo
from utils.exif_reader import get_image_metadata, run_exiftool, extract_date, extract_location, extract_gps_coordinates

# Set up logging
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/photos",
    tags=["photos"],
    responses={404: {"description": "Not found"}},
)

@router.get("/")
def read_photos(
    species_id: Optional[int] = None,
    species_name: Optional[str] = None,
    location: Optional[str] = None, 
    date: Optional[str] = None, 
    offset: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    """
    Retrieve a list of photos with pagination and optional filtering.
    
    Args:
        species_id: Optional filter by species ID
        species_name: Optional filter by species name (scientific or common name)
        location: Optional filter by location (substring match)
        date: Optional filter by exact date
        offset: Number of records to skip
        limit: Maximum number of records to return
        db: Database session
    """
    photos = photo_service.get_photos(
        db, 
        species_id=species_id,
        species_name=species_name,
        location=location, 
        date=date, 
        offset=offset, 
        limit=limit
    )
    
    # Ensure we're returning a list of dictionaries, not SQLAlchemy objects
    if photos and not isinstance(photos[0], dict):
        return [
            {
                "id": photo.id,
                "file_path": photo.file_path,
                "date": photo.date,
                "location": photo.location
            }
            for photo in photos
        ]
    return photos

@router.get("/{photo_id}")
def read_photo(photo_id: int, db: Session = Depends(get_db)):
    """
    Retrieve a specific photo by ID.
    """
    # Kasuta get_photo_with_species, mis tagastab ka fotoga seotud taimeliigid
    db_photo = photo_service.get_photo_with_species(db, photo_id=photo_id)
    if db_photo is None:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    return db_photo

@router.put("/{photo_id}")
def update_photo(
    photo_id: int, 
    date: Optional[str] = Body(None), 
    location: Optional[str] = Body(None), 
    db: Session = Depends(get_db)
):
    """
    Update a specific photo by ID.
    """
    updated_photo = photo_service.update_photo(db, photo_id=photo_id, date=date, location=location)
    if updated_photo is None:
        raise HTTPException(status_code=404, detail="Fotot ei leitud")
    
    return {"message": "Foto andmed edukalt uuendatud", "photo": updated_photo}

@router.delete("/{photo_id}")
def delete_photo(
    photo_id: int, 
    delete_file: bool = False,
    db: Session = Depends(get_db)
):
    """
    Delete a specific photo by ID.
    """
    result = photo_service.delete_photo(db, photo_id=photo_id, delete_file=delete_file)
    if not result:
        raise HTTPException(status_code=404, detail="Fotot ei leitud")
    
    return {"message": "Foto edukalt kustutatud"}

@router.post("/upload", response_model=Dict[str, Any])
async def upload_photo(
    file: UploadFile = File(...),
    date: str = None,
    location: str = None,
    db: Session = Depends(get_db)
):
    """
    Upload a photo without AI identification.
    Simple photo upload for cases when AI plant identification is not needed.
    
    Args:
        file: Photo file to upload
        date: Optional date for the photo (will be extracted from EXIF if available)
        location: Optional location for the photo (will be extracted from EXIF if available)
        db: Database session
    """
    try:
        # Create file_storage directory if it doesn't exist
        file_storage_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "file_storage")
        if not os.path.exists(file_storage_path):
            os.makedirs(file_storage_path)
            logger.info(f"Created directory: {file_storage_path}")
        
        # Generate unique filename and save the file
        permanent_filename = f"{uuid.uuid4()}-{file.filename}"
        permanent_path = os.path.join(file_storage_path, permanent_filename)
        
        # Save the uploaded file
        with open(permanent_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        logger.info(f"File saved to: {permanent_path}")
        
        # If date not provided, use current date
        if not date:
            date = datetime.now().strftime("%Y-%m-%d")
        
        # Save photo info to database (this will also extract EXIF data if available)
        db_photo = photo_service.create_photo(
            db, 
            file_path=permanent_path, 
            date=date,
            location=location
        )
        
        logger.info(f"Photo information saved to database with ID: {db_photo.id}")
        
        return {
            "message": "Foto edukalt üles laaditud", 
            "photo_id": db_photo.id,
            "photo": {
                "id": db_photo.id,
                "file_path": db_photo.file_path,
                "date": db_photo.date,
                "location": db_photo.location
            }
        }
        
    except Exception as e:
        logger.error(f"Error uploading photo: {e}")
        raise HTTPException(status_code=500, detail=f"Viga foto üleslaadimisel: {str(e)}")

@router.post("/extract-metadata", response_model=Dict[str, Any])
async def extract_file_metadata(
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Ekstrakteerib pildifaili metaandmed ilma faili salvestamata.
    Võimaldab klientrakendusel kuvada metaandmeid kasutajale enne pildi üleslaadimist.
    
    Args:
        file: Foto fail, millest metaandmeid lugeda
        db: Andmebaasiühendus (pole tegelikult vaja, aga FastAPI konventsioonide tõttu)
    """
    try:
        # Salvesta üleslaetud fail ajutiselt
        with NamedTemporaryFile(delete=False) as temp_file:
            try:
                shutil.copyfileobj(file.file, temp_file)
                temp_path = temp_file.name
                logger.info(f"Ajutine fail metaandmete lugemiseks salvestatud: {temp_path}")
            except Exception as e:
                logger.error(f"Viga ajutise faili salvestamisel: {str(e)}")
                raise HTTPException(status_code=500, detail=f"Faili üleslaadimise viga: {str(e)}")
        
        try:
            # Ekstrakteeri metaandmed failist - kasutame get_image_metadata funktsiooni, mis juba töötab
            logger.info(f"Ekstrakteerin metaandmeid failist: {temp_path}")
            metadata = get_image_metadata(temp_path)
            logger.info(f"Leitud metaandmed: {metadata}")
            
            # Kui metadata on tühi, proovime otse andmeid GPS osast kätte saada
            if not metadata:
                raw_metadata = run_exiftool(temp_path)
                logger.info(f"Ekstra proovime raw metaandmete lugemist: {raw_metadata}")
                
                metadata = {}
                
                # Otsene GPS positsioon
                if 'Composite' in raw_metadata and 'GPSPosition' in raw_metadata['Composite']:
                    metadata['location'] = raw_metadata['Composite']['GPSPosition']
                    logger.info(f"Found direct GPS position: {metadata['location']}")
                
                # Koordinaadid
                if 'GPS' in raw_metadata:
                    gps_data = raw_metadata['GPS']
                    
                    # Laiuskraad
                    if 'GPSLatitude' in gps_data and 'GPSLatitudeRef' in gps_data:
                        lat_str = gps_data['GPSLatitude']
                        lat_ref = gps_data['GPSLatitudeRef']
                        
                        # Proovime ekstraheerida väärtust kraadides, minutites, sekundites
                        lat_match = re.search(r'(\d+)\s*deg\s*(\d+)\'\s*(\d+\.?\d*)\"', lat_str)
                        if lat_match:
                            degrees, minutes, seconds = map(float, lat_match.groups())
                            latitude = degrees + minutes/60 + seconds/3600
                            if lat_ref.lower() == 'south' or lat_ref.lower() == 's':
                                latitude = -latitude
                            
                            metadata['gps_latitude'] = latitude
                            logger.info(f"Extracted latitude: {latitude}")
                    
                    # Pikkuskraad
                    if 'GPSLongitude' in gps_data and 'GPSLongitudeRef' in gps_data:
                        lng_str = gps_data['GPSLongitude']
                        lng_ref = gps_data['GPSLongitudeRef']
                        
                        # Proovime ekstraheerida väärtust kraadides, minutites, sekundites
                        lng_match = re.search(r'(\d+)\s*deg\s*(\d+)\'\s*(\d+\.?\d*)\"', lng_str)
                        if lng_match:
                            degrees, minutes, seconds = map(float, lng_match.groups())
                            longitude = degrees + minutes/60 + seconds/3600
                            if lng_ref.lower() == 'west' or lng_ref.lower() == 'w':
                                longitude = -longitude
                            
                            metadata['gps_longitude'] = longitude
                            logger.info(f"Extracted longitude: {longitude}")
                            
                    # Kõrgus
                    if 'GPSAltitude' in gps_data:
                        alt_str = gps_data['GPSAltitude']
                        alt_match = re.search(r'(\d+\.?\d*)\s*m', alt_str)
                        if alt_match:
                            altitude = float(alt_match.group(1))
                            metadata['gps_altitude'] = altitude
                            logger.info(f"Extracted altitude: {altitude}")
                
                # Kui koordinaadid on olemas, aga asukoht mitte, siis loome asukoha
                if 'gps_latitude' in metadata and 'gps_longitude' in metadata and 'location' not in metadata:
                    metadata['location'] = f"{metadata['gps_latitude']}, {metadata['gps_longitude']}"
                    logger.info(f"Created location from coordinates: {metadata['location']}")
                
                # Kuupäev
                date_fields = [
                    ('ExifIFD', 'DateTimeOriginal'),
                    ('ExifIFD', 'CreateDate'),
                    ('IFD0', 'ModifyDate')
                ]
                
                for section, field in date_fields:
                    if section in raw_metadata and field in raw_metadata[section]:
                        date_str = raw_metadata[section][field]
                        date_match = re.match(r'(\d{4}):(\d{2}):(\d{2})', date_str)
                        if date_match:
                            year, month, day = date_match.groups()
                            metadata['date'] = f"{year}-{month}-{day}"
                            logger.info(f"Extracted date: {metadata['date']}")
                            break
                
                # Kaamera info
                if 'IFD0' in raw_metadata:
                    if 'Make' in raw_metadata['IFD0']:
                        metadata['camera_make'] = raw_metadata['IFD0']['Make']
                        logger.info(f"Extracted camera make: {metadata['camera_make']}")
                    
                    if 'Model' in raw_metadata['IFD0']:
                        metadata['camera_model'] = raw_metadata['IFD0']['Model']
                        logger.info(f"Extracted camera model: {metadata['camera_model']}")
            
            # Tagasta metaandmed JSON-ina
            logger.info(f"Final metadata: {metadata}")
            return metadata
            
        except Exception as e:
            logger.error(f"Viga metaandmete lugemisel: {str(e)}")
            logger.exception(e)
            raise HTTPException(status_code=500, detail=f"Metaandmete lugemise viga: {str(e)}")
        
        finally:
            # Kustuta ajutine fail
            try:
                os.unlink(temp_path)
                logger.info(f"Ajutine fail kustutatud: {temp_path}")
            except Exception as e:
                logger.error(f"Viga ajutise faili kustutamisel: {str(e)}")
                # Jätkame, kuna see on ainult puhastamine
    
    except Exception as e:
        logger.error(f"Ootamatu viga metaandmete lugemisel: {str(e)}")
        logger.exception(e)
        raise HTTPException(status_code=500, detail=str(e))