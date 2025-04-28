"""
Taimeliigi tuvastamise API moodul.
Pakub API lõpp-punkte taimeliikide tuvastamiseks.
"""
from fastapi import APIRouter, File, UploadFile, Depends, HTTPException
from sqlalchemy.orm import Session
import shutil
import os
import uuid
from typing import List
from tempfile import NamedTemporaryFile
from datetime import datetime
import logging

from database import get_db
from utils.plant_identification import PlantIdClient
from models.species_models import Species
from models.photo_models import Photo
from models.relation_models import PhotoSpeciesRelation
from services import species_service, photo_service, relation_service

# Seadista logi
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/identify",
    tags=["taime-tuvastus"],
    responses={404: {"description": "Ei leitud"}},
)

@router.post("/", response_model=List[dict])
async def identify_plant(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    api_key: str = None,
    location: str = None
):
    """
    Tuvasta taimeliik üleslaetud pildil.
    """
    # Salvesta üleslaetud fail ajutiselt
    with NamedTemporaryFile(delete=False) as temp_file:
        try:
            shutil.copyfileobj(file.file, temp_file)
            temp_path = temp_file.name
            logger.info(f"Ajutine fail salvestatud: {temp_path}")
        except Exception as e:
            logger.error(f"Viga ajutise faili salvestamisel: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Faili üleslaadimise viga: {str(e)}")
    
    try:
        # Initsialiseeri taimetuvastuse klient päris API-ga (mitte simulatsiooniga)
        plant_id_client = PlantIdClient(api_key=api_key, use_simulation=False)
        logger.info("Plant ID Client initsialiseeritud")
        
        # Tuvasta taimed pildil
        identification_result = plant_id_client.identify_plant(temp_path)
        logger.info("Tuvastamine õnnestus")
        
        # Ekstrakteeri struktureeritud liikide andmed
        species_data = plant_id_client.extract_species_data(identification_result)
        logger.info(f"Tuvastati {len(species_data)} liiki")
        
        try:
            # Salvesta foto püsivalt file_storage kataloogi
            file_storage_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "file_storage")
            if not os.path.exists(file_storage_path):
                os.makedirs(file_storage_path)
                logger.info(f"Loodud kataloog: {file_storage_path}")
            
            permanent_filename = f"{uuid.uuid4()}-{file.filename}"
            permanent_path = os.path.join(file_storage_path, permanent_filename)
            
            logger.info(f"Kopeerin faili asukohast {temp_path} asukohta {permanent_path}")
            shutil.copy(temp_path, permanent_path)
            logger.info(f"Fail kopeeritud püsivasse asukohta: {permanent_path}")
            
            # Salvesta foto info andmebaasi
            current_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            db_photo = photo_service.create_photo(
                db, 
                file_path=permanent_path, 
                date=current_date,
                location=location
            )
            logger.info(f"Foto info salvestatud andmebaasi ID-ga: {db_photo.id}")
            
            # Salvesta tuvastatud liigid ja seosed fotoga
            if species_data:
                for i, species_info in enumerate(species_data):
                    if species_info["probability"] > 0.5:  # Salvesta kõik piisavalt suure tõenäosusega liigid
                        # Kontrolli, kas liik on juba andmebaasis
                        existing_species = db.query(Species).filter_by(
                            scientific_name=species_info["scientific_name"]
                        ).first()
                        
                        # Kui ei ole, loo uus liigi kirje
                        if not existing_species:
                            common_name = species_info["common_names"][0] if species_info["common_names"] else None
                            db_species = species_service.create_species(
                                db,
                                scientific_name=species_info["scientific_name"],
                                common_name=common_name,
                                family=species_info["family"]
                            )
                            species_id = db_species.id
                            logger.info(f"Uus liik salvestatud ID-ga: {species_id}")
                        else:
                            species_id = existing_species.id
                            logger.info(f"Olemasolev liik leitud ID-ga: {species_id}")
                        
                        # Loo seos foto ja liigi vahel
                        category = "primary" if i == 0 else "secondary"
                        relation = relation_service.create_relation(
                            db,
                            photo_id=db_photo.id,
                            species_id=species_id,
                            category=category
                        )
                        logger.info(f"Loodud seos foto ID {db_photo.id} ja liigi ID {species_id} vahel, kategooria: {category}")
            
        except Exception as e:
            logger.error(f"Viga failide või andmebaasi operatsioonidega: {str(e)}")
            logger.exception(e)
            # Jätkame, et vähemalt tuvastuse tulemused tagastada
        
        return species_data
    
    except Exception as e:
        logger.error(f"Tuvastamise viga: {str(e)}")
        logger.exception(e)
        raise HTTPException(status_code=500, detail=str(e))
    
    finally:
        # Puhasta ajutine fail
        try:
            os.unlink(temp_path)
            logger.info(f"Ajutine fail kustutatud: {temp_path}")
        except Exception as e:
            logger.error(f"Viga ajutise faili kustutamisel: {str(e)}")
            # Jätkame, kuna see on ainult puhastamine

