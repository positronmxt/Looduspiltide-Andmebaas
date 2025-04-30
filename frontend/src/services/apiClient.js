// src/services/apiClient.js
/**
 * API klient, mis kasutab fetch API-t Axios-i asemel
 * Fetch on brauserisse sisseehitatud ja ei vaja Node.js mooduleid
 */

import { API_BASE_URL } from '../config/config';

// Abifunktsioon päringute tegemiseks
const fetchWithErrorHandling = async (url, options = {}) => {
  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    // Kontrolli, kas vastus on OK (staatuskood 200-299)
    if (!response.ok) {
      const errorData = await response.json().catch(() => null);
      throw new Error(
        errorData?.message || `HTTP viga ${response.status}: ${response.statusText}`
      );
    }

    // Kontrolli, kas vastus on tühi
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      return await response.json();
    }
    
    return await response.text();
  } catch (error) {
    console.error('API päring ebaõnnestus:', error);
    throw error;
  }
};

// API meetodid
const apiClient = {
  // GET päring
  get: (endpoint, params = {}) => {
    const url = new URL(`${API_BASE_URL}${endpoint}`);
    
    // Lisa päringutee parameetrid
    Object.keys(params).forEach(key => 
      url.searchParams.append(key, params[key])
    );
    
    return fetchWithErrorHandling(url.toString());
  },
  
  // POST päring
  post: (endpoint, data = {}) => {
    return fetchWithErrorHandling(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },
  
  // PUT päring
  put: (endpoint, data = {}) => {
    return fetchWithErrorHandling(`${API_BASE_URL}${endpoint}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },
  
  // DELETE päring
  delete: (endpoint) => {
    return fetchWithErrorHandling(`${API_BASE_URL}${endpoint}`, {
      method: 'DELETE',
    });
  }
};

export default apiClient;