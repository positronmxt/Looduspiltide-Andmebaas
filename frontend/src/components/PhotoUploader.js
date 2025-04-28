import React, { useState, useEffect } from 'react';
import './PhotoUploader.css';

/**
 * Lihtsate piltide üleslaadimise komponent.
 * Võimaldab laadida üles pilte ilma AI tuvastuseta.
 */
const PhotoUploader = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [preview, setPreview] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(null);
  const [error, setError] = useState('');
  const [location, setLocation] = useState('');
  const [date, setDate] = useState('');
  const [metaData, setMetaData] = useState(null);
  const [isLoadingMeta, setIsLoadingMeta] = useState(false);

  /**
   * Käsitleb faili valimist sisendi väljalt
   */
  const handleFileChange = async (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
      setPreview(URL.createObjectURL(file));
      setError('');
      
      // Kohe pärast pildi valimist proovi lugeda metaandmeid
      setIsLoadingMeta(true);
      await fetchImageMetadata(file);
    }
  };

  /**
   * Loeb pildi metaandmeid, saates selle ajutisele API otspunktile
   */
  const fetchImageMetadata = async (file) => {
    try {
      const formData = new FormData();
      formData.append('file', file);

      // Saada fail serverile, et lugeda metaandmeid
      const response = await fetch('http://localhost:8001/photos/extract-metadata', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Metaandmete lugemine ebaõnnestus');
      }

      const data = await response.json();
      setMetaData(data);
      
      // Täida vormi väljad metaandmetest, kui need on saadaval
      if (data.date) {
        setDate(data.date);
      }
      
      if (data.location) {
        setLocation(data.location);
      }
      
    } catch (err) {
      console.error('Viga metaandmete lugemisel:', err);
      // Metaandmete lugemise viga pole kriitiline, seega ei näita kasutajale
    } finally {
      setIsLoadingMeta(false);
    }
  };

  /**
   * Esitab pildi üleslaadimiseks
   */
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!selectedFile) {
      setError('Palun vali esmalt pilt');
      return;
    }

    setIsLoading(true);
    setError('');
    setSuccess(null);

    const formData = new FormData();
    formData.append('file', selectedFile);
    
    // Lisame kuupäeva ja asukoha, kui need on sisestatud
    if (date) {
      formData.append('date', date);
    }
    
    if (location) {
      formData.append('location', location);
    }
    
    // Lisame võimalikud GPS koordinaadid, kui need on saadaval metaandmetest
    if (metaData) {
      if (metaData.gps_latitude) {
        formData.append('gps_latitude', metaData.gps_latitude);
      }
      
      if (metaData.gps_longitude) {
        formData.append('gps_longitude', metaData.gps_longitude);
      }
      
      if (metaData.gps_altitude) {
        formData.append('gps_altitude', metaData.gps_altitude);
      }
      
      if (metaData.camera_make) {
        formData.append('camera_make', metaData.camera_make);
      }
      
      if (metaData.camera_model) {
        formData.append('camera_model', metaData.camera_model);
      }
    }

    try {
      const response = await fetch('http://localhost:8001/photos/upload', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Foto üleslaadimine ebaõnnestus');
      }

      const data = await response.json();
      setSuccess(`Foto edukalt üles laaditud ID-ga: ${data.photo_id}`);
      
      // Lähtesta vorm pärast edukat üleslaadimist
      setSelectedFile(null);
      setPreview('');
      setLocation('');
      setDate('');
      setMetaData(null);
      
    } catch (err) {
      setError(err.message || 'Viga foto üleslaadimisel');
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Formaaditakse metaandmete kuva
   */
  const renderMetadata = () => {
    if (isLoadingMeta) {
      return <div className="loading-meta">Metaandmete lugemine...</div>;
    }

    if (!metaData) return null;

    return (
      <div className="metadata-display">
        <h4>Pildi metaandmed:</h4>
        <table>
          <tbody>
            {metaData.date && (
              <tr>
                <td>Kuupäev:</td>
                <td>{metaData.date}</td>
              </tr>
            )}
            {metaData.location && (
              <tr>
                <td>Asukoht:</td>
                <td>{metaData.location}</td>
              </tr>
            )}
            {(metaData.gps_latitude && metaData.gps_longitude) && (
              <tr>
                <td>GPS koordinaadid:</td>
                <td>{metaData.gps_latitude}, {metaData.gps_longitude}{metaData.gps_altitude ? `, kõrgus: ${metaData.gps_altitude}m` : ''}</td>
              </tr>
            )}
            {(metaData.camera_make || metaData.camera_model) && (
              <tr>
                <td>Kaamera:</td>
                <td>{[metaData.camera_make, metaData.camera_model].filter(Boolean).join(' ')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    );
  };

  return (
    <div className="photo-uploader">
      <h2>Lihtsalt Pildi Üleslaadimine</h2>
      <p className="uploader-info">
        See vaade võimaldab laadida üles looduspilte ilma AI taimetuvastuseta. 
        Piltide metaandmetest (EXIF) püütakse automaatselt lugeda kuupäeva ja asukohainfot.
      </p>
      
      {success && <div className="success-message">{success}</div>}
      {error && <div className="error-message">{error}</div>}
      
      <form onSubmit={handleSubmit} className="upload-form">
        <div className="file-input-container">
          <label htmlFor="file-upload" className="custom-file-upload">
            Vali Pilt
          </label>
          <input 
            id="file-upload" 
            type="file" 
            accept="image/*" 
            onChange={handleFileChange} 
          />
          {selectedFile && (
            <span className="file-name">{selectedFile.name}</span>
          )}
        </div>
        
        {preview && (
          <div className="preview-container">
            <h3>Pildi eelvaade</h3>
            <img src={preview} alt="Eelvaade" className="image-preview" />
          </div>
        )}
        
        {renderMetadata()}
        
        <div className="form-group">
          <label htmlFor="date-input">Kuupäev (valikuline):</label>
          <input 
            id="date-input" 
            type="date" 
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="date-input"
          />
          <p className="input-hint">Kui jätad tühjaks, püütakse kuupäev lugeda pildi metaandmetest või kasutatakse tänast kuupäeva.</p>
        </div>
        
        <div className="form-group">
          <label htmlFor="location-input">Asukoht (valikuline):</label>
          <input 
            id="location-input" 
            type="text" 
            value={location}
            onChange={(e) => setLocation(e.target.value)}
            placeholder="Sisesta asukoht (nt. 'Saaremaa, Kuressaare')"
            className="location-input"
          />
          <p className="input-hint">Kui jätad tühjaks, püütakse asukoht lugeda pildi GPS metaandmetest.</p>
        </div>
        
        <button 
          type="submit" 
          className="upload-button"
          disabled={isLoading || !selectedFile}
        >
          {isLoading ? 'Üleslaadimine...' : 'Lae Pilt Üles'}
        </button>
      </form>
    </div>
  );
};

export default PhotoUploader;