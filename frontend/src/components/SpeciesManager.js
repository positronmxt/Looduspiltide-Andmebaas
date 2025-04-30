import React, { useState, useEffect } from 'react';
import './SpeciesManager.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

const SpeciesManager = () => {
  const [species, setSpecies] = useState([]);
  const [newSpecies, setNewSpecies] = useState({
    scientific_name: '',
    common_name: '',
    family: ''
  });
  const [editForm, setEditForm] = useState({
    scientific_name: '',
    common_name: '',
    family: ''
  });
  const [editingSpecies, setEditingSpecies] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchSpecies();
  }, []);

  const fetchSpecies = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}`);
      if (!response.ok) {
        throw new Error('Failed to fetch species');
      }
      const data = await response.json();
      setSpecies(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!newSpecies.scientific_name || !newSpecies.common_name || !newSpecies.family) {
      setError('Palun täitke kõik väljad!');
      return;
    }
    
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(newSpecies)
      });
      if (!response.ok) {
        throw new Error('Failed to add species');
      }
      fetchSpecies();
      setNewSpecies({
        scientific_name: '',
        common_name: '',
        family: ''
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleEditFormSubmit = async (e) => {
    e.preventDefault();

    if (!editForm.scientific_name || !editForm.common_name || !editForm.family) {
      setError('Palun täitke kõik väljad!');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}/${editingSpecies.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          scientific_name: editForm.scientific_name,
          common_name: editForm.common_name,
          family: editForm.family
        }),
      });
      if (!response.ok) {
        throw new Error('Failed to update species');
      }
      fetchSpecies();
      setEditingSpecies(null);
      setEditForm({
        scientific_name: '',
        common_name: '',
        family: ''
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (speciesId) => {
    if (window.confirm('Kas olete kindel, et soovite selle liigi kustutada?')) {
      setLoading(true);
      setError(null);

      try {
        const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}/${speciesId}`, {
          method: 'DELETE',
        });
        if (!response.ok) {
          throw new Error('Failed to delete species');
        }
        fetchSpecies();
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewSpecies({
      ...newSpecies,
      [name]: value
    });
  };

  const handleEditInputChange = (e) => {
    const { name, value } = e.target;
    setEditForm({
      ...editForm,
      [name]: value
    });
  };

  const startEditing = (specie) => {
    setEditingSpecies(specie);
    setEditForm({
      scientific_name: specie.scientific_name,
      common_name: specie.common_name,
      family: specie.family
    });
  };

  return (
    <div className="species-manager">
      <h1>Liikide haldamine</h1>
      {loading && <p>Laadimine...</p>}
      {error && <p className="error">{error}</p>}
      <ul>
        {species.map((specie) => (
          <li key={specie.id}>
            {specie.common_name} ({specie.scientific_name})
            <button onClick={() => startEditing(specie)}>Muuda</button>
            <button onClick={() => handleDelete(specie.id)}>Kustuta</button>
          </li>
        ))}
      </ul>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          name="scientific_name"
          placeholder="Teaduslik nimi"
          value={newSpecies.scientific_name}
          onChange={handleInputChange}
        />
        <input
          type="text"
          name="common_name"
          placeholder="Üldnimi"
          value={newSpecies.common_name}
          onChange={handleInputChange}
        />
        <input
          type="text"
          name="family"
          placeholder="Perekond"
          value={newSpecies.family}
          onChange={handleInputChange}
        />
        <button type="submit">Lisa liik</button>
      </form>
      {editingSpecies && (
        <form onSubmit={handleEditFormSubmit}>
          <input
            type="text"
            name="scientific_name"
            placeholder="Teaduslik nimi"
            value={editForm.scientific_name}
            onChange={handleEditInputChange}
          />
          <input
            type="text"
            name="common_name"
            placeholder="Üldnimi"
            value={editForm.common_name}
            onChange={handleEditInputChange}
          />
          <input
            type="text"
            name="family"
            placeholder="Perekond"
            value={editForm.family}
            onChange={handleEditInputChange}
          />
          <button type="submit">Salvesta muudatused</button>
        </form>
      )}
    </div>
  );
}

export default SpeciesManager;