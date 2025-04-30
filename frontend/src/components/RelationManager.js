import React, { useState, useEffect } from 'react';
import './RelationManager.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

const RelationManager = () => {
  const [relations, setRelations] = useState([]);
  const [species, setSpecies] = useState([]);
  const [newRelation, setNewRelation] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchRelations();
    fetchSpecies();
  }, []);

  const fetchSpecies = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.SPECIES}`);
      if (!response.ok) {
        throw new Error('Failed to fetch species');
      }
      const data = await response.json();
      setSpecies(data);
    } catch (error) {
      setError(error.message);
    }
  };

  const fetchRelations = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.RELATIONS}`);
      if (!response.ok) {
        throw new Error('Failed to fetch relations');
      }
      const data = await response.json();
      setRelations(data);
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.RELATIONS}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(newRelation)
      });
      if (!response.ok) {
        throw new Error('Failed to submit relation');
      }
      const data = await response.json();
      setRelations([...relations, data]);
      setNewRelation({});
    } catch (error) {
      setError(error.message);
    }
  };

  return (
    <div className="relation-manager">
      <h1>Relation Manager</h1>
      {error && <p className="error">{error}</p>}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <ul>
          {relations.map((relation, index) => (
            <li key={index}>{relation.name}</li>
          ))}
        </ul>
      )}
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={newRelation.name || ''}
          onChange={(e) => setNewRelation({ ...newRelation, name: e.target.value })}
          placeholder="Relation Name"
        />
        <button type="submit">Add Relation</button>
      </form>
    </div>
  );
};

export default RelationManager;