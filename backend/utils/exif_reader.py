"""
Utility module for reading EXIF metadata from images.
Uses the exiftool command-line utility to extract image metadata.
"""
import subprocess
import json
import re
import logging
import shutil
import os
from datetime import datetime
from typing import Dict, Any, Optional, Tuple

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_exiftool_installed() -> bool:
    """
    Check if exiftool is installed and available on the system.
    
    Returns:
        Boolean indicating whether exiftool is available
    """
    try:
        # Try to find the exiftool executable
        exiftool_path = shutil.which("exiftool")
        if not exiftool_path:
            logger.error("exiftool not found in system PATH. Please install it with: sudo apt-get install libimage-exiftool-perl")
            return False
        
        # Run a test command
        version_check = subprocess.run(["exiftool", "-ver"], capture_output=True, text=True, check=True)
        logger.info(f"exiftool installed, version: {version_check.stdout.strip()}")
        return True
    except subprocess.SubprocessError as e:
        logger.error(f"Error checking exiftool: {e}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error checking exiftool: {e}")
        return False

# Check at module load time if exiftool is available
EXIFTOOL_AVAILABLE = check_exiftool_installed()

def run_exiftool(file_path: str) -> Dict[str, Any]:
    """
    Run exiftool on an image file and return the metadata as a dictionary.
    
    Args:
        file_path: Path to the image file
        
    Returns:
        Dictionary containing the image metadata
    """
    if not EXIFTOOL_AVAILABLE:
        logger.error("exiftool is not available. Install it with: sudo apt-get install libimage-exiftool-perl")
        return {}
    
    if not os.path.exists(file_path):
        logger.error(f"File does not exist: {file_path}")
        return {}
    
    try:
        # Run exiftool to get JSON output
        logger.info(f"Running exiftool on file: {file_path}")
        cmd = ["exiftool", "-json", "-a", "-u", "-g1", file_path]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        if result.stdout:
            try:
                metadata = json.loads(result.stdout)[0]  # exiftool returns a list with one item
                logger.info(f"Metadata successfully extracted from {file_path}")
                
                # Debug log to see what GPS data was found
                gps_fields = {k: v for k, v in metadata.items() if "GPS" in k}
                if gps_fields:
                    logger.info(f"GPS data found in image: {gps_fields}")
                else:
                    logger.info("No GPS data found in image metadata")
                
                return metadata
            except (json.JSONDecodeError, IndexError) as e:
                logger.error(f"Error parsing exiftool output: {e}")
                logger.error(f"Raw output: {result.stdout[:200]}...")
                return {}
        else:
            logger.warning(f"No output from exiftool for file: {file_path}")
            return {}
    except subprocess.CalledProcessError as e:
        logger.error(f"Error running exiftool (return code {e.returncode}): {e}")
        if e.stderr:
            logger.error(f"Error details: {e.stderr}")
        return {}
    except Exception as e:
        logger.error(f"Unexpected error processing file {file_path}: {e}")
        return {}

def extract_date(metadata: Dict[str, Any]) -> Optional[str]:
    """
    Extract the date from image metadata in YYYY-MM-DD format.
    
    Args:
        metadata: Dictionary containing image metadata
        
    Returns:
        Date string in YYYY-MM-DD format, or None if not available
    """
    # Try different date fields in order of preference
    date_fields = [
        "EXIF:DateTimeOriginal",
        "EXIF:CreateDate",
        "EXIF:ModifyDate",
        "File:FileModifyDate"
    ]
    
    for field in date_fields:
        if field in metadata:
            # Extract date part from datetime string (format: YYYY:MM:DD HH:MM:SS)
            date_match = re.match(r"(\d{4}):(\d{2}):(\d{2})", metadata[field])
            if date_match:
                year, month, day = date_match.groups()
                return f"{year}-{month}-{day}"
    
    return None

def extract_location(metadata: Dict[str, Any]) -> Optional[str]:
    """
    Try to extract location information from the metadata.
    
    Args:
        metadata: Dictionary containing image metadata
        
    Returns:
        Location string if available, otherwise None
    """
    # If there's GPS data, return coordinates as the location
    if "Composite:GPSPosition" in metadata:
        return metadata["Composite:GPSPosition"]
    elif all(key in metadata for key in ["GPS:GPSLatitude", "GPS:GPSLongitude"]):
        lat = metadata["GPS:GPSLatitude"]
        lng = metadata["GPS:GPSLongitude"]
        return f"{lat}, {lng}"
    
    return None

