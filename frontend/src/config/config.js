/**
 * API konfiguratsioon
 */

// API baas URL - siin saab vajadusel muuta porti või domeeni
export const API_BASE_URL = 'http://localhost:8001';

// API endpointid
export const API_ENDPOINTS = {
  PHOTOS: '/photos',
  SPECIES: '/species',
  SETTINGS: '/settings',
  SETTINGS_SHUTDOWN: '/settings/shutdown',
  PLANT_ID: '/plant_id',
  RELATIONS: '/relations',
  BROWSE: '/browse',
  // Lisame puuduvad endpointid
  UPLOAD: '/photos/upload',    // Fotode üleslaadimise endpoint
  IDENTIFY: '/plant_id'        // Taimetuvastuse endpoint (sama mis PLANT_ID)
};

// Staatiline fotode URL (kust pilte serveeritakse)
export const STATIC_FILE_URL = `${API_BASE_URL}/static`;