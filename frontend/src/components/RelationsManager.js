import React, { useState, useEffect } from 'react';
import './RelationsManager.css';
import { API_BASE_URL, API_ENDPOINTS } from '../config/config';

function RelationsManager() {
  const [relations, setRelations] = useState([]);
  const [newRelation, setNewRelation] = useState({});
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    fetchRelations();
  }, []);

  const fetchRelations = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.RELATIONS}`);
      if (response.ok) {
        const data = await response.json();
        setRelations(data);
      } else {
        console.error('Failed to fetch relations');
      }
    } catch (error) {
      console.error('Error fetching relations:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddFormSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.RELATIONS}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(newRelation),
      });

      if (response.ok) {
        fetchRelations();
        setNewRelation({});
      } else {
        console.error('Failed to add relation');
      }
    } catch (error) {
      console.error('Error adding relation:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async (relationId) => {
    if (window.confirm('Kas olete kindel, et soovite selle suhte kustutada?')) {
      setIsLoading(true);

      try {
        const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.RELATIONS}/${relationId}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          fetchRelations();
        } else {
          console.error('Failed to delete relation');
        }
      } catch (error) {
        console.error('Error deleting relation:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  return (
    <div className="relations-manager">
      <h1>Relations Manager</h1>
      {isLoading && <p>Loading...</p>}
      <ul>
        {relations.map((relation) => (
          <li key={relation.id}>
            {relation.name}
            <button onClick={() => handleDelete(relation.id)}>Delete</button>
          </li>
        ))}
      </ul>
      <form onSubmit={handleAddFormSubmit}>
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
}

export default RelationsManager;