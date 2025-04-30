"""
Looduspiltide andmebaasi peamine rakenduse moodul.
Initsialiseerib FastAPI rakenduse ja lisab kõik marsruuterid.
"""
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError, ResponseValidationError
import uvicorn
import sys
import logging
from pathlib import Path
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Seadista logi
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Lisa ülemkataloog Pythoni otsingusüsteemi, et impordid töötaksid otse käivitatuna
sys.path.append(str(Path(__file__).parent.parent))

from routers import photo_routes, species_routes, relation_routes, plant_id_api, browse_routes, settings_routes

# Loo FastAPI rakendus
app = FastAPI(
    title="Looduspiltide Andmebaasi API",
    description="API looduspiltide ja liikide tuvastamise haldamiseks",
    version="0.1.0",
)

# CORS seadistamine - lubame kõik päritolud arenduse ajal
origins = ["*"]  # Lubame kõik päritolud arenduskeskkonnas

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Erinditöötleja ResponseValidationError jaoks
@app.exception_handler(ResponseValidationError)
async def validation_exception_handler(request: Request, exc: ResponseValidationError):
    logger.error(f"ValidationError: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Server error: Response validation failed", "errors": str(exc)},
        headers={"Access-Control-Allow-Origin": "*"}
    )

# Lisa täiendav erinditöötleja kõigi teiste erandite jaoks
@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"GeneralError: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": f"Server error: {str(exc)}"},
        headers={"Access-Control-Allow-Origin": "*"}
    )

# Lisa erinevate ressursside marsruuterid
logger.info("Registreerin marsruuterid...")
app.include_router(photo_routes.router)
app.include_router(species_routes.router)
app.include_router(relation_routes.router)
app.include_router(plant_id_api.router)
app.include_router(browse_routes.router)
app.include_router(settings_routes.router)
logger.info("Kõik marsruuterid registreeritud!")

# Lisa staatiliste failide teenindus piltide jaoks
app.mount("/static", StaticFiles(directory="../file_storage"), name="static")

@app.get("/")
def read_root():
    """
    Juurendpoint, mis tagastab tervitussõnumi.
    """
    return {"message": "Tere tulemast Looduspiltide Andmebaasi API-sse!"}

# Rakenduse käivitamine
if __name__ == "__main__":
    logger.info("Käivitan serveri...")
    uvicorn.run(app, host="0.0.0.0", port=8001)