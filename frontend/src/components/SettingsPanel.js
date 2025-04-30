import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './SettingsPanel.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

const SettingsPanel = () => {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [editingKey, setEditingKey] = useState(null);
  const [editValue, setEditValue] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  // Lae seadistused lehele jõudes
  useEffect(() => {
    fetchSettings();
  }, []);

  // Küsi seadistused serverist
  const fetchSettings = async () => {
    setLoading(true);
    try {
      const response = await axios.get(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}/`);
      setSettings(response.data);
      setError(null);
    } catch (err) {
      console.error('Viga seadistuste laadimisel:', err);
      setError('Seadistuste laadimine ebaõnnestus. Palun proovige hiljem uuesti.');
    } finally {
      setLoading(false);
    }
  };

  // Alusta seadistuse muutmist
  const startEditing = (setting) => {
    setEditingKey(setting.key);
    setEditValue(setting.value);
  };

  // Tühista muutmine
  const cancelEditing = () => {
    setEditingKey(null);
    setEditValue('');
  };

  // Salvesta muudetud seadistus
  const saveSetting = async (setting) => {
    try {
      await axios.post(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}/`, {
        key: setting.key,
        value: editValue,
        description: setting.description
      });
      
      // Uuenda lokaalselt seadistuste nimekirja
      setSettings(settings.map(s => 
        s.key === setting.key ? {...s, value: editValue} : s
      ));
      
      setSuccessMessage(`Seadistus "${setting.key}" on edukalt salvestatud!`);
      setTimeout(() => setSuccessMessage(''), 3000); // Peida teade 3 sekundi pärast
      
      setEditingKey(null);
      setEditValue('');
    } catch (err) {
      console.error('Viga seadistuse salvestamisel:', err);
      setError('Seadistuse salvestamine ebaõnnestus. Palun proovige hiljem uuesti.');
    }
  };

  // Näita laadimisanimatsiooni
  if (loading && settings.length === 0) {
    return <div className="settings-loading">Laadin seadistusi...</div>;
  }

  return (
    <div className="settings-panel">
      <h2>Administreerimise Paneel</h2>
      <p>Siin saate hallata rakenduse seadistusi</p>
      
      {error && <div className="settings-error">{error}</div>}
      {successMessage && <div className="settings-success">{successMessage}</div>}
      
      <div className="settings-list">
        {settings.map(setting => (
          <div key={setting.key} className="setting-item">
            <div className="setting-header">
              <h3>{setting.key}</h3>
              {editingKey !== setting.key && (
                <button 
                  onClick={() => startEditing(setting)}
                  className="edit-button"
                >
                  Muuda
                </button>
              )}
            </div>
            
            <p className="setting-description">{setting.description || 'Kirjeldus puudub'}</p>
            
            {editingKey === setting.key ? (
              <div className="setting-edit">
                <input
                  type={setting.key.includes("API_KEY") || setting.key.includes("PASSWORD") ? "password" : "text"}
                  value={editValue}
                  onChange={(e) => setEditValue(e.target.value)}
                  className="setting-input"
                />
                <div className="setting-actions">
                  <button 
                    onClick={() => saveSetting(setting)}
                    className="save-button"
                  >
                    Salvesta
                  </button>
                  <button 
                    onClick={cancelEditing}
                    className="cancel-button"
                  >
                    Tühista
                  </button>
                </div>
              </div>
            ) : (
              <div className="setting-value">
                {setting.key.includes("API_KEY") || setting.key.includes("PASSWORD") 
                  ? (setting.value ? '••••••••••••••••' : '<puudub>') 
                  : (setting.value || '<puudub>')}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default SettingsPanel;