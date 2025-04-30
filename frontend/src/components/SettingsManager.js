import React, { useState, useEffect } from 'react';
import './SettingsManager.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

function SettingsManager() {
  const [settings, setSettings] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}`);
      if (response.ok) {
        const data = await response.json();
        setSettings(data);
      } else {
        console.error('Failed to fetch settings');
      }
    } catch (error) {
      console.error('Error fetching settings:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSettingChange = async (settingId, value) => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SETTINGS}/${settingId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ value }),
      });
      if (response.ok) {
        fetchSettings();
      } else {
        console.error('Failed to update setting');
      }
    } catch (error) {
      console.error('Error updating setting:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="settings-manager">
      {isLoading ? (
        <p>Loading...</p>
      ) : (
        <ul>
          {settings.map((setting) => (
            <li key={setting.id}>
              <span>{setting.name}</span>
              <input
                type="text"
                value={setting.value}
                onChange={(e) => handleSettingChange(setting.id, e.target.value)}
              />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default SettingsManager;