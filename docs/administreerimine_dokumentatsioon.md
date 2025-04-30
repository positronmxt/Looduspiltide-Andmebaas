# Administreerimisfunktsionaalsus Looduspiltide Andmebaasis

See dokument kirjeldab administreerimisfunktsionaalsuse komponente ja loogikat, et vajadusel oleks neid lihtne taastada.

## Backend komponendid

### 1. Models: `/backend/models/settings_models.py`

```python
"""
Rakenduse seadistuste mudelid.
"""
from pydantic import BaseModel
from typing import Optional, List

class AppSetting(BaseModel):
    """Rakenduse seadistus andmebaasis."""
    key: str
    value: str
    description: str

class AppSettingCreate(BaseModel):
    """Seadistuse loomise skeem."""
    key: str
    value: str
    description: str

class AppSettingUpdate(BaseModel):
    """Seadistuse uuendamise skeem."""
    value: str
    description: Optional[str] = None

class AppSettingResponse(BaseModel):
    """Seadistuse vastuse skeem."""
    key: str
    value: str
    description: str

class AllSettingsResponse(BaseModel):
    """Kõikide seadistuste vastuse skeem."""
    settings: List[AppSettingResponse]
```

### 2. Service: `/backend/services/settings_service.py`

```python
"""
Rakenduse seadistuste teenus.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from database import get_db
import logging

logger = logging.getLogger(__name__)

class SettingsService:
    """Teenus rakenduse seadistuste haldamiseks."""

    @staticmethod
    async def get_all_settings():
        """Tagastab kõik rakenduse seadistused."""
        db = next(get_db())
        try:
            result = db.execute("SELECT key, value, description FROM app_settings").fetchall()
            settings = [{"key": row[0], "value": row[1], "description": row[2]} for row in result]
            return settings
        except Exception as e:
            logger.error(f"Viga seadistuste lugemisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def get_setting(key: str):
        """Tagastab ühe seadistuse võtme järgi."""
        db = next(get_db())
        try:
            result = db.execute(
                "SELECT key, value, description FROM app_settings WHERE key = :key",
                {"key": key}
            ).fetchone()
            
            if not result:
                return None
            
            return {"key": result[0], "value": result[1], "description": result[2]}
        except Exception as e:
            logger.error(f"Viga seadistuse '{key}' lugemisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def update_setting(key: str, value: str, description: Optional[str] = None):
        """Uuendab olemasolevat seadistust."""
        db = next(get_db())
        try:
            # Kontrollime, kas seadistus eksisteerib
            existing = db.execute(
                "SELECT key FROM app_settings WHERE key = :key",
                {"key": key}
            ).fetchone()
            
            if not existing:
                raise ValueError(f"Seadistust võtmega '{key}' ei leitud")
            
            # Kui uut kirjeldust pole antud, jätame vana alles
            if description is None:
                db.execute(
                    "UPDATE app_settings SET value = :value WHERE key = :key",
                    {"key": key, "value": value}
                )
            else:
                db.execute(
                    "UPDATE app_settings SET value = :value, description = :description WHERE key = :key",
                    {"key": key, "value": value, "description": description}
                )
            
            db.commit()
            return await SettingsService.get_setting(key)
        except Exception as e:
            db.rollback()
            logger.error(f"Viga seadistuse '{key}' uuendamisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def create_setting(key: str, value: str, description: str):
        """Loob uue seadistuse."""
        db = next(get_db())
        try:
            # Kontrollime, kas seadistus juba eksisteerib
            existing = db.execute(
                "SELECT key FROM app_settings WHERE key = :key",
                {"key": key}
            ).fetchone()
            
            if existing:
                raise ValueError(f"Seadistus võtmega '{key}' juba eksisteerib")
            
            db.execute(
                "INSERT INTO app_settings (key, value, description) VALUES (:key, :value, :description)",
                {"key": key, "value": value, "description": description}
            )
            
            db.commit()
            return await SettingsService.get_setting(key)
        except Exception as e:
            db.rollback()
            logger.error(f"Viga seadistuse '{key}' loomisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def delete_setting(key: str):
        """Kustutab seadistuse."""
        db = next(get_db())
        try:
            # Kontrollime, kas seadistus eksisteerib
            existing = db.execute(
                "SELECT key FROM app_settings WHERE key = :key",
                {"key": key}
            ).fetchone()
            
            if not existing:
                raise ValueError(f"Seadistust võtmega '{key}' ei leitud")
            
            db.execute(
                "DELETE FROM app_settings WHERE key = :key",
                {"key": key}
            )
            
            db.commit()
            return True
        except Exception as e:
            db.rollback()
            logger.error(f"Viga seadistuse '{key}' kustutamisel: {e}")
            raise
        finally:
            db.close()

    @staticmethod
    async def get_plant_id_api_key():
        """Tagastab Plant.id API võtme."""
        setting = await SettingsService.get_setting("PLANT_ID_API_KEY")
        return setting["value"] if setting else ""
```

