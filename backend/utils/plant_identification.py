"""
Plant identification API client module.
Provides functionality to identify plant species using external API services or simulated data.
"""
import requests
import os
import random
from typing import List, Dict, Any, Optional
import base64
import logging

logger = logging.getLogger(__name__)

class PlantIdClient:
    """Client for interacting with external plant identification APIs or using simulated data."""
    
    def __init__(self, api_key: str = None, use_simulation: bool = False):
        """
        Initialize the plant identification client.
        
        Args:
            api_key: API key for the plant identification service. 
                    If None, will try to get from environment variable PLANT_ID_API_KEY
                    or use the default API key.
            use_simulation: Whether to use simulated data instead of making real API calls.
                          Defaults to False to use real API.
        """
        # Set default API key if none provided
        default_api_key = "gkUrPir7M5moavv0Hp4PFGl68BC6uYlRmPi35aU3YZhC2GPclZ"
        
        # Kasuta päris API-t simulatsiooni asemel
        self.use_simulation = False
        
        self.api_key = api_key or os.environ.get("PLANT_ID_API_KEY") or default_api_key
            
        self.api_url = "https://api.plant.id/v2/identify"
        
    def identify_plant(self, image_path: str) -> Dict[str, Any]:
        """
        Identify plant species in an image.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Dictionary containing identification results
        """
        if self.use_simulation:
            return self._get_simulated_response(image_path)
        else:
            return self._call_plant_id_api(image_path)
    
    def _call_plant_id_api(self, image_path: str) -> Dict[str, Any]:
        """
        Call the Plant.id API to identify plants in the image.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Dictionary containing API response
        """
        try:
            # Read the image file and encode it as base64
            with open(image_path, "rb") as file:
                image_data = file.read()
            
            base64_image = base64.b64encode(image_data).decode("utf-8")
            
            # Prepare the data for the API request
            data = {
                "api_key": self.api_key,
                "images": [base64_image],
                "modifiers": ["crops_fast", "similar_images"],
                "plant_language": "et",  # Estonian language for plant names
                "plant_details": ["common_names", "url", "wiki_description", "taxonomy", "synonyms"]
            }
            
            # Make the request to the API
            logger.info(f"Making request to Plant.id API for image: {os.path.basename(image_path)}")
            response = requests.post(self.api_url, json=data)
            
            # Check if the request was successful
            if response.status_code != 200:
                logger.error(f"Plant.id API returned error: {response.status_code}, {response.text}")
                return {"error": f"API request failed with status code {response.status_code}"}
            
            # Parse the response
            result = response.json()
            logger.info(f"Received response from Plant.id API with {len(result.get('suggestions', []))} suggestions")
            
            return result
            
        except Exception as e:
            logger.error(f"Error calling Plant.id API: {str(e)}")
            # Kui päris API-ga on probleem, tagasta lihtsustatud andmed
            return {"error": str(e), "suggestions": []}
    
    def _get_simulated_response(self, image_path: str) -> Dict[str, Any]:
        """
        Return simulated plant identification response for development purposes.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Dictionary containing simulated identification results
        """
        # Get the filename to determine which simulation to use
        filename = os.path.basename(image_path).lower()
        file_id = hash(image_path) % 100  # Kasuta faili tee räsi väärtust juhuslikkuse lisamiseks
        
        # Common plants database for simulation
        common_plants = [
            {
                "plant_name": "Taraxacum officinale",
                "probability": 0.95,
                "plant_details": {
                    "common_names": ["Võilill", "Dandelion", "Common dandelion"],
                    "taxonomy": {
                        "family": "Asteraceae",
                        "genus": "Taraxacum"
                    },
                    "url": "https://en.wikipedia.org/wiki/Taraxacum_officinale"
                }
            },
            {
                "plant_name": "Bellis perennis",
                "probability": 0.92,
                "plant_details": {
                    "common_names": ["Kirikakar", "Common daisy", "Lawn daisy"],
                    "taxonomy": {
                        "family": "Asteraceae",
                        "genus": "Bellis"
                    },
                    "url": "https://en.wikipedia.org/wiki/Bellis_perennis"
                }
            },
            {
                "plant_name": "Tulipa gesneriana",
                "probability": 0.98,
                "plant_details": {
                    "common_names": ["Tulp", "Garden tulip", "Didier's tulip"],
                    "taxonomy": {
                        "family": "Liliaceae",
                        "genus": "Tulipa"
                    },
                    "url": "https://en.wikipedia.org/wiki/Tulipa_gesneriana"
                }
            },
            {
                "plant_name": "Primula veris",
                "probability": 0.91,
                "plant_details": {
                    "common_names": ["Nurmenukk", "Cowslip", "Spring primrose"],
                    "taxonomy": {
                        "family": "Primulaceae",
                        "genus": "Primula"
                    },
                    "url": "https://en.wikipedia.org/wiki/Primula_veris"
                }
            },
            {
                "plant_name": "Convallaria majalis",
                "probability": 0.94,
                "plant_details": {
                    "common_names": ["Maikelluke", "Lily of the valley"],
                    "taxonomy": {
                        "family": "Asparagaceae",
                        "genus": "Convallaria"
                    },
                    "url": "https://en.wikipedia.org/wiki/Lily_of_the_valley"
                }
            }
        ]
        
        # Second level suggestions with lower probability
        secondary_plants = [
            {
                "plant_name": "Leucanthemum vulgare",
                "probability": 0.42,
                "plant_details": {
                    "common_names": ["Härjasilm", "Oxeye daisy", "Marguerite"],
                    "taxonomy": {
                        "family": "Asteraceae",
                        "genus": "Leucanthemum"
                    },
                    "url": "https://en.wikipedia.org/wiki/Leucanthemum_vulgare"
                }
            },
            {
                "plant_name": "Trifolium repens",
                "probability": 0.38,
                "plant_details": {
                    "common_names": ["Valge ristik", "White clover", "Dutch clover"],
                    "taxonomy": {
                        "family": "Fabaceae",
                        "genus": "Trifolium"
                    },
                    "url": "https://en.wikipedia.org/wiki/Trifolium_repens"
                }
            },
            {
                "plant_name": "Campanula patula",
                "probability": 0.45,
                "plant_details": {
                    "common_names": ["Harilik kellukas", "Spreading bellflower"],
                    "taxonomy": {
                        "family": "Campanulaceae",
                        "genus": "Campanula"
                    },
                    "url": "https://en.wikipedia.org/wiki/Campanula_patula"
                }
            }
        ]
        
        # Choose primary suggestion using more varied logic
        primary_suggestion = None
        
        # Kasuta kombinatsiooni failinimest ja räsist, et määrata taimede valik
        return {
            "suggestions": common_plants + secondary_plants
        }
    
    def extract_species_data(self, identification_result: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Extract structured species data from the identification result.
        
        Args:
            identification_result: Raw result from the identify_plant method
            
        Returns:
            List of identified species with structured data
        """
        species_list = []
        
        if "error" in identification_result:
            logger.error(f"Error in identification result: {identification_result['error']}")
            return species_list
            
        if "suggestions" not in identification_result:
            return species_list
        
        for suggestion in identification_result["suggestions"]:
            species_data = {
                "scientific_name": suggestion.get("plant_name", ""),
                "probability": suggestion.get("probability", 0),
                "common_names": suggestion.get("plant_details", {}).get("common_names", []),
                "family": suggestion.get("plant_details", {}).get("taxonomy", {}).get("family", ""),
                "genus": suggestion.get("plant_details", {}).get("taxonomy", {}).get("genus", "")
            }
            species_list.append(species_data)
        
        return species_list