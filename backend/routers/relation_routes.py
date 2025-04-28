"""
API routes for photo-species relation operations.
Provides endpoints for CRUD operations on relations between photos and species.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from services import relation_service
from models.relation_models import PhotoSpeciesRelation

router = APIRouter(
    prefix="/relations",
    tags=["relations"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[dict])
def read_relations(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Retrieve a list of photo-species relations with pagination.
    """
    return relation_service.get_relations(db, skip=skip, limit=limit)

@router.get("/photo/{photo_id}", response_model=List[dict])
def read_relations_by_photo(photo_id: int, db: Session = Depends(get_db)):
    """
    Retrieve all relations for a specific photo.
    """
    return relation_service.get_relations_by_photo(db, photo_id=photo_id)

@router.get("/species/{species_id}", response_model=List[dict])
def read_relations_by_species(species_id: int, db: Session = Depends(get_db)):
    """
    Retrieve all relations for a specific species.
    """
    return relation_service.get_relations_by_species(db, species_id=species_id)