### 3. Router: `/backend/routers/settings_routes.py`

```python
"""
Seadistuste marsruudid API jaoks.
"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List
import logging
from models.settings_models import (
    AppSetting, 
    AppSettingCreate, 
    AppSettingUpdate, 
    AppSettingResponse, 
    AllSettingsResponse
)
from services.settings_service import SettingsService

router = APIRouter(prefix="/settings", tags=["settings"])
logger = logging.getLogger(__name__)

@router.get("", response_model=AllSettingsResponse)
async def get_all_settings():
    """
    Tagastab kõik rakenduse seadistused.
    """
    try:
        settings = await SettingsService.get_all_settings()
        return {"settings": settings}
    except Exception as e:
        logger.error(f"Viga seadistuste hankimisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuste hankimisel tekkis viga: {str(e)}")

@router.get("/{key}", response_model=AppSettingResponse)
async def get_setting(key: str):
    """
    Tagastab ühe seadistuse võtme järgi.
    """
    try:
        setting = await SettingsService.get_setting(key)
        if not setting:
            raise HTTPException(status_code=404, detail=f"Seadistust võtmega '{key}' ei leitud")
        return setting
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Viga seadistuse '{key}' hankimisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse hankimisel tekkis viga: {str(e)}")

@router.put("/{key}", response_model=AppSettingResponse)
async def update_setting(key: str, setting_update: AppSettingUpdate):
    """
    Uuendab olemasolevat seadistust.
    """
    try:
        updated_setting = await SettingsService.update_setting(
            key, 
            setting_update.value, 
            setting_update.description
        )
        return updated_setting
    except ValueError as e:
        logger.error(f"Viga seadistuse '{key}' uuendamisel: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Viga seadistuse '{key}' uuendamisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse uuendamisel tekkis viga: {str(e)}")

@router.post("", response_model=AppSettingResponse)
async def create_setting(setting_create: AppSettingCreate):
    """
    Loob uue seadistuse.
    """
    try:
        new_setting = await SettingsService.create_setting(
            setting_create.key,
            setting_create.value,
            setting_create.description
        )
        return new_setting
    except ValueError as e:
        logger.error(f"Viga seadistuse loomisel: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Viga seadistuse loomisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse loomisel tekkis viga: {str(e)}")

@router.delete("/{key}", response_model=dict)
async def delete_setting(key: str):
    """
    Kustutab seadistuse.
    """
    try:
        await SettingsService.delete_setting(key)
        return {"message": f"Seadistus võtmega '{key}' on edukalt kustutatud"}
    except ValueError as e:
        logger.error(f"Viga seadistuse '{key}' kustutamisel: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Viga seadistuse '{key}' kustutamisel: {e}")
        raise HTTPException(status_code=500, detail=f"Seadistuse kustutamisel tekkis viga: {str(e)}")

@router.get("/plant-id/api-key", response_model=dict)
async def get_plant_id_api_key():
    """
    Tagastab Plant.id API võtme.
    """
    try:
        api_key = await SettingsService.get_plant_id_api_key()
        return {"api_key": api_key}
    except Exception as e:
        logger.error(f"Viga Plant.id API võtme hankimisel: {e}")
        raise HTTPException(status_code=500, detail=f"API võtme hankimisel tekkis viga: {str(e)}")
```

