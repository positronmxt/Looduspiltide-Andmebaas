import React, { useState, useRef, useCallback } from 'react';
import './MassPhotoUploader.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

/**
 * Massilise piltide üleslaadimise komponent.
 * Võimaldab laadida üles mitu pilti korraga.
 */
const MassPhotoUploader = () => {
  const [files, setFiles] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(null);
  const [error, setError] = useState('');
  const [progress, setProgress] = useState(0);
  const [uploadStatus, setUploadStatus] = useState([]); // [{name, status, message, id}]
  const [location, setLocation] = useState('');
  const [date, setDate] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const fileInputRef = useRef(null);
  
  // Drag & Drop tugi
  const [isDragging, setIsDragging] = useState(false);
  
  const handleDragOver = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  }, []);
  
  const handleDragLeave = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  }, []);
  
  const handleDrop = useCallback((e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    
    const droppedFiles = Array.from(e.dataTransfer.files).filter(
      file => file.type.startsWith('image/')
    );
    
    if (droppedFiles.length === 0) {
      setError('Palun vali ainult pildifaile (jpg, png, jne)');
      return;
    }
    
    setError('');
    addNewFiles(droppedFiles);
  }, []);
  
  /**
   * Lisab uued failid olemasolevasse nimekirja, vältides duplikaate
   * faili nime ja suuruse põhjal
   */
  const addNewFiles = useCallback((newFiles) => {
    setFiles(prevFiles => {
      // Filtreerime välja duplikaadid
      const uniqueNewFiles = newFiles.filter(newFile => 
        !prevFiles.some(existingFile => 
          existingFile.name === newFile.name && 
          existingFile.size === newFile.size
        )
      );
      
      return [...prevFiles, ...uniqueNewFiles];
    });
  }, []);
  
  /**
   * Käsitleb faili valimist sisendi väljalt
   */
  const handleFileChange = useCallback((e) => {
    const selectedFiles = Array.from(e.target.files).filter(
      file => file.type.startsWith('image/')
    );
    
    if (selectedFiles.length === 0) {
      setError('Palun vali ainult pildifaile (jpg, png, jne)');
      return;
    }
    
    setError('');
    addNewFiles(selectedFiles);
  }, [addNewFiles]);
  
  /**
   * Eemaldab faili nimekirjast
   */
  const handleRemoveFile = useCallback((index) => {
    setFiles(prevFiles => prevFiles.filter((_, i) => i !== index));
  }, []);
  
  /**
   * Tühjendab faili nimekirja
   */
  const handleClearFiles = useCallback(() => {
    setFiles([]);
    // Tühjendame ka input välja, et samu faile saaks uuesti valida
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  }, []);
  
  /**
   * Käsitleb ühe faili üleslaadimist
   */
  const uploadFile = useCallback(async (file, index) => {
    const formData = new FormData();
    formData.append('file', file);
    
    // Lisame kuupäeva ja asukoha, kui need on sisestatud
    if (date) {
      formData.append('date', date);
    }
    
    if (location) {
      formData.append('location', location);
    }
    
    try {
  const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.UPLOAD}`, {
        method: 'POST',
        body: formData,
      });
      
      if (!response.ok) {
        throw new Error(`Foto üleslaadimine ebaõnnestus: ${response.statusText}`);
      }
      
      const data = await response.json();
      
      setUploadStatus(prev => {
        const updated = [...prev];
        updated[index] = {
          name: file.name,
          status: 'success',
          message: `ID: ${data.photo_id}`,
          id: data.photo_id
        };
        return updated;
      });
      
      return true;
    } catch (err) {
      setUploadStatus(prev => {
        const updated = [...prev];
        updated[index] = {
          name: file.name,
          status: 'error',
          message: err.message || 'Viga faili üleslaadimisel',
          id: null
        };
        return updated;
      });
      
      return false;
    }
  }, [date, location]);
  
  /**
   * Käsitleb kõikide failide üleslaadimist
   */
  const handleSubmit = useCallback(async (e) => {
    e.preventDefault();
    
    if (files.length === 0) {
      setError('Palun vali vähemalt üks pilt');
      return;
    }
    
    setIsLoading(true);
    setIsProcessing(true);
    setError('');
    setSuccess(null);
    setProgress(0);
    
    // Loome tühja staatuse array kõigi failide jaoks
    setUploadStatus(files.map(file => ({
      name: file.name,
      status: 'pending',
      message: 'Ootel...',
      id: null
    })));
    
    let successCount = 0;
    
    for (let i = 0; i < files.length; i++) {
      // Uuendame staatust, et näidata, millist faili parasjagu töödeldakse
      setUploadStatus(prev => {
        const updated = [...prev];
        updated[i] = {
          ...updated[i],
          status: 'uploading',
          message: 'Laadimine...'
        };
        return updated;
      });
      
      const success = await uploadFile(files[i], i);
      
      if (success) {
        successCount++;
      }
      
      // Uuendame progressi
      setProgress(((i + 1) / files.length) * 100);
    }
    
    setIsLoading(false);
    setIsProcessing(false);
    
    if (successCount === files.length) {
      setSuccess(`Kõik ${files.length} pilti on edukalt üles laaditud!`);
    } else if (successCount > 0) {
      setSuccess(`${successCount} pilti ${files.length}-st on edukalt üles laaditud.`);
    } else {
      setError('Kõik üleslaadimised ebaõnnestusid. Palun proovi uuesti.');
    }
  }, [files, uploadFile]);
  
  /**
   * Formaadib faili suuruse lugejasõbralikult
   */
  const formatFileSize = (bytes) => {
    if (bytes < 1024) return bytes + ' B';
    else if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
    else return (bytes / 1048576).toFixed(1) + ' MB';
  };
  
  return (
    <div className="mass-photo-uploader">
      <h2>Piltide Üleslaadimine</h2>
      <p className="uploader-info">
        See vaade võimaldab laadida üles mitu looduspilti korraga. 
        Piltide üleslaadimiseks võid kasutada faili valimist või lohistada pildid siia aknasse.
      </p>
      
      {success && <div className="success-message">{success}</div>}
      {error && <div className="error-message">{error}</div>}
      
      <form onSubmit={handleSubmit} className="upload-form">
        <div 
          className={`drop-zone ${isDragging ? 'dragging' : ''}`}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
        >
          <div className="drop-zone-content">
            <span className="drop-icon">📷</span>
            <p>Lohista pildid siia või</p>
            <label htmlFor="file-upload-mass" className="custom-file-upload">
              Vali Pildid
            </label>
            <input 
              id="file-upload-mass" 
              type="file" 
              accept="image/*" 
              onChange={handleFileChange}
              multiple
              ref={fileInputRef}
            />
            <p className="drop-hint">Saad valida mitu faili korraga</p>
          </div>
        </div>
        
        {files.length > 0 && (
          <div className="files-preview">
            <div className="files-header">
              <h3>Valitud failid ({files.length})</h3>
              <button 
                type="button" 
                className="clear-button"
                onClick={handleClearFiles}
                disabled={isProcessing}
              >
                Tühjenda nimekiri
              </button>
            </div>
            
            <div className="files-list">
              {files.map((file, index) => {
                const status = uploadStatus[index] || { status: 'pending', message: 'Ootel...' };
                
                return (
                  <div 
                    key={`${file.name}-${file.size}-${index}`} 
                    className={`file-item ${status.status}`}
                  >
                    <div className="file-preview">
                      <img 
                        src={URL.createObjectURL(file)} 
                        alt={file.name} 
                        className="file-thumbnail" 
                      />
                    </div>
                    <div className="file-info">
                      <div className="file-name" title={file.name}>
                        {file.name}
                      </div>
                      <div className="file-meta">
                        {formatFileSize(file.size)}
                      </div>
                      <div className={`file-status ${status.status}`}>
                        {status.message}
                      </div>
                    </div>
                    <button 
                      type="button" 
                      className="remove-file" 
                      onClick={() => handleRemoveFile(index)}
                      disabled={isProcessing}
                      title="Eemalda fail"
                    >
                      &times;
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        )}
        
        <div className="form-group">
          <label htmlFor="date-input-mass">Kuupäev (valikuline, rakendub kõigile piltidele):</label>
          <input 
            id="date-input-mass" 
            type="date" 
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="date-input"
          />
          <p className="input-hint">Kui jätad tühjaks, püütakse kuupäev lugeda iga pildi metaandmetest või kasutatakse tänast kuupäeva.</p>
        </div>
        
        <div className="form-group">
          <label htmlFor="location-input-mass">Asukoht (valikuline, rakendub kõigile piltidele):</label>
          <input 
            id="location-input-mass" 
            type="text" 
            value={location}
            onChange={(e) => setLocation(e.target.value)}
            placeholder="Sisesta asukoht (nt. 'Saaremaa, Kuressaare')"
            className="location-input"
          />
          <p className="input-hint">Kui jätad tühjaks, püütakse asukoht lugeda iga pildi GPS metaandmetest.</p>
        </div>
        
        {files.length > 0 && (
          <div className="upload-progress-container">
            {isLoading && (
              <>
                <div className="progress-bar">
                  <div 
                    className="progress-fill" 
                    style={{ width: `${progress}%` }}
                  ></div>
                </div>
                <div className="progress-text">
                  {Math.round(progress)}% - {uploadStatus.filter(s => s.status === 'success').length}/{files.length} laaditud
                </div>
              </>
            )}
          </div>
        )}
        
        <button 
          type="submit" 
          className="upload-button"
          disabled={isLoading || files.length === 0}
        >
          {isLoading ? 'Laadimine...' : `Lae üles ${files.length > 0 ? `(${files.length} pilti)` : ''}`}
        </button>
      </form>
    </div>
  );
};

export default MassPhotoUploader;