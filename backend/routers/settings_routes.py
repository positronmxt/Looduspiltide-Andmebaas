"""
Rakenduse seadistuste marsruuterid.

See moodul sisaldab kõiki HTTP marsruute, mis on seotud rakenduse seadistuste haldamisega.
Võimaldab seadistuste loomist, lugemist, uuendamist ja kustutamist läbi REST API liidese.
"""
from fastapi import APIRouter, HTTPException, Depends, Body
from fastapi import Request
import asyncio
from typing import Dict, Any
import logging
from services.settings_service import SettingsService
from models.settings_models import AppSettingCreate, AppSettingUpdate, AllSettingsResponse

# Seadista logi
logger = logging.getLogger(__name__)

# Loo marsruuter
router = APIRouter(
    prefix="/settings",
    tags=["settings"],
    responses={404: {"description": "Seadistus ei ole leitud"}},
)

@router.post("/shutdown")
async def shutdown_server(request: Request):
    """Sulgeb rakenduse serveri protsessi (graceful)."""
    try:
        loop = asyncio.get_event_loop()
        loop.call_later(0.2, lambda: asyncio.create_task(request.app.shutdown()))
        loop.call_later(0.4, lambda: asyncio.create_task(request.app.router.shutdown()))
        loop.call_later(0.6, lambda: asyncio.create_task(request.app.state.router.shutdown()) if hasattr(request.app.state, 'router') else None)
        return {"message": "Serveri sulgemine algatatud"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sulgemine ebaõnnestus: {e}")

@router.get("/", response_model=Dict[str, Any])
async def get_all_settings():
    """
    Tagastab kõik rakenduse seadistused.
    
    Returns:
        Dict[str, Any]: Sõnastik, mis sisaldab kõiki rakenduse seadistusi
                        võtme "settings" all.
    
    Raises:
        HTTPException(500): Kui seadistuste lugemine ebaõnnestub.
    """
    try:
        settings = await SettingsService.get_all_settings()
        return {"settings": settings}
    except Exception as e:
        logger.error(f"Viga seadistuste lugemisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuste lugemine ebaõnnestus: {str(e)}")

@router.get("/{key}", response_model=Dict[str, Any])
async def get_setting(key: str):
    """
    Tagastab ühe seadistuse võtme alusel.
    
    Args:
        key (str): Seadistuse võti, mida soovitakse leida.
    
    Returns:
        Dict[str, Any]: Seadistuse andmed (võti, väärtus, kirjeldus).
    
    Raises:
        HTTPException(404): Kui seadistust antud võtmega ei leitud.
        HTTPException(500): Kui seadistuse lugemine ebaõnnestub.
    """
    try:
        setting = await SettingsService.get_setting(key)
        if not setting:
            raise HTTPException(status_code=404, detail=f"Seadistust võtmega '{key}' ei leitud")
        return setting
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Viga seadistuse '{key}' lugemisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse lugemine ebaõnnestus: {str(e)}")

@router.put("/{key}", response_model=Dict[str, Any])
async def update_setting(key: str, data: dict = Body(...)):
    """
    Uuendab olemasolevat seadistust.
    
    Args:
        key (str): Seadistuse võti, mida soovitakse uuendada.
        data (dict): Uuendatavad andmed, sisaldab võtit "value" (kohustuslik)
                    ja võtit "description" (valikuline).
    
    Returns:
        Dict[str, Any]: Uuendatud seadistuse andmed.
    
    Raises:
        HTTPException(400): Kui väärtus puudub.
        HTTPException(404): Kui seadistust antud võtmega ei leitud.
        HTTPException(500): Kui seadistuse uuendamine ebaõnnestub.
    """
    try:
        value = data.get("value")
        description = data.get("description")
        
        # Kontrollime, kas väärtus on antud
        if value is None:
            raise HTTPException(status_code=400, detail="Väärtus on kohustuslik")
        
        # Uuendame seadistust
        updated = await SettingsService.update_setting(key, value, description)
        return updated
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Viga seadistuse '{key}' uuendamisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse uuendamine ebaõnnestus: {str(e)}")

@router.post("/", response_model=Dict[str, Any])
async def create_setting(data: AppSettingCreate):
    """
    Loob uue seadistuse.
    
    Args:
        data (AppSettingCreate): Andmemudel, mis sisaldab loodava seadistuse 
                                 võtit, väärtust ja kirjeldust.
    
    Returns:
        Dict[str, Any]: Loodud seadistuse andmed.
    
    Raises:
        HTTPException(400): Kui seadistus antud võtmega juba eksisteerib või andmed on vigased.
        HTTPException(500): Kui seadistuse loomine ebaõnnestub.
    """
    try:
        created = await SettingsService.create_setting(data.key, data.value, data.description)
        return created
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Viga seadistuse loomisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse loomine ebaõnnestus: {str(e)}")

@router.delete("/{key}")
async def delete_setting(key: str):
    """
    Kustutab seadistuse.
    
    Args:
        key (str): Seadistuse võti, mida soovitakse kustutada.
    
    Returns:
        Dict[str, str]: Teade seadistuse eduka kustutamise kohta.
    
    Raises:
        HTTPException(404): Kui seadistust antud võtmega ei leitud.
        HTTPException(500): Kui seadistuse kustutamine ebaõnnestub.
    """
    try:
        await SettingsService.delete_setting(key)
        return {"message": f"Seadistus võtmega '{key}' on edukalt kustutatud"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Viga seadistuse '{key}' kustutamisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse kustutamine ebaõnnestus: {str(e)}")