### 4. Backend muudatused main.py failis

Import:
```python
from routers import photo_routes, species_routes, relation_routes, plant_id_api, browse_routes, settings_routes
```

Registreerimine:
```python
app.include_router(settings_routes.router)
```

### 5. Andmebaasi muudatused (update_schema.py)

Juba olemasolev kood loob app_settings tabeli ja lisab vajaliku PLANT_ID_API_KEY seadistuse:
```python
# Create app_settings table if it doesn't exist
logger.info("Kontrollime app_settings tabeli olemasolu...")
cursor.execute("""
    CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        description TEXT
    )
""")

# Add default settings if needed
cursor.execute("""
    INSERT INTO app_settings (key, value, description)
    VALUES ('PLANT_ID_API_KEY', '', 'Plant.id API võtme väärtus')
    ON CONFLICT (key) DO NOTHING
""")
```

## Frontend komponendid

### 1. AdminPanel komponent: `/frontend/src/components/AdminPanel.js`

```jsx
import React, { useState, useEffect } from 'react';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';
import './AdminPanel.css';

function AdminPanel() {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [editMode, setEditMode] = useState({});
  const [editValues, setEditValues] = useState({});

  // Seadistuste laadimine
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        setLoading(true);
        const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}`);
        
        if (!response.ok) {
          throw new Error(`API viga: ${response.status}`);
        }
        
        const data = await response.json();
        setSettings(data.settings || []);
        
        // Initsialiseerime editValues kõigi seadistustega
        const initialEditValues = {};
        data.settings.forEach(setting => {
          initialEditValues[setting.key] = setting.value;
        });
        setEditValues(initialEditValues);
        
        setError(null);
      } catch (err) {
        console.error('Viga seadistuste laadimisel:', err);
        setError(`Seadistuste laadimine ebaõnnestus: ${err.message}`);
      } finally {
        setLoading(false);
      }
    };

    fetchSettings();
  }, []);

  // Seadistuse muutmisrežiimi aktiveerimine
  const handleEditToggle = (key) => {
    setEditMode(prev => ({
      ...prev,
      [key]: !prev[key]
    }));
  };

  // Seadistuse muutmine
  const handleInputChange = (key, value) => {
    setEditValues(prev => ({
      ...prev,
      [key]: value
    }));
  };

  // Seadistuse salvestamine
  const handleSave = async (key) => {
    try {
      setLoading(true);
      
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}/${key}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          value: editValues[key]
        }),
      });

      if (!response.ok) {
        throw new Error(`API viga: ${response.status}`);
      }

      const updatedSetting = await response.json();
      
      // Uuendame kohalikku olekut
      setSettings(prev => 
        prev.map(setting => 
          setting.key === key ? updatedSetting : setting
        )
      );
      
      // Väljume muutmisrežiimist
      setEditMode(prev => ({
        ...prev,
        [key]: false
      }));
      
      setError(null);
    } catch (err) {
      console.error('Viga seadistuse salvestamisel:', err);
      setError(`Seadistuse salvestamine ebaõnnestus: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  if (loading && settings.length === 0) {
    return <div className="admin-panel loading">Seadistuste laadimine...</div>;
  }

  return (
    <div className="admin-panel">
      <h2>Rakenduse administreerimine</h2>
      
      {error && (
        <div className="error-message">
          {error}
        </div>
      )}
      
      <table className="settings-table">
        <thead>
          <tr>
            <th>Seadistus</th>
            <th>Väärtus</th>
            <th>Kirjeldus</th>
            <th>Tegevused</th>
          </tr>
        </thead>
        <tbody>
          {settings.map((setting) => (
            <tr key={setting.key}>
              <td>{setting.key}</td>
              <td>
                {editMode[setting.key] ? (
                  <input
                    type="text"
                    value={editValues[setting.key] || ''}
                    onChange={(e) => handleInputChange(setting.key, e.target.value)}
                  />
                ) : (
                  setting.key === 'PLANT_ID_API_KEY' && setting.value ? 
                  '********' : setting.value || '-'
                )}
              </td>
              <td>{setting.description || '-'}</td>
              <td>
                {editMode[setting.key] ? (
                  <button 
                    onClick={() => handleSave(setting.key)}
                    disabled={loading}
                  >
                    Salvesta
                  </button>
                ) : (
                  <button 
                    onClick={() => handleEditToggle(setting.key)}
                    disabled={loading}
                  >
                    Muuda
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      
      <div className="info-section">
        <h3>Plant.id API kasutamine</h3>
        <p>
          Taimetuvastuseks on vajalik Plant.id API võti. Kui teil ei ole veel võtit, saate selle hankida 
          <a href="https://web.plant.id/plant-identification-api/" target="_blank" rel="noreferrer">
            Plant.id veebisaidilt
          </a>.
        </p>
        <p>Pärast võtme hankimist sisestage see ülaltoodud tabelisse "PLANT_ID_API_KEY" seadistuse juurde.</p>
      </div>
    </div>
  );
}

export default AdminPanel;
```

### 2. AdminPanel CSS: `/frontend/src/components/AdminPanel.css`

```css
.admin-panel {
  padding: 20px;
  max-width: 1000px;
  margin: 0 auto;
}

.admin-panel h2 {
  color: #2c3e50;
  margin-bottom: 20px;
  border-bottom: 2px solid #3498db;
  padding-bottom: 10px;
}

.settings-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 20px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.settings-table th,
.settings-table td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

.settings-table th {
  background-color: #3498db;
  color: white;
  font-weight: 500;
}

.settings-table tr:nth-child(even) {
  background-color: #f9f9f9;
}

.settings-table tr:hover {
  background-color: #f1f1f1;
}

.settings-table input {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.settings-table button {
  padding: 8px 12px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.settings-table button:hover {
  background-color: #2980b9;
}

.settings-table button:disabled {
  background-color: #95a5a6;
  cursor: not-allowed;
}

.error-message {
  background-color: #f8d7da;
  color: #721c24;
  padding: 12px 15px;
  margin-bottom: 20px;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
}

.admin-panel.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 200px;
  font-size: 18px;
  color: #555;
}

.info-section {
  background-color: #e8f4f8;
  padding: 15px 20px;
  border-radius: 5px;
  margin-top: 30px;
}

.info-section h3 {
  color: #2c3e50;
  margin-top: 0;
  margin-bottom: 10px;
}

.info-section a {
  color: #3498db;
  margin-left: 5px;
  text-decoration: none;
}

.info-section a:hover {
  text-decoration: underline;
}
```

### 3. App.js muudatused

Import:
```jsx
import AdminPanel from './components/AdminPanel';
```

Navigatsiooninupp:
```jsx
<button 
  className={activeView === 'admin' ? 'active' : ''}
  onClick={() => setActiveView('admin')}
>
  Administreerimine
</button>
```

Komponendi renderdusloogika:
```jsx
{activeView === 'admin' && <AdminPanel />}
```

### 4. config.js muudatused

Lisa SETTINGS API otspunkt:
```javascript
export const API_ENDPOINTS = {
  PHOTOS: '/photos',
  SPECIES: '/species',
  SETTINGS: '/settings',  // Lisa see rida
  PLANT_ID: '/plant_id',
  RELATIONS: '/relations',
  BROWSE: '/browse'
};
```

## Kasutusjuhend

1. Mine Administreerimise vaatele peamenüüst
2. Sisesta Plant.id API võti (saad selle https://web.plant.id/plant-identification-api/ lehelt)
3. Salvesta muudatused
4. API võti on nüüd salvestatud andmebaasi ja seda kasutatakse taimetuvastuseks

## Koodi rakendamisel

Kui koodis tuleb vigu, siis kontrolli:
1. Kas andmebaasis on `app_settings` tabel olemas
2. Kas API endpoints töötavad korrektlselt (kasuta näiteks browseri Network tab-i või Postman-i)
3. Kas Admin vaade laadib seadistusi korrektselt

Veaprobleemide puhul kontrolli logisid:
- Backend: `/backend/logs/backend.log`
- Frontend: `/frontend/logs/frontend.log`