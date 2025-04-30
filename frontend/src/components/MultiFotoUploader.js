import React, { useState, useRef } from 'react';
import './MultiFotoUploader.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

const MultiFotoUploader = () => {
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [uploadedPhotos, setUploadedPhotos] = useState([]);
  const [errorMessage, setErrorMessage] = useState(null);
  const [identifyingPhotos, setIdentifyingPhotos] = useState(false);
  const fileInputRef = useRef();

  const handleFileChange = (e) => {
    setSelectedFiles(Array.from(e.target.files));
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    
    if (!selectedFiles.length) {
      setErrorMessage('Palun valige vähemalt üks fail.');
      return;
    }
    
    setErrorMessage(null);

    try {
      const formData = new FormData();
      selectedFiles.forEach(file => formData.append('photos', file));

      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.UPLOAD}/batch`, {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        setUploadedPhotos(data.photos);
        setSelectedFiles([]);
        fileInputRef.current.value = null;
      } else {
        setErrorMessage('Fotode üleslaadimine ebaõnnestus.');
      }
    } catch (error) {
      setErrorMessage('Fotode üleslaadimisel tekkis viga.');
    }
  };

  const handleAIIdentify = async () => {
    if (!uploadedPhotos || uploadedPhotos.length === 0) {
      setErrorMessage('Palun laadige kõigepealt fotosid üles.');
      return;
    }
    
    setIdentifyingPhotos(true);
    setErrorMessage(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PLANT_ID}/batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          photo_ids: uploadedPhotos.map(photo => photo.id)
        }),
      });

      if (!response.ok) {
        // Proovi saada täpsema veateate
        try {
          const errorData = await response.json();
          
          // Kontrolli, kas veateade on seotud API võtme puudumisega
          if (response.status === 400 && errorData.detail && 
              (errorData.detail.includes("API võti puudub") || 
              errorData.detail.includes("Plant.ID API võti") ||
              errorData.detail.includes("administreerimislehel"))) {
            throw new Error("Taimetuvastuse jaoks on vaja seadistada Plant.ID API võti. Palun minge administreerimislehele API võtme seadistamiseks.");
          }
        } catch (parseError) {
          // Kui veateate parsimine ebaõnnestus, kasuta üldist veateadet
        }
        
        setErrorMessage('AI tuvastamine ebaõnnestus.');
      } else {
        const data = await response.json();
        console.log('AI Identification Results:', data);
      }
    } catch (error) {
      setErrorMessage(error.message || 'AI tuvastamisel tekkis viga.');
    } finally {
      setIdentifyingPhotos(false);
    }
  };

  return (
    <div className="multi-foto-uploader">
      <form onSubmit={handleUpload}>
        <input
          type="file"
          multiple
          onChange={handleFileChange}
          ref={fileInputRef}
        />
        <button type="submit">Laadi üles</button>
      </form>
      {errorMessage && <p className="error-message">{errorMessage}</p>}
      {uploadedPhotos.length > 0 && (
        <div>
          <button onClick={handleAIIdentify} disabled={identifyingPhotos}>
            {identifyingPhotos ? 'Tuvastamine...' : 'Tuvasta taimed'}
          </button>
        </div>
      )}
    </div>
  );
};

export default MultiFotoUploader;