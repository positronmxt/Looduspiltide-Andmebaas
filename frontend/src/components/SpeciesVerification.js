import React, { useState } from 'react';
import './SpeciesVerification.css';

/**
 * TaimeliikiTuvastamine komponent piltide üleslaadimiseks ja taimeliikide tuvastamiseks.
 * Pakub kasutajaliidest piltide üleslaadimiseks ja kuvab tuvastamise tulemusi.
 */
const SpeciesVerification = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [preview, setPreview] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [identificationResults, setIdentificationResults] = useState([]);
  const [error, setError] = useState('');

  /**
   * Käsitleb faili valimist sisendi väljalt
   */
  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
      setPreview(URL.createObjectURL(file));
      setError('');
    }
  };

  /**
   * Esitab pildi tuvastamiseks
   */
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!selectedFile) {
      setError('Palun vali esmalt pilt');
      return;
    }

    setIsLoading(true);
    setError('');

    const formData = new FormData();
    formData.append('file', selectedFile);

    try {
      const response = await fetch('http://localhost:8001/identify/', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Taimeliigi tuvastamine ebaõnnestus');
      }

      const data = await response.json();
      setIdentificationResults(data);
    } catch (err) {
      setError(err.message || 'Viga taimeliigi tuvastamisel');
      setIdentificationResults([]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="species-verification">
      <h2>Taimeliigi Tuvastamine</h2>
      
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
        
        <button 
          type="submit" 
          className="identify-button"
          disabled={isLoading || !selectedFile}
        >
          {isLoading ? 'Tuvastamine...' : 'Tuvasta Liik'}
        </button>
      </form>

      {error && <div className="error-message">{error}</div>}

      <div className="results-container">
        <div className="image-preview">
          {preview && (
            <img src={preview} alt="Valitud pilt" className="preview-image" />
          )}
          {!preview && (
            <div className="no-image">
              <img src="/placeholder.jpg" alt="Kohatäitja" />
              <p>Vali pilt tuvastamiseks</p>
            </div>
          )}
        </div>

        <div className="identification-results">
          {identificationResults.length > 0 ? (
            <>
              <h3>Tuvastamise Tulemused</h3>
              <ul className="results-list">
                {identificationResults.map((result, index) => (
                  <li key={index} className="result-item">
                    <div className="result-header">
                      <span className="scientific-name">{result.scientific_name}</span>
                      <span className="probability">
                        {Math.round(result.probability * 100)}% tõenäosus
                      </span>
                    </div>
                    {result.common_names && result.common_names.length > 0 && (
                      <div className="common-names">
                        Tuntud kui: {result.common_names.join(', ')}
                      </div>
                    )}
                    <div className="taxonomy">
                      Sugukond: {result.family || 'Teadmata'}
                    </div>
                  </li>
                ))}
              </ul>
            </>
          ) : (
            !isLoading && (
              <div className="no-results">
                <p>Tuvastamise tulemused puuduvad</p>
              </div>
            )
          )}
          {isLoading && (
            <div className="loading">
              <p>Taimeliigi tuvastamine...</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default SpeciesVerification;