import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../api/config';

function EditPatient() {
  const navigate = useNavigate();
  const { id } = useParams();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    address: '',
    dateOfBirth: '',
    registeredDate: ''
  });
  const [loading, setLoading] = useState(false);
  const [fetchLoading, setFetchLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchPatient();
  }, [id]);

  const fetchPatient = async () => {
    try {
      const response = await api.get(`/api/patients/${id}`);
      setFormData(response.data);
    } catch (err) {
      setError('Failed to load patient data');
      console.error('Error fetching patient:', err);
    } finally {
      setFetchLoading(false);
    }
  };

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
      await api.put(`/api/patients/${id}`, formData);
      navigate('/patients');
    } catch (err) {
      console.error('Error updating patient:', err);
      setError(err.response?.data?.message || 'Failed to update patient');
    } finally {
      setLoading(false);
    }
  };

  if (fetchLoading) return <div className="loading">Loading patient data...</div>;

  return (
    <div className="form-container">
      <h2>Edit Patient</h2>
      {error && <div className="error-message">{error}</div>}
      <form onSubmit={handleSubmit} className="patient-form">
        {/* Same form fields as AddPatient */}
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
            {loading ? 'Updating...' : 'Update Patient'}
          </button>
        </div>
      </form>
    </div>
  );
}

export default EditPatient;