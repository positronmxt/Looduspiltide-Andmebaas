import React, { useState, useEffect } from 'react';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';
import './AdminPanel.css';

// Mockitud andmed juhuks kui API päring ebaõnnestub
const MOCK_SETTINGS = [
  {
    key: "PLANT_ID_API_KEY",
    value: "",
    description: "Plant.id API võti taimetuvastuseks"
  },
  {
    key: "MAX_UPLOAD_SIZE_MB",
    value: "10",
    description: "Maksimaalne üleslaadimise suurus megabaitides"
  }
];

function AdminPanel() {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [editMode, setEditMode] = useState({});
  const [editValues, setEditValues] = useState({});
  const [isUsingMockData, setIsUsingMockData] = useState(false);
  const [shutdownMessage, setShutdownMessage] = useState(null);

  // Seadistuste laadimine
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        setLoading(true);
        
        // Proovime andmeid saada API-st
        try {
          const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}`);
          
          if (!response.ok) {
            throw new Error(`API viga: ${response.status}`);
          }
          
          const data = await response.json();
          setSettings(data.settings || []);
          setIsUsingMockData(false);
        } catch (apiError) {
          // Kui API päring ebaõnnestub, kasutame mockitud andmeid
          console.error('API viga, kasutan mockitud andmeid:', apiError);
          setSettings(MOCK_SETTINGS);
          setIsUsingMockData(true);
          setError(`API ühendus ebaõnnestus. Kasutan lokaalseid andmeid.`);
        }
        
        // Initsialiseerime editValues kõigi seadistustega
        const initialEditValues = {};
        const currentSettings = isUsingMockData ? MOCK_SETTINGS : settings;
        currentSettings.forEach(setting => {
          initialEditValues[setting.key] = setting.value;
        });
        setEditValues(initialEditValues);
        
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
      
      // Kui kasutame mockitud andmeid, salvestame ainult lokaalselt
      if (isUsingMockData) {
        setSettings(prev => 
          prev.map(setting => 
            setting.key === key ? { ...setting, value: editValues[key] } : setting
          )
        );
        
        setEditMode(prev => ({
          ...prev,
          [key]: false
        }));
        
        setError(null);
        setLoading(false);
        return;
      }
      
      // Muidu päriselt salvestame API kaudu
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

  // API võtme kustutamine
  const handleDelete = async (key) => {
    if (!window.confirm(`Kas olete kindel, et soovite kustutada seadistuse "${key}"?`)) {
      return;
    }
    
    try {
      setLoading(true);
      
      // Kui kasutame mockitud andmeid, kustutame ainult lokaalselt
      if (isUsingMockData) {
        setSettings(prev => 
          prev.map(setting => 
            setting.key === key ? { ...setting, value: "" } : setting
          )
        );
        setEditValues(prev => ({
          ...prev,
          [key]: ""
        }));
        setError(null);
        setLoading(false);
        return;
      }
      
      // Muidu päriselt salvestame tühja väärtuse API kaudu (mis on sisuliselt kustutamine)
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}/${key}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          value: ""
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
      
      // Uuendame ka muudetavat väärtust
      setEditValues(prev => ({
        ...prev,
        [key]: ""
      }));
      
      setError(null);
      alert(`Seadistus "${key}" on kustutatud edukalt.`);
    } catch (err) {
      console.error('Viga seadistuse kustutamisel:', err);
      setError(`Seadistuse kustutamine ebaõnnestus: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleShutdown = async () => {
    if(!window.confirm('Kas kindlasti sulgeda server?')) return;
    try {
      const res = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}/shutdown`, { method: 'POST' });
      const data = await res.json().catch(()=>({}));
      setShutdownMessage(data.message || 'Sulgemine algatatud');
    } catch(e){
      setShutdownMessage('Sulgemine ebaõnnestus: '+e.message);
    }
  };

  if (loading && settings.length === 0) {
    return <div className="admin-panel loading">Seadistuste laadimine...</div>;
  }

  return (
    <div className="admin-panel">
      <h2>Rakenduse administreerimine</h2>
      
      {isUsingMockData && (
        <div className="warning-message">
          Kasutan lokaalseid andmeid, kuna API ühendus ebaõnnestus. Muudatused ei salvestu serverisse.
        </div>
      )}
      
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
                  <>
                    <button 
                      onClick={() => handleEditToggle(setting.key)}
                      disabled={loading}
                      className="action-button edit-button"
                    >
                      Muuda
                    </button>
                    {setting.key === 'PLANT_ID_API_KEY' && (
                      <button 
                        onClick={() => handleDelete(setting.key)}
                        disabled={loading}
                        className="action-button delete-button"
                      >
                        Kustuta
                      </button>
                    )}
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      
      <div className="info-section">
  <button onClick={handleShutdown} className="action-button delete-button" style={{marginBottom:'1rem'}}>Sulge serveri sessioon</button>
  {shutdownMessage && <div className="warning-message">{shutdownMessage}</div>}
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