import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../api/config';  // Use the centralized api instance (remove axios import)

function PatientList() {
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [deleteLoading, setDeleteLoading] = useState(null);

  // Don't recreate api instance - use the imported one
  // The interceptor in api/config already handles the token

  useEffect(() => {
    fetchPatients();
  }, []);

  const fetchPatients = async () => {
    try {
      // Use the imported api instance
      const response = await api.get('/api/patients');
      setPatients(response.data);
    } catch (err) {
      setError('Failed to load patients');
      // The interceptor in api/config will handle 401 redirect
      console.error('Error fetching patients:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this patient?')) return;
    
    setDeleteLoading(id);
    try {
      await api.delete(`/api/patients/${id}`);
      setPatients(patients.filter(p => p.id !== id));
    } catch (err) {
      alert('Failed to delete patient');
      console.error('Error deleting patient:', err);
    } finally {
      setDeleteLoading(null);
    }
  };

  if (loading) return <div className="loading">Loading patients...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="patient-list">
      <div className="list-header">
        <h2>Patient List</h2>
        <Link to="/patients/add" className="btn btn-primary">Add New Patient</Link>
      </div>
      
      {patients.length === 0 ? (
        <p>No patients found.</p>
      ) : (
        <div className="patient-grid">
          {patients.map(patient => (
            <div key={patient.id} className="patient-card">
              <h3>{patient.name}</h3>
              <p><strong>Email:</strong> {patient.email}</p>
              <p><strong>Address:</strong> {patient.address}</p>
              <p><strong>DOB:</strong> {patient.dateOfBirth}</p>
              <div className="card-actions">
                <Link to={`/patients/edit/${patient.id}`} className="btn-edit">Edit</Link>
                <button 
                  onClick={() => handleDelete(patient.id)}
                  disabled={deleteLoading === patient.id}
                  className="btn-delete"
                >
                  {deleteLoading === patient.id ? 'Deleting...' : 'Delete'}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default PatientList;