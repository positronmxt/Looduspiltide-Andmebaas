"""
API routes for species operations.
Provides endpoints for CRUD operations on species.
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
from services import species_service
from models.species_models import Species

router = APIRouter(
    prefix="/species",
    tags=["species"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[dict])
def read_species(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Retrieve a list of species with pagination.
    """
    return species_service.get_species(db, skip=skip, limit=limit)

@router.get("/{species_id}", response_model=dict)
def read_species_by_id(species_id: int, db: Session = Depends(get_db)):
    """
    Retrieve a specific species by ID.
    """
    db_species = species_service.get_species_by_id(db, species_id=species_id)
    if db_species is None:
        raise HTTPException(status_code=404, detail="Species not found")
    return db_species

@router.post("/", response_model=dict)
def create_species(
    scientific_name: str = Body(...), 
    common_name: Optional[str] = Body(None), 
    family: Optional[str] = Body(None), 
    db: Session = Depends(get_db)
):
    """
    Create a new species.
    """
    return species_service.create_species(
        db=db, 
        scientific_name=scientific_name, 
        common_name=common_name, 
        family=family
    )

@router.put("/{species_id}", response_model=dict)
def update_species(
    species_id: int, 
    scientific_name: Optional[str] = Body(None), 
    common_name: Optional[str] = Body(None), 
    family: Optional[str] = Body(None), 
    db: Session = Depends(get_db)
):
    """
    Update a specific species by ID.
    """
    updated_species = species_service.update_species(
        db=db, 
        species_id=species_id, 
        scientific_name=scientific_name, 
        common_name=common_name, 
        family=family
    )
    
    if updated_species is None:
        raise HTTPException(status_code=404, detail="Liiki ei leitud")
    
    return updated_species

@router.delete("/{species_id}")
def delete_species(species_id: int, db: Session = Depends(get_db)):
    """
    Delete a specific species by ID.
    """
    result = species_service.delete_species(db, species_id=species_id)
    if not result:
        raise HTTPException(status_code=404, detail="Liiki ei leitud")
    
    return {"message": "Liik edukalt kustutatud"}