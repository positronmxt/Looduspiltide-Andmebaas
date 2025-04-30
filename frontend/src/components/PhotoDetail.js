import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import './PhotoDetail.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

function PhotoDetail() {
  const { photoId } = useParams();
  const [photoDetails, setPhotoDetails] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [searchResults, setSearchResults] = useState([]);

  useEffect(() => {
    fetchPhotoDetails();
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

  const handleSpeciesSelection = async (speciesId) => {
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.PHOTOS}/${photoId}/species/${speciesId}`, {
        method: 'POST',
      });
      if (!response.ok) {
        throw new Error('Failed to select species');
      }
      const data = await response.json();
      setPhotoDetails(data);
    } catch (error) {
      setError(error.message);
    }
  };

  const searchSpecies = async (query) => {
    if (!query.trim()) {
      setSearchResults([]);
      return;
    }
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}/search?query=${encodeURIComponent(query)}`);
      if (!response.ok) {
        throw new Error('Failed to search species');
      }
      const data = await response.json();
      setSearchResults(data);
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
    <div className="photo-detail">
      {photoDetails && (
        <div>
          <h1>{photoDetails.title}</h1>
          <img src={photoDetails.imageUrl} alt={photoDetails.title} />
          <p>{photoDetails.description}</p>
          <div>
            <h2>Species</h2>
            <ul>
              {photoDetails.species.map((species) => (
                <li key={species.id}>
                  <button onClick={() => handleSpeciesSelection(species.id)}>
                    {species.name}
                  </button>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h2>Search Species</h2>
            <input
              type="text"
              placeholder="Search species..."
              onChange={(e) => searchSpecies(e.target.value)}
            />
            <ul>
              {searchResults.map((result) => (
                <li key={result.id}>{result.name}</li>
              ))}
            </ul>
          </div>
        </div>
      )}
      <Link to="/">Back to Gallery</Link>
    </div>
  );
}

export default PhotoDetail;