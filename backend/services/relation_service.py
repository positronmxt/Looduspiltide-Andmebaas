"""
Relation service module containing business logic for photo-species relations.
"""
from sqlalchemy.orm import Session
from typing import List, Optional

from models.relation_models import PhotoSpeciesRelation

def get_relation(db: Session, relation_id: int) -> Optional[PhotoSpeciesRelation]:
    """
    Get a single photo-species relation by ID.
    
    Args:
        db: Database session
        relation_id: ID of the relation to retrieve
        
    Returns:
        PhotoSpeciesRelation object if found, None otherwise
    """
    return db.query(PhotoSpeciesRelation).filter(PhotoSpeciesRelation.id == relation_id).first()

def get_relations(db: Session, skip: int = 0, limit: int = 100) -> List[PhotoSpeciesRelation]:
    """
    Get a list of photo-species relations with pagination.
    
    Args:
        db: Database session
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List of PhotoSpeciesRelation objects
    """
    return db.query(PhotoSpeciesRelation).offset(skip).limit(limit).all()

def get_relations_by_photo(db: Session, photo_id: int) -> List[PhotoSpeciesRelation]:
    """
    Get all relations for a specific photo.
    
    Args:
        db: Database session
        photo_id: ID of the photo
        
    Returns:
        List of PhotoSpeciesRelation objects
    """
    return db.query(PhotoSpeciesRelation).filter(PhotoSpeciesRelation.photo_id == photo_id).all()

def get_relations_by_species(db: Session, species_id: int) -> List[PhotoSpeciesRelation]:
    """
    Get all relations for a specific species.
    
    Args:
        db: Database session
        species_id: ID of the species
        
    Returns:
        List of PhotoSpeciesRelation objects
    """
    return db.query(PhotoSpeciesRelation).filter(PhotoSpeciesRelation.species_id == species_id).all()

def create_relation(db: Session, photo_id: int, species_id: int, category: str = None) -> PhotoSpeciesRelation:
    """
    Create a new photo-species relation.
    
    Args:
        db: Database session
        photo_id: ID of the photo
        species_id: ID of the species
        category: Category of the relation (e.g., "main subject", "background")
        
    Returns:
        Created PhotoSpeciesRelation object
    """
    db_relation = PhotoSpeciesRelation(photo_id=photo_id, species_id=species_id, category=category)
    db.add(db_relation)
    db.commit()
    db.refresh(db_relation)
    return db_relation