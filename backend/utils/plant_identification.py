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
import json

logger = logging.getLogger(__name__)

class PlantIdClient:
    """Client for interacting with external plant identification APIs or using simulated data."""
    
    def __init__(self, api_key: str = None, use_simulation: bool = False):
        """
        Initialize the plant identification client.
        
        Args:
            api_key: API key for the plant identification service. 
                    If None, will try to get from environment variable PLANT_ID_API_KEY
            use_simulation: Whether to use simulated data instead of making real API calls.
                          Defaults to False to use real API.
        """
        # Remove hardcoded API key for security reasons
        self.api_key = api_key or os.environ.get("PLANT_ID_API_KEY") or ""
        self.use_simulation = use_simulation
        self.api_url = "https://api.plant.id/v2/identify"

        logger.info(f"PlantIdClient initialized, simulation mode: {self.use_simulation}")
        
        # Check if API key is missing and warn
        if not self.api_key and not self.use_simulation:
            logger.warning("Plant.id API key is missing. Please set the PLANT_ID_API_KEY environment variable or in database settings.")

    def identify_plant(self, image_path: str) -> Dict[str, Any]:
        """
        Identify plant species in an image.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            Dictionary containing identification results
            
        Raises:
            Exception: If API key is missing and simulation mode is disabled
        """
        # Kui API võti on puudu ja simulatsioonirežiim pole lubatud, tõsta viga
        if not self.api_key or self.api_key.strip() == "":
            if not self.use_simulation:
                error_msg = "API võti puudub. Taimetuvastuse jaoks on vaja seadistada Plant.ID API võti administreerimislehel."
                logger.error(error_msg)
                raise Exception(error_msg)
            else:
                logger.info("API võti puudub, kasutan simulatsioonirežiimi")
                return self._get_simulated_response()
            
        if self.use_simulation:
            logger.info("Using simulated plant identification")
            return self._get_simulated_response()
        
        try:
            logger.info(f"Sending request to Plant.id API: {image_path}")
            # Read image binary data
            with open(image_path, "rb") as img_file:
                img_data = img_file.read()
            
            # Encode image to base64
            encoded_img = base64.b64encode(img_data).decode("utf-8")
            
            # Prepare API request
            payload = {
                "api_key": self.api_key,
                "images": [encoded_img],
                "modifiers": ["similar_images"],
                "plant_details": ["common_names", "url", "wiki_description", "taxonomy"]
            }
            
            # Send request
            response = requests.post(self.api_url, json=payload)
            logger.info(f"Request sent, response status: {response.status_code}")
            
            # Check response
            if response.status_code != 200:
                logger.error(f"API error: {response.status_code}, {response.text}")
                if self.use_simulation:
                    # Kui simulatsioon on lubatud, kasuta seda tagavaraplaanina
                    logger.info("API viga, kasutan simulatsiooni tagavaraplaanina")
                    return self._get_simulated_response()
                else:
                    # Muidu tõsta viga
                    error_msg = f"Viga Plant.id API-s: {response.status_code}, {response.text}"
                    raise Exception(error_msg)
            
            # Log partial response for debugging
            response_json = response.json()
            logger.info(f"Received API response with keys: {list(response_json.keys())}")
            
            if "suggestions" not in response_json or not response_json["suggestions"]:
                logger.warning("Response does not contain 'suggestions' key or it's empty!")
                if self.use_simulation:
                    logger.info("Vastuses pole soovitusi, kasutan simulatsiooni tagavaraplaanina")
                    return self._get_simulated_response()
                else:
                    # Muidu tagasta tühi massiiv kui pole simulatsioonirežiim
                    return {"suggestions": []}
            
            # Return response
            return response_json
            
        except Exception as e:
            logger.error(f"Error with Plant.id API: {str(e)}")
            if self.use_simulation:
                # Kui simulatsioon on lubatud, kasuta seda tagavaraplaanina
                logger.info("API viga, kasutan simulatsiooni tagavaraplaanina")
                return self._get_simulated_response()
            else:
                # Muidu tõsta viga edasi
                raise

    def extract_species_data(self, api_response: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Extract structured species data from the API response.
        
        Args:
            api_response: API response
            
        Returns:
            List of identified species with structured data
        """
        try:
            # Log the input for debugging
            logger.info(f"Extracting species data from response with keys: {list(api_response.keys())}")
            
            results = []
            suggestions = api_response.get("suggestions", [])
            
            if not suggestions:
                logger.warning("No suggestions found in API response!")
                logger.debug(f"Raw API response snippet: {str(api_response)[:300]}...")
                # Kui vastuses pole soovitusi ja simulatsioonirežiim pole lubatud, tagasta tühi massiiv
                if not self.use_simulation:
                    logger.info("Vastuses pole soovitusi, tagastan tühja massiivi")
                    return []
                else:
                    # Simulatsioonirežiimis kasuta simuleeritud andmeid
                    logger.info("Vastuses pole soovitusi, kasutan simuleeritud andmeid")
                    sim_response = self._get_simulated_response()
                    return self.extract_species_data(sim_response)
                
            logger.info(f"Processing {len(suggestions)} suggestions")
            
            for i, suggestion in enumerate(suggestions):
                logger.debug(f"Processing suggestion {i+1}/{len(suggestions)}")
                
                # Check if suggestion has all required fields
                if "plant_name" not in suggestion:
                    logger.warning(f"Suggestion {i+1} missing 'plant_name' field!")
                    continue
                    
                plant_details = suggestion.get("plant_details", {})
                common_names = plant_details.get("common_names", [])
                
                # Get wiki description safely
                wiki_desc = ""
                wiki_description = plant_details.get("wiki_description", {})
                if isinstance(wiki_description, dict):
                    wiki_desc = wiki_description.get("value", "")
                
                # Get taxonomy data safely
                taxonomy = plant_details.get("taxonomy", {})
                family = taxonomy.get("family", "") if isinstance(taxonomy, dict) else ""
                
                species_data = {
                    "scientific_name": suggestion.get("plant_name", ""),
                    "common_names": common_names,
                    "probability": suggestion.get("probability", 0),
                    "family": family,
                    "description": wiki_desc
                }
                results.append(species_data)
                
            logger.info(f"Successfully extracted data for {len(results)} species")
            return results
        except Exception as e:
            logger.error(f"Error extracting data: {str(e)}")
            # Log the input structure that caused the error
            try:
                logger.error(f"API response structure that caused error: {json.dumps(api_response)[:500]}...")
            except:
                logger.error("Could not serialize API response for logging")
                
            # Vea korral tagasta tühi massiiv kui simulatsioonirežiim pole lubatud
            if not self.use_simulation:
                logger.info("Viga andmete töötlemisel, tagastan tühja massiivi")
                return []
            else:
                # Simulatsioonirežiimis kasuta simuleeritud andmeid
                logger.info("Viga andmete töötlemisel, kasutan simuleeritud andmeid")
                sim_response = self._get_simulated_response()
                return self.extract_species_data(sim_response)

    def _get_simulated_response(self) -> Dict[str, Any]:
        """
        Return simulated Plant.id API response.
        Used for testing or when API is unavailable.
        
        Returns:
            Dictionary containing simulated identification results
        """
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
                    "url": "https://en.wikipedia.org/wiki/Taraxacum_officinale",
                    "wiki_description": {
                        "value": "Võilill on laialt levinud taim..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Bellis_perennis",
                    "wiki_description": {
                        "value": "Kirikakar on mitmeaastane rohttaim..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Tulipa_gesneriana",
                    "wiki_description": {
                        "value": "Tulp on kevadel õitsev sibullill..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Primula_veris",
                    "wiki_description": {
                        "value": "Nurmenukk on mitmeaastane kevadel õitsev taim..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Lily_of_the_valley",
                    "wiki_description": {
                        "value": "Maikelluke on mürgine, kuid dekoratiivne kevadine metsataim..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Leucanthemum_vulgare",
                    "wiki_description": {
                        "value": "Härjasilm on mitmeaastane taim..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Trifolium_repens",
                    "wiki_description": {
                        "value": "Valge ristik on mitmeaastane rohttaim..."
                    }
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
                    "url": "https://en.wikipedia.org/wiki/Campanula_patula",
                    "wiki_description": {
                        "value": "Harilik kellukas on ühe- või kaheaastane taim..."
                    }
                }
            }
        ]
        
        # Vali juhuslikult 3-5 taime simulatsiooni jaoks
        main_suggestions = random.sample(common_plants, min(3, len(common_plants)))
        secondary_suggestions = random.sample(secondary_plants, min(2, len(secondary_plants)))
        
        logger.info("Generated simulated response with plant suggestions")
        return {
            "suggestions": main_suggestions + secondary_suggestions
        }