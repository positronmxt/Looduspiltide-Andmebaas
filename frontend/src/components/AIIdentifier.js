import React, { useState } from 'react';
import './AIIdentifier.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

const AIIdentifier = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [error, setError] = useState(null);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!selectedFile) {
      setError('Palun vali pilt, mida tuvastada!');
      return;
    }
    
    setLoading(true);
    setError(null);
    setResult(null);
    
    const formData = new FormData();
    formData.append('file', selectedFile);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.IDENTIFY}`, {
        method: 'POST',
        body: formData,
      });
      
      if (!response.ok) {
        throw new Error('Tuvastamine ebaõnnestus!');
      }
      
      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleFileChange = (e) => {
    setSelectedFile(e.target.files[0]);
  };

  return (
    <div className="ai-identifier">
      <form onSubmit={handleSubmit}>
        <input type="file" onChange={handleFileChange} />
        <button type="submit" disabled={loading}>
          {loading ? 'Tuvastamine...' : 'Tuvasta'}
        </button>
      </form>
      {error && <p className="error">{error}</p>}
      {result && <div className="result">{JSON.stringify(result)}</div>}
    </div>
  );
};

export default AIIdentifier;