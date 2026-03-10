import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/config';  // Import your api instance

function AddPatient() {
  const navigate = useNavigate();
  const token = localStorage.getItem('token');
  
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    address: '',
    dateOfBirth: '',
    registeredDate: new Date().toISOString().split('T')[0]
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      // Use formData, not patientData (undefined variable)
      await api.post('/api/patients', formData);
      navigate('/patients');
    } catch (err) {
      console.error('Error adding patient:', err);
      setError(err.response?.data?.message || 'Failed to add patient');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="form-container">
      <h2>Add New Patient</h2>
      {error && <div className="error-message">{error}</div>}
      <form onSubmit={handleSubmit} className="patient-form">
        <div className="form-group">
          <label>Name:</label>
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
            className="form-input"
          />
        </div>
        
        <div className="form-group">
          <label>Email:</label>
          <input
            type="email"
            name="email"
            value={formData.email}
            onChange={handleChange}
            required
            className="form-input"
          />
        </div>
        
        <div className="form-group">
          <label>Address:</label>
          <input
            type="text"
            name="address"
            value={formData.address}
            onChange={handleChange}
            required
            className="form-input"
          />
        </div>
        
        <div className="form-group">
          <label>Date of Birth:</label>
          <input
            type="date"
            name="dateOfBirth"
            value={formData.dateOfBirth}
            onChange={handleChange}
            required
            className="form-input"
          />
        </div>
        
        <div className="form-group">
          <label>Registered Date:</label>
          <input
            type="date"
            name="registeredDate"
            value={formData.registeredDate}
            onChange={handleChange}
            required
            className="form-input"
          />
        </div>
        
        <div className="form-actions">
          <button type="button" onClick={() => navigate('/patients')} className="btn-cancel">
            Cancel
          </button>
          <button type="submit" disabled={loading} className="btn-submit">
            {loading ? 'Creating...' : 'Create Patient'}
          </button>
        </div>
      </form>
    </div>
  );
}

export default AddPatient;