def extract_gps_coordinates(metadata: Dict[str, Any]) -> Tuple[Optional[float], Optional[float], Optional[float]]:
    """
    Extract GPS coordinates from the metadata.
    
    Args:
        metadata: Dictionary containing image metadata
        
    Returns:
        Tuple of (latitude, longitude, altitude) or (None, None, None) if not available
    """
    latitude = longitude = altitude = None
    
    # Extract latitude
    if "GPS:GPSLatitude" in metadata and "GPS:GPSLatitudeRef" in metadata:
        lat = metadata["GPS:GPSLatitude"]
        lat_ref = metadata["GPS:GPSLatitudeRef"]
        
        # Convert DMS format to decimal
        if isinstance(lat, str) and "deg" in lat:
            # Parse format like: "57 deg 46' 28.17" N"
            parts = re.match(r"(\d+)\s*deg\s*(\d+)'\s*(\d+\.?\d*)\"", lat)
            if parts:
                degrees, minutes, seconds = map(float, parts.groups())
                latitude = degrees + minutes/60 + seconds/3600
                
                if lat_ref == "S":
                    latitude = -latitude
    
    # Extract longitude
    if "GPS:GPSLongitude" in metadata and "GPS:GPSLongitudeRef" in metadata:
        lng = metadata["GPS:GPSLongitude"]
        lng_ref = metadata["GPS:GPSLongitudeRef"]
        
        # Convert DMS format to decimal
        if isinstance(lng, str) and "deg" in lng:
            # Parse format like: "26 deg 2' 12.45" E"
            parts = re.match(r"(\d+)\s*deg\s*(\d+)'\s*(\d+\.?\d*)\"", lng)
            if parts:
                degrees, minutes, seconds = map(float, parts.groups())
                longitude = degrees + minutes/60 + seconds/3600
                
                if lng_ref == "W":
                    longitude = -longitude
    
    # Extract altitude
    if "GPS:GPSAltitude" in metadata:
        alt = metadata["GPS:GPSAltitude"]
        if isinstance(alt, str) and "m" in alt:
            # Parse format like: "83 m"
            alt_match = re.match(r"(\d+\.?\d*)\s*m", alt)
            if alt_match:
                altitude = float(alt_match.group(1))
                
                # Consider altitude reference (above/below sea level)
                if "GPS:GPSAltitudeRef" in metadata and metadata["GPS:GPSAltitudeRef"] == "Below Sea Level":
                    altitude = -altitude
    
    return latitude, longitude, altitude

def get_image_metadata(file_path: str) -> Dict[str, Any]:
    """
    Get important metadata from an image file.
    
    Args:
        file_path: Path to the image file
        
    Returns:
        Dictionary containing extracted metadata
    """
    metadata = run_exiftool(file_path)
    if not metadata:
        return {}
    
    result = {}
    
    # Extract date from various possible fields
    if 'ExifIFD' in metadata and 'DateTimeOriginal' in metadata['ExifIFD']:
        date_str = metadata['ExifIFD']['DateTimeOriginal']
        date_match = re.match(r'(\d{4}):(\d{2}):(\d{2})', date_str)
        if date_match:
            year, month, day = date_match.groups()
            result['date'] = f"{year}-{month}-{day}"
    elif 'ExifIFD' in metadata and 'CreateDate' in metadata['ExifIFD']:
        date_str = metadata['ExifIFD']['CreateDate']
        date_match = re.match(r'(\d{4}):(\d{2}):(\d{2})', date_str)
        if date_match:
            year, month, day = date_match.groups()
            result['date'] = f"{year}-{month}-{day}"
    elif 'IFD0' in metadata and 'ModifyDate' in metadata['IFD0']:
        date_str = metadata['IFD0']['ModifyDate']
        date_match = re.match(r'(\d{4}):(\d{2}):(\d{2})', date_str)
        if date_match:
            year, month, day = date_match.groups()
            result['date'] = f"{year}-{month}-{day}"
    
    # Extract GPS coordinates from GPS section
    if 'GPS' in metadata:
        gps_data = metadata['GPS']
        
        # Extract latitude
        if 'GPSLatitude' in gps_data and 'GPSLatitudeRef' in gps_data:
            lat_str = gps_data['GPSLatitude']
            lat_ref = gps_data['GPSLatitudeRef']
            
            lat_match = re.search(r'(\d+)\s*deg\s*(\d+)\'\s*(\d+\.?\d*)\"', lat_str)
            if lat_match:
                degrees, minutes, seconds = map(float, lat_match.groups())
                latitude = degrees + minutes/60 + seconds/3600
                if lat_ref == 'South' or lat_ref == 'S':
                    latitude = -latitude
                
                result['gps_latitude'] = latitude
        
        # Extract longitude
        if 'GPSLongitude' in gps_data and 'GPSLongitudeRef' in gps_data:
            lng_str = gps_data['GPSLongitude']
            lng_ref = gps_data['GPSLongitudeRef']
            
            lng_match = re.search(r'(\d+)\s*deg\s*(\d+)\'\s*(\d+\.?\d*)\"', lng_str)
            if lng_match:
                degrees, minutes, seconds = map(float, lng_match.groups())
                longitude = degrees + minutes/60 + seconds/3600
                if lng_ref == 'West' or lng_ref == 'W':
                    longitude = -longitude
                
                result['gps_longitude'] = longitude
        
        # Extract altitude
        if 'GPSAltitude' in gps_data:
            alt_str = gps_data['GPSAltitude']
            alt_match = re.search(r'(\d+\.?\d*)\s*m', alt_str)
            if alt_match:
                altitude = float(alt_match.group(1))
                result['gps_altitude'] = altitude
    
    # Extract location from Composite section or create from coordinates
    if 'Composite' in metadata and 'GPSPosition' in metadata['Composite']:
        result['location'] = metadata['Composite']['GPSPosition']
    elif 'gps_latitude' in result and 'gps_longitude' in result:
        result['location'] = f"{result['gps_latitude']}, {result['gps_longitude']}"
    
    # Extract camera information
    if 'IFD0' in metadata:
        if 'Make' in metadata['IFD0']:
            result['camera_make'] = metadata['IFD0']['Make']
        
        if 'Model' in metadata['IFD0']:
            result['camera_model'] = metadata['IFD0']['Model']
    
    logger.info(f"Extracted metadata from {file_path}: {result}")
    
    return result