"""
Fotode sirvimise API marsruuter.
Pakub API lõpp-punkte fotode sirvimiseks ja filtreerimiseks.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from database import get_db
from services import photo_service

router = APIRouter(
    prefix="/photos",
    tags=["fotode-sirvimine"],
    responses={404: {"description": "Ei leitud"}},
)

@router.get("/", response_model=List[Dict[str, Any]])
async def get_photos(
    species_id: Optional[int] = Query(None, description="Taimeliigi ID filtreerimiseks"),
    location: Optional[str] = Query(None, description="Asukoht filtreerimiseks"),
    date: Optional[str] = Query(None, description="Kuupäev filtreerimiseks (YYYY-MM-DD)"),
    offset: int = Query(0, description="Mitu fotot vahele jätta (leheküljestamine)"),
    limit: int = Query(20, description="Maksimaalne fotode arv vastuses"),
    db: Session = Depends(get_db)
):
    """
    Tagasta fotode nimekiri koos põhiandmetega.
    Võimaldab filtreerida liigi, asukoha ja kuupäeva järgi.
    """
    photos = photo_service.get_photos(
        db, species_id=species_id, location=location, 
        date=date, offset=offset, limit=limit
    )
    return photos

@router.get("/{photo_id}", response_model=Dict[str, Any])
async def get_photo(
    photo_id: int, 
    db: Session = Depends(get_db)
):
    """
    Tagasta konkreetse foto detailid koos tuvastatud liikidega.
    """
    photo_data = photo_service.get_photo_with_species(db, photo_id)
    if not photo_data:
        raise HTTPException(status_code=404, detail="Fotot ei leitud")
    return photo_data