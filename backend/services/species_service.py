"""
Species service module containing business logic for species operations.
"""
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any

from models.species_models import Species
from models.relation_models import PhotoSpeciesRelation

def model_to_dict(model) -> Dict[str, Any]:
    """
    Convert a SQLAlchemy model instance to a dictionary.
    
    Args:
        model: SQLAlchemy model instance
        
    Returns:
        Dictionary representation of the model
    """
    return {column.name: getattr(model, column.name) for column in model.__table__.columns}

def get_species_by_id(db: Session, species_id: int) -> Optional[Dict[str, Any]]:
    """
    Get a single species by ID.
    
    Args:
        db: Database session
        species_id: ID of the species to retrieve
        
    Returns:
        Dictionary representation of the species if found, None otherwise
    """
    species = db.query(Species).filter(Species.id == species_id).first()
    if species:
        return model_to_dict(species)
    return None

def get_species(db: Session, skip: int = 0, limit: int = 100) -> List[Dict[str, Any]]:
    """
    Get a list of species with pagination.
    
    Args:
        db: Database session
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List of dictionaries representing Species objects
    """
    species_list = db.query(Species).offset(skip).limit(limit).all()
    return [model_to_dict(species) for species in species_list]

def create_species(db: Session, scientific_name: str, common_name: str = None, family: str = None) -> Dict[str, Any]:
    """
    Create a new species record.
    
    Args:
        db: Database session
        scientific_name: Scientific name of the species
        common_name: Common name of the species
        family: Taxonomic family of the species
        
    Returns:
        Dictionary representation of the created Species object
    """
    db_species = Species(scientific_name=scientific_name, common_name=common_name, family=family)
    db.add(db_species)
    db.commit()
    db.refresh(db_species)
    return model_to_dict(db_species)

def update_species(db: Session, species_id: int, scientific_name: Optional[str] = None, 
                  common_name: Optional[str] = None, family: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """
    Update an existing species record.
    
    Args:
        db: Database session
        species_id: ID of the species to update
        scientific_name: New scientific name for the species
        common_name: New common name for the species
        family: New taxonomic family for the species
        
    Returns:
        Dictionary representation of the updated Species object if found, None otherwise
    """
    db_species = db.query(Species).filter(Species.id == species_id).first()
    if not db_species:
        return None
    
    # Update fields if provided
    if scientific_name is not None:
        db_species.scientific_name = scientific_name
    if common_name is not None:
        db_species.common_name = common_name
    if family is not None:
        db_species.family = family
    
    db.commit()
    db.refresh(db_species)
    return model_to_dict(db_species)

def delete_species(db: Session, species_id: int) -> bool:
    """
    Delete a species record and its relationships.
    
    Args:
        db: Database session
        species_id: ID of the species to delete
        
    Returns:
        True if the species was found and deleted, False otherwise
    """
    db_species = db.query(Species).filter(Species.id == species_id).first()
    if not db_species:
        return False
    
    # Delete associated relations with photos
    db.query(PhotoSpeciesRelation).filter(PhotoSpeciesRelation.species_id == species_id).delete()
    
    # Delete the species record
    db.delete(db_species)
    db.commit()
    return True