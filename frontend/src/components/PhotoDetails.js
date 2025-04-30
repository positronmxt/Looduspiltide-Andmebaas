import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import './PhotoDetails.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

const PhotoDetails = () => {
  const { photoId } = useParams();
  const [photoDetails, setPhotoDetails] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [selectedSpecies, setSelectedSpecies] = useState('');

  useEffect(() => {
    if (photoId) {
      fetchPhotoDetails();
    }
  }, [photoId]);

  const fetchPhotoDetails = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/${photoId}`);
      if (!response.ok) {
        throw new Error('Failed to fetch photo details');
      }
      const data = await response.json();
      setPhotoDetails(data);
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSpeciesSelection = async () => {
    if (!selectedSpecies) return;
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/${photoId}/species/${selectedSpecies}`, {
        method: 'POST',
      });
      if (!response.ok) {
        throw new Error('Failed to update species');
      }
      const data = await response.json();
      setPhotoDetails(data);
    } catch (error) {
      setError(error.message);
    }
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="photo-details">
      {photoDetails ? (
        <div>
          <h1>{photoDetails.title}</h1>
          <img src={photoDetails.url} alt={photoDetails.title} />
          <p>{photoDetails.description}</p>
          <select
            value={selectedSpecies}
            onChange={(e) => setSelectedSpecies(e.target.value)}
          >
            <option value="">Select species</option>
            {photoDetails.species.map((species) => (
              <option key={species.id} value={species.id}>
                {species.name}
              </option>
            ))}
          </select>
          <button onClick={handleSpeciesSelection}>Update Species</button>
        </div>
      ) : (
        <div>No photo details available</div>
      )}
    </div>
  );
};

export default PhotoDetails;