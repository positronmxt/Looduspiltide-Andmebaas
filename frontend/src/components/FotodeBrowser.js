import React, { useState, useEffect } from 'react';
import './FotodeBrowser.css';
import { API_BASE_URL, API_ENDPOINTS, STATIC_FILE_URL } from '../config/config';

const FotodeBrowser = () => {
  const [photos, setPhotos] = useState([]);
  const [selectedPhoto, setSelectedPhoto] = useState(null);
  const [filters, setFilters] = useState({
    speciesName: '',
    location: '',
    date: '',
    month: null,
    year: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [identifyingPhoto, setIdentifyingPhoto] = useState(false);
  const [identificationSuccess, setIdentificationSuccess] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [editForm, setEditForm] = useState({
    date: '',
    location: ''
  });
  const [editSpeciesMode, setEditSpeciesMode] = useState(false);
  const [editSpecies, setEditSpecies] = useState({
    id: null,
    scientific_name: '',
    common_name: '',
    family: ''
  });
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [confirmDeleteSpecies, setConfirmDeleteSpecies] = useState(null);

  // Kuude nimetused eesti keeles
  const months = [
    "Jaanuar", "Veebruar", "Märts", "Aprill", "Mai", "Juuni", 
    "Juuli", "August", "September", "Oktoober", "November", "Detsember"
  ];

  useEffect(() => {
    fetchPhotos();
  }, []);

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchPhotos();
    }, 500);
    return () => clearTimeout(delayDebounceFn);
  }, [filters]);

  const fetchPhotos = async () => {
    setLoading(true);
    setError(null);
    
    try {
      let url = `${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/?`;
      
      if (filters.speciesName) url += `species_name=${encodeURIComponent(filters.speciesName)}&`;
      if (filters.location) url += `location=${encodeURIComponent(filters.location)}&`;
      if (filters.date) url += `date=${encodeURIComponent(filters.date)}&`;
      
      // Kui kuufilter on aktiivne, filtreerime kuu järgi frontendis
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error('Fotode laadimine ebaõnnestus');
      }
      
      let data = await response.json();
      
      // Kui on valitud kuu, filtreerime frontendis
      if (filters.month !== null) {
        data = data.filter(photo => {
          if (!photo.date) return false;
          const photoDate = new Date(photo.date);
          
          // Kontrolli, kas kuu vastab filtrile
          // JavaScript-is on kuud 0-põhised (0 = jaanuar, 11 = detsember)
          const photoMonth = photoDate.getMonth();
          
          // Kui on valitud ka aasta, kontrolli ka aastat
          if (filters.year && filters.year !== '') {
            const photoYear = photoDate.getFullYear();
            return photoMonth === filters.month && photoYear === parseInt(filters.year);
          }
          
          // Kui aastat pole määratud, filtreeri ainult kuu järgi
          return photoMonth === filters.month;
        });
      }
      
      setPhotos(data);
    } catch (err) {
      console.error('Viga fotode laadimisel:', err);
      setError('Fotode laadimine ebaõnnestus. Palun proovige hiljem uuesti.');
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const formatDateForFilter = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toISOString().split('T')[0];
  };

  const handleDateFilterChange = (e) => {
    const { name, value } = e.target;
    if (!value) {
      setFilters(prev => ({
        ...prev,
        [name]: ''
      }));
    } else {
      setFilters(prev => ({
        ...prev,
        [name]: formatDateForFilter(value)
      }));
    }
  };

  const clearDateFilter = () => {
    setFilters(prev => ({
      ...prev,
      date: ''
    }));
    document.getElementById('date-filter').value = '';
  };

  // Käsitleb kuu valimist
  const handleMonthSelect = (index) => {
    // Kui sama kuu on juba valitud, siis tühistame valiku
    if (filters.month === index) {
      setFilters(prev => ({
        ...prev,
        month: null
      }));
    } else {
      setFilters(prev => ({
        ...prev,
        month: index
      }));
    }
  };
  
  // Käsitleb aasta valimist kuufiltri jaoks
  const handleYearChange = (e) => {
    const { value } = e.target;
    setFilters(prev => ({
      ...prev,
      year: value
    }));
  };

  const handlePhotoClick = async (photoId) => {
    try {
      // Lähtestame tuvastuse oleku uue foto avamisel
      setIdentificationSuccess(false);
      
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/${photoId}`);
      
      if (!response.ok) {
        throw new Error('Foto detailide laadimine ebaõnnestus');
      }
      
      const data = await response.json();
      console.log('Saadud foto andmed:', data);
      
      if (!data) {
        throw new Error('Foto andmeid ei saadud');
      }
      
      // Kontrolli liikide nimekirja
      if (!data.species || data.species.length === 0) {
        // Kui foto liikide nimekiri on tühi, proovi liigi seoseid eraldi pärida
        console.log('Foto liikide nimekiri on tühi, proovime eraldi pärida...');
        try {
          const relationsResponse = await fetch(`${API_BASE_URL}${API_ENDPOINTS.RELATIONS}/photo/${photoId}`);
          if (relationsResponse.ok) {
            const relationsData = await relationsResponse.json();
            if (relationsData && Array.isArray(relationsData) && relationsData.length > 0) {
              console.log('Leitud liikide seosed:', relationsData);
              data.species = relationsData;
            }
          }
        } catch (relErr) {
          console.error('Viga liikide seoste pärimisel:', relErr);
        }
      }
      
      setSelectedPhoto({
        photo: {
          id: data.id,
          file_path: data.file_path,
          date: data.date,
          location: data.location,
          gps_latitude: data.gps_latitude,
          gps_longitude: data.gps_longitude,
          gps_altitude: data.gps_altitude,
          camera_make: data.camera_make,
          camera_model: data.camera_model
        },
        species: data.species || []
      });
    } catch (err) {
      console.error('Viga foto detailide laadimisel:', err);
      setError('Foto detailide laadimine ebaõnnestus. Palun proovige hiljem uuesti.');
    }
  };

  const closePhotoDetail = () => {
    setSelectedPhoto(null);
  };

  const getRelativeFilePath = (absolutePath) => {
    if (!absolutePath) return '';
    const parts = absolutePath.split('/');
    return parts[parts.length - 1];
  };

  const handleAIIdentify = async () => {
    if (!selectedPhoto || !selectedPhoto.photo || !selectedPhoto.photo.id) return;
    
    setIdentifyingPhoto(true);
    setIdentificationSuccess(false);
    setError(null);
    
    try {
      console.log('Tuvastan taimi fotole ID-ga:', selectedPhoto.photo.id);
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PLANT_ID}/existing/${selectedPhoto.photo.id}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        }
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        
        // Kontrolli, kas veateade on seotud API võtme puudumisega
        if (response.status === 400 && errorData.detail && 
            (errorData.detail.includes("API võti puudub") || 
             errorData.detail.includes("Plant.ID API võti") ||
             errorData.detail.includes("administreerimislehel"))) {
          throw new Error("Taimetuvastuse jaoks on vaja seadistada Plant.ID API võti. Palun minge administreerimislehele API võtme seadistamiseks.");
        }
        
        throw new Error('Taime tuvastamine ebaõnnestus');
      }
      
      const data = await response.json();
      console.log('Tuvastamise tulemused:', data);
      console.log('Tuvastamise tulemuste tüüp:', typeof data, Array.isArray(data));
      console.log('Tuvastamise tulemuste pikkus:', data.length);

      // Kontrollime kas array on tühi, kuigi seda poleks tohi olla
      if (data && Array.isArray(data) && data.length === 0) {
        console.error("HOIATUS: API tagastas tühja massiivi, kuigi seda ei peaks juhtuma!");
        // Proovime teha veel ühe päringu otse curl käsuga
        alert("Tuvastamise vastus on tühi, kuid API peaks andmeid tagastama. Kontrolli logisid.");
      }

      // Otse kuvame tuvastatud liigid frontendis ilma andmebaasist uuesti pärimata
      if (data && data.length > 0) {
        console.log("Tulemused on olemas, kuvame need");
        // Loome spetsiaalsed objektid frontendi jaoks, et need sarnaneks andmebaasi omadega
        const formattedSpecies = data.map((species, index) => {
          console.log(`Formateerin liiki: ${species.scientific_name}`);
          return {
            id: `temp-${Date.now()}-${index}`, // Ajutine ID frontendis kuvamiseks
            scientific_name: species.scientific_name,
            common_name: species.common_names ? species.common_names[0] : null,
            estonian_name: species.estonian_name || (species.common_names ? species.common_names.find(n => /[õäöüÕÄÖÜ]/.test(n)) : null),
            family: species.family,
            probability: species.probability
          };
        });
        
        console.log("Formateeritud liigid:", formattedSpecies);
        
        // Uuendame kohe foto andmed uute liikidega
        setSelectedPhoto(prev => {
          const updated = {
            ...prev,
            species: formattedSpecies
          };
          console.log("Uuendatud foto andmed:", updated);
          return updated;
        });
        setIdentificationSuccess(true);
      } else {
        console.log("Tulemused on tühjad või puuduvad!");
      }
      
      // Proovime siiski ka andmebaasist värskendada, aga me ei sõltu sellest enam
      setTimeout(async () => {
        try {
          await handlePhotoClick(selectedPhoto.photo.id);
        } catch (err) {
          console.error('Viga foto uuesti laadimisel:', err);
          // Kui andmebaasist laadimine ebaõnnestub, siis me juba näitame tulemusi, seega pole probleemi
        }
      }, 1000);
      
    } catch (err) {
      console.error('Viga taime tuvastamisel:', err);
      setError(err.message);
    } finally {
      setIdentifyingPhoto(false);
    }
  };

  const handleEditClick = () => {
    if (selectedPhoto) {
      setEditForm({
        date: selectedPhoto.photo.date || '',
        location: selectedPhoto.photo.location || ''
      });
      setEditMode(true);
    }
  };

  const handleEditCancel = () => {
    setEditMode(false);
  };

  const handleEditFormChange = (e) => {
    const { name, value } = e.target;
    setEditForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    
    if (!selectedPhoto) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/${selectedPhoto.photo.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          date: editForm.date,
          location: editForm.location
        })
      });
      
      if (!response.ok) {
        throw new Error('Foto andmete muutmine ebaõnnestus');
      }
      
      await handlePhotoClick(selectedPhoto.photo.id);
      
      setEditMode(false);
      setSuccess('Foto andmed edukalt muudetud');
      
      setTimeout(() => {
        setSuccess(null);
      }, 3000);
      
    } catch (err) {
      console.error('Viga foto andmete muutmisel:', err);
      setError('Foto andmete muutmine ebaõnnestus. Palun proovige hiljem uuesti.');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteClick = () => {
    setConfirmDelete(true);
  };

  const handleDeleteCancel = () => {
    setConfirmDelete(false);
  };

  const handleDeleteConfirm = async () => {
    if (!selectedPhoto) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/${selectedPhoto.photo.id}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        }
      });
      
      if (!response.ok) {
        throw new Error('Foto kustutamine ebaõnnestus');
      }
      
      setSuccess('Foto edukalt kustutatud');
      setConfirmDelete(false);
      setSelectedPhoto(null);
      
      fetchPhotos();
      
    } catch (err) {
      console.error('Viga foto kustutamisel:', err);
      setError('Foto kustutamine ebaõnnestus. Palun proovige hiljem uuesti.');
    } finally {
      setLoading(false);
    }
  };

  const handleEditSpeciesClick = (species) => {
    setEditSpecies({
      id: species.id,
      scientific_name: species.scientific_name || '',
      common_name: species.common_name || '',
      family: species.family || ''
    });
    setEditSpeciesMode(true);
  };

  const handleEditSpeciesCancel = () => {
    setEditSpeciesMode(false);
    setEditSpecies({
      id: null,
      scientific_name: '',
      common_name: '',
      family: ''
    });
  };

  const handleEditSpeciesChange = (e) => {
    const { name, value } = e.target;
    setEditSpecies(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleEditSpeciesSubmit = async (e) => {
    e.preventDefault();
    
    if (!editSpecies.id) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}/${editSpecies.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          scientific_name: editSpecies.scientific_name,
          common_name: editSpecies.common_name,
          family: editSpecies.family
        })
      });
      
      if (!response.ok) {
        throw new Error('Liigi andmete muutmine ebaõnnestus');
      }
      
      if (selectedPhoto) {
        await handlePhotoClick(selectedPhoto.photo.id);
      }
      
      setEditSpeciesMode(false);
      setSuccess('Liigi andmed edukalt muudetud');
      
      setTimeout(() => {
        setSuccess(null);
      }, 3000);
      
    } catch (err) {
      console.error('Viga liigi andmete muutmisel:', err);
      setError('Liigi andmete muutmine ebaõnnestus. Palun proovige hiljem uuesti.');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteSpeciesClick = (species) => {
    setConfirmDeleteSpecies(species);
  };

  const handleDeleteSpeciesCancel = () => {
    setConfirmDeleteSpecies(null);
  };

  const handleDeleteSpeciesConfirm = async () => {
    if (!confirmDeleteSpecies || !confirmDeleteSpecies.id) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}/${confirmDeleteSpecies.id}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        }
      });
      
      if (!response.ok) {
        throw new Error('Liigi kustutamine ebaõnnestus');
      }
      
      setSuccess('Liik edukalt kustutatud');
      setConfirmDeleteSpecies(null);
      
      if (selectedPhoto) {
        await handlePhotoClick(selectedPhoto.photo.id);
      }
      
    } catch (err) {
      console.error('Viga liigi kustutamisel:', err);
      setError('Liigi kustutamine ebaõnnestus. Palun proovige hiljem uuesti.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="photo-browser">
      <h2>Looduspiltide Sirvimine</h2>
      
      {success && <div className="success-message">{success}</div>}
      {error && <div className="error-message">{error}</div>}
      
      <div className="filter-panel">
        <h3>Filtrid</h3>
        <div className="filter-controls">
          <div className="filter-group">
            <label htmlFor="speciesName">Taimeliik:</label>
            <input 
              type="text" 
              id="speciesName" 
              name="speciesName" 
              value={filters.speciesName}
              onChange={handleFilterChange}
              placeholder="Sisesta taime nimetus"
            />
            <div className="filter-hint">Sisesta taime teaduslik või tavanimi</div>
          </div>
          
          <div className="filter-group">
            <label htmlFor="location">Asukoht:</label>
            <input 
              type="text" 
              id="location" 
              name="location" 
              value={filters.location}
              onChange={handleFilterChange}
              placeholder="Sisesta asukoht"
            />
            <div className="filter-hint">Sisesta täpne asukoht või selle osa</div>
          </div>
          
          <div className="filter-group">
            <label htmlFor="date-filter">Kuupäev:</label>
            <div className="date-filter-container">
              <input 
                type="date" 
                id="date-filter" 
                name="date"
                onChange={handleDateFilterChange}
                className="date-picker"
              />
              {filters.date && (
                <button
                  type="button"
                  className="clear-date-button"
                  onClick={clearDateFilter}
                  title="Tühjenda kuupäev"
                >
                  ×
                </button>
              )}
            </div>
            <div className="filter-hint">
              {filters.date 
                ? `Filtreerin kuupäeva: ${filters.date}` 
                : 'Vali kuupäev kalendrist'}
            </div>
          </div>
        </div>
        
        {/* Kuude nupud */}
        <div className="months-filter">
          <div className="months-filter-header">
            <h4>Filtreeri kuu järgi:</h4>
            <div className="year-filter">
              <label htmlFor="year-filter">Aasta:</label>
              <input 
                type="number" 
                id="year-filter" 
                name="year"
                value={filters.year}
                onChange={handleYearChange}
                placeholder="Kõik aastad"
                min="2000"
                max="2100"
              />
              {filters.year && (
                <button
                  type="button"
                  className="clear-year-button"
                  onClick={() => setFilters(prev => ({ ...prev, year: '' }))}
                  title="Tühjenda aasta"
                >
                  ×
                </button>
              )}
            </div>
          </div>
          
          <div className="months-buttons">
            {months.map((month, index) => (
              <button
                key={index}
                className={`month-button ${filters.month === index ? 'active' : ''}`}
                onClick={() => handleMonthSelect(index)}
              >
                {month.substring(0, 3)}
              </button>
            ))}
          </div>
          
          {filters.month !== null && (
            <div className="active-month-filter">
              Filtreerin kuud: {months[filters.month]} 
              {filters.year ? ` ${filters.year}` : ' (kõik aastad)'}
              <button
                className="clear-month-filter"
                onClick={() => setFilters(prev => ({ ...prev, month: null }))}
              >
                Tühista kuufilter
              </button>
            </div>
          )}
        </div>
      </div>
      
      {loading && !selectedPhoto ? (
        <div className="loading">Fotode laadimine...</div>
      ) : (
        <div className="photos-grid">
          {photos.length > 0 ? (
            photos.map(photo => (
              <div 
                key={photo.id} 
                className="photo-card"
                onClick={() => handlePhotoClick(photo.id)}
              >
                <img 
                  src={`${STATIC_FILE_URL}/${getRelativeFilePath(photo.file_path)}`} 
                  alt="Looduspilt" 
                  className="photo-thumbnail"
                  onError={(e) => {e.target.src = '/placeholder.jpg'}}
                />
                <div className="photo-info">
                  <p className="photo-date">{photo.date || 'Kuupäev puudub'}</p>
                  <p className="photo-location">{photo.location || 'Asukoht puudub'}</p>
                  {photo.species && photo.species.length > 0 && (
                    <p className="photo-species">
                      {photo.species.slice(0, 2).map((species, index) => (
                        <span key={species.id} className="species-tag">
                          {species.common_name || species.scientific_name}
                          {index < Math.min(photo.species.length, 2) - 1 ? ', ' : ''}
                        </span>
                      ))}
                      {photo.species.length > 2 && <span className="more-species">+{photo.species.length - 2}</span>}
                    </p>
                  )}
                </div>
              </div>
            ))
          ) : (
            <div className="no-photos">
              <p>Fotosid ei leitud. Proovi muuta filtreid või lisa uusi pilte.</p>
            </div>
          )}
        </div>
      )}
      
      {selectedPhoto && (
        <div className="photo-detail-overlay" onClick={closePhotoDetail}>
          <div className="photo-detail" onClick={(e) => e.stopPropagation()}>
            <button className="close-button" onClick={closePhotoDetail}>×</button>
            
            <div className="detail-content">
              <div className="detail-image">
                <img 
                  src={`${STATIC_FILE_URL}/${getRelativeFilePath(selectedPhoto.photo.file_path)}`} 
                  alt="Looduspilt"
                  onError={(e) => {e.target.src = '/placeholder.jpg'}} 
                />
                
                <div className="image-actions">
                  <button 
                    className="ai-identify-button" 
                    onClick={handleAIIdentify}
                    disabled={identifyingPhoto || loading}
                  >
                    {identifyingPhoto ? 'Tuvastamine...' : 'Tuvasta AI-ga taimed'}
                  </button>
                  
                  <button 
                    className="edit-button" 
                    onClick={handleEditClick}
                    disabled={editMode || loading}
                  >
                    Muuda andmeid
                  </button>
                  
                  <button 
                    className="delete-button" 
                    onClick={handleDeleteClick}
                    disabled={confirmDelete || loading}
                  >
                    Kustuta foto
                  </button>
                </div>
                
                {identificationSuccess && (
                  <div className="identification-success">
                    Taimed edukalt tuvastatud!
                  </div>
                )}
                
                {confirmDelete && (
                  <div className="confirm-delete">
                    <p>Kas olete kindel, et soovite selle foto kustutada?</p>
                    <div className="confirm-actions">
                      <button 
                        className="confirm-yes" 
                        onClick={handleDeleteConfirm}
                        disabled={loading}
                      >
                        {loading ? 'Kustutamine...' : 'Jah, kustuta'}
                      </button>
                      <button 
                        className="confirm-no" 
                        onClick={handleDeleteCancel}
                        disabled={loading}
                      >
                        Tühista
                      </button>
                    </div>
                  </div>
                )}
              </div>
              
              <div className="detail-info">
                {editMode ? (
                  <div className="edit-form">
                    <h3>Muuda foto andmeid</h3>
                    <form onSubmit={handleEditSubmit}>
                      <div className="form-group">
                        <label htmlFor="date">Kuupäev:</label>
                        <input 
                          type="date" 
                          id="date" 
                          name="date"
                          value={editForm.date}
                          onChange={handleEditFormChange}
                        />
                      </div>
                      
                      <div className="form-group">
                        <label htmlFor="location">Asukoht:</label>
                        <input 
                          type="text" 
                          id="location" 
                          name="location"
                          value={editForm.location}
                          onChange={handleEditFormChange}
                          placeholder="Sisesta asukoht"
                        />
                      </div>
                      
                      <div className="form-actions">
                        <button 
                          type="submit" 
                          className="save-button"
                          disabled={loading}
                        >
                          {loading ? 'Salvestamine...' : 'Salvesta'}
                        </button>
                        <button 
                          type="button" 
                          className="cancel-button"
                          onClick={handleEditCancel}
                          disabled={loading}
                        >
                          Tühista
                        </button>
                      </div>
                    </form>
                  </div>
                ) : (
                  <>
                    <h3>Foto detailid</h3>
                    <p><strong>ID:</strong> {selectedPhoto.photo.id}</p>
                    <p><strong>Kuupäev:</strong> {selectedPhoto.photo.date || 'Pole määratud'}</p>
                    <p><strong>Asukoht:</strong> {selectedPhoto.photo.location || 'Pole määratud'}</p>
                    
                    {/* Meta-andmete kuvamine, kui need on olemas */}
                    {(selectedPhoto.photo.gps_latitude || 
                      selectedPhoto.photo.gps_longitude || 
                      selectedPhoto.photo.gps_altitude ||
                      selectedPhoto.photo.camera_make ||
                      selectedPhoto.photo.camera_model) && (
                      <div className="metadata-section">
                        <h4>Foto metaandmed:</h4>
                        <div className="metadata-content">
                          {(selectedPhoto.photo.gps_latitude && selectedPhoto.photo.gps_longitude) && (
                            <p><strong>GPS koordinaadid:</strong> {selectedPhoto.photo.gps_latitude}, {selectedPhoto.photo.gps_longitude}
                              {selectedPhoto.photo.gps_altitude && `, kõrgus: ${selectedPhoto.photo.gps_altitude}m`}
                            </p>
                          )}
                          
                          {(selectedPhoto.photo.camera_make || selectedPhoto.photo.camera_model) && (
                            <p><strong>Kaamera:</strong> {[selectedPhoto.photo.camera_make, selectedPhoto.photo.camera_model].filter(Boolean).join(' ')}</p>
                          )}
                        </div>
                      </div>
                    )}
                  </>
                )}
                
                {editSpeciesMode ? (
                  <div className="edit-species-form">
                    <h3>Muuda liigi andmeid</h3>
                    <form onSubmit={handleEditSpeciesSubmit}>
                      <div className="form-group">
                        <label htmlFor="scientific_name">Teaduslik nimetus:</label>
                        <input 
                          type="text" 
                          id="scientific_name" 
                          name="scientific_name"
                          value={editSpecies.scientific_name}
                          onChange={handleEditSpeciesChange}
                          placeholder="Teaduslik nimetus"
                        />
                      </div>
                      
                      <div className="form-group">
                        <label htmlFor="common_name">Tavanimi:</label>
                        <input 
                          type="text" 
                          id="common_name" 
                          name="common_name"
                          value={editSpecies.common_name}
                          onChange={handleEditSpeciesChange}
                          placeholder="Tavanimi"
                        />
                      </div>
                      
                      <div className="form-group">
                        <label htmlFor="family">Sugukond:</label>
                        <input 
                          type="text" 
                          id="family" 
                          name="family"
                          value={editSpecies.family}
                          onChange={handleEditSpeciesChange}
                          placeholder="Sugukond"
                        />
                      </div>
                      
                      <div className="form-actions">
                        <button 
                          type="submit" 
                          className="save-button"
                          disabled={loading}
                        >
                          {loading ? 'Salvestamine...' : 'Salvesta'}
                        </button>
                        <button 
                          type="button" 
                          className="cancel-button"
                          onClick={handleEditSpeciesCancel}
                          disabled={loading}
                        >
                          Tühista
                        </button>
                      </div>
                    </form>
                  </div>
                ) : (
                  <>
                    <h4>Tuvastatud taimeliigid:</h4>
                    {selectedPhoto.species && selectedPhoto.species.length > 0 ? (
                      <ul className="species-list">
                        {selectedPhoto.species.map(species => (
                          <li key={species.id} className="species-item">
                            <div className="species-content">
                              <div className="species-name">{species.scientific_name}</div>
                              <div className="species-common-name">
                                {species.common_name || 'Harilik nimi puudub'}
                              </div>
                              <div className="species-family">
                                Sugukond: {species.family || 'Teadmata'}
                              </div>
                            </div>
                            
                            <div className="species-actions">
                              <button 
                                className="edit-species-button" 
                                onClick={() => handleEditSpeciesClick(species)}
                                disabled={loading}
                              >
                                Muuda
                              </button>
                              <button 
                                className="delete-species-button" 
                                onClick={() => handleDeleteSpeciesClick(species)}
                                disabled={loading}
                              >
                                Kustuta
                              </button>
                            </div>
                            
                            {confirmDeleteSpecies && confirmDeleteSpecies.id === species.id && (
                              <div className="confirm-delete-species">
                                <p>Kas olete kindel, et soovite selle liigi kustutada?</p>
                                <div className="confirm-actions">
                                  <button 
                                    className="confirm-yes" 
                                    onClick={handleDeleteSpeciesConfirm}
                                    disabled={loading}
                                  >
                                    {loading ? 'Kustutamine...' : 'Jah, kustuta'}
                                  </button>
                                  <button 
                                    className="confirm-no" 
                                    onClick={handleDeleteSpeciesCancel}
                                    disabled={loading}
                                  >
                                    Tühista
                                  </button>
                                </div>
                              </div>
                            )}
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p>Liike pole tuvastatud. Kasuta "Tuvasta AI-ga taimed" nuppu, et määrata foto liigid.</p>
                    )}
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FotodeBrowser;