@router.post("/existing/{photo_id}", response_model=List[dict])
async def identify_existing_photo(
    photo_id: int,
    db: Session = Depends(get_db),
    api_key: str = None
):
    """
    Tuvasta taimeliik olemasoleval pildil andmebaasist.
    """
    # Kontrolli, kas foto eksisteerib
    db_photo = photo_service.get_photo(db, photo_id=photo_id)
    if not db_photo:
        raise HTTPException(status_code=404, detail="Fotot ei leitud")
    
    if isinstance(db_photo, dict):
        file_path = db_photo["file_path"]
    else:
        file_path = db_photo.file_path
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail=f"Faili ei leitud: {file_path}")
    
    try:
        # Initsialiseeri taimetuvastuse klient
        plant_id_client = PlantIdClient(api_key=api_key, use_simulation=False)
        logger.info(f"Plant ID Client initsialiseeritud foto ID-ga {photo_id}")
        
        # Tuvasta taimed pildil
        identification_result = plant_id_client.identify_plant(file_path)
        logger.info(f"Olemasoleva foto (ID: {photo_id}) tuvastamine õnnestus")
        
        # Ekstrakteeri struktureeritud liikide andmed
        species_data = plant_id_client.extract_species_data(identification_result)
        logger.info(f"Tuvastati {len(species_data)} liiki fotol ID: {photo_id}")
        
        # Eemalda vanad seosed, kui need eksisteerivad
        existing_relations = db.query(PhotoSpeciesRelation).filter_by(photo_id=photo_id).all()
        if existing_relations:
            for relation in existing_relations:
                db.delete(relation)
            db.commit()
            logger.info(f"Eemaldatud {len(existing_relations)} vana seost fotole ID: {photo_id}")
        
        # Salvesta tuvastatud liigid ja seosed fotoga
        if species_data:
            for i, species_info in enumerate(species_data):
                if species_info["probability"] > 0.5:  # Salvesta kõik piisavalt suure tõenäosusega liigid
                    # Kontrolli, kas liik on juba andmebaasis
                    existing_species = db.query(Species).filter_by(
                        scientific_name=species_info["scientific_name"]
                    ).first()
                    
                    # Kui ei ole, loo uus liigi kirje
                    if not existing_species:
                        common_name = species_info["common_names"][0] if species_info["common_names"] else None
                        db_species = species_service.create_species(
                            db,
                            scientific_name=species_info["scientific_name"],
                            common_name=common_name,
                            family=species_info["family"]
                        )
                        species_id = db_species.id
                        logger.info(f"Uus liik salvestatud ID-ga: {species_id}")
                    else:
                        species_id = existing_species.id
                        logger.info(f"Olemasolev liik leitud ID-ga: {species_id}")
                    
                    # Loo seos foto ja liigi vahel
                    category = "primary" if i == 0 else "secondary"
                    relation = relation_service.create_relation(
                        db,
                        photo_id=photo_id,
                        species_id=species_id,
                        category=category
                    )
                    logger.info(f"Loodud seos foto ID {photo_id} ja liigi ID {species_id} vahel, kategooria: {category}")
        
        return species_data
    
    except Exception as e:
        logger.error(f"Olemasoleva foto tuvastamise viga: {str(e)}")
        logger.exception(e)
        raise HTTPException(status_code=500, detail=str(e))