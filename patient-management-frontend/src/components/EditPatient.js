import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../api/config';

function EditPatient() {
  const navigate = useNavigate();
  const { id } = useParams(); // Get patient ID from URL
  const [loading, setLoading] = useState(false);
  const [fetchLoading, setFetchLoading] = useState(true);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    address: '',
    dateOfBirth: '',
    registeredDate: ''
  });

  // Fetch patient data on component mount
  useEffect(() => {
    if (id) {
      fetchPatient();
    } else {
      setError('No patient ID provided');
      setFetchLoading(false);
    }
  }, [id]);

  const fetchPatient = async () => {
    try {
      setFetchLoading(true);
      setError('');
      
      console.log(`📥 Fetching patient with ID: ${id}`);
      const response = await api.get(`/api/patients/${id}`);
      
      console.log('✅ Patient data received:', response.data);
      
      // Format dates for input fields (YYYY-MM-DD)
      const patientData = { ...response.data };
      
      // Handle date formatting if needed
      if (patientData.dateOfBirth) {
        patientData.dateOfBirth = formatDateForInput(patientData.dateOfBirth);
      }
      if (patientData.registeredDate) {
        patientData.registeredDate = formatDateForInput(patientData.registeredDate);
      }
      
      setFormData(patientData);
      
    } catch (err) {
      console.error('❌ Error fetching patient:', err);
      
      if (err.response?.status === 404) {
        setError('Patient not found. It may have been deleted.');
      } else {
        setError(err.userMessage || 'Failed to load patient data. Please try again.');
      }
    } finally {
      setFetchLoading(false);
    }
  };

  // Helper to format date for input field
  const formatDateForInput = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return dateString; // Return original if invalid
    return date.toISOString().split('T')[0];
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
    // Clear field error when user types
    if (fieldErrors[name]) {
      setFieldErrors({
        ...fieldErrors,
        [name]: ''
      });
    }
  };

  const validateForm = () => {
    const errors = {};
    
    if (!formData.name?.trim()) {
      errors.name = 'Name is required';
    } else if (formData.name.length < 2) {
      errors.name = 'Name must be at least 2 characters';
    }
    
    if (!formData.email?.trim()) {
      errors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      errors.email = 'Email is invalid';
    }
    
    if (!formData.address?.trim()) {
      errors.address = 'Address is required';
    }
    
    if (!formData.dateOfBirth) {
      errors.dateOfBirth = 'Date of birth is required';
    }
    
    return errors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate form
    const errors = validateForm();
    if (Object.keys(errors).length > 0) {
      setFieldErrors(errors);
      setError('Please fix the errors below');
      return;
    }
    
    setLoading(true);
    setError('');
    setFieldErrors({});
    
    try {
      console.log(`📤 Updating patient ${id} with data:`, formData);
      
      const response = await api.put(`/api/patients/${id}`, formData);
      
      console.log('✅ Patient updated successfully:', response.data);
      
      // Show success message
      alert('Patient updated successfully!');
      
      // Navigate back to patient list
      navigate('/patients');
      
    } catch (err) {
      console.error('❌ Error updating patient:', err);
      
      // Handle field-specific errors
      if (err.response?.data?.fieldErrors) {
        setFieldErrors(err.response.data.fieldErrors);
      }
      
      // Handle specific status codes
      if (err.response?.status === 404) {
        setError('Patient not found. It may have been deleted.');
      } else if (err.response?.status === 409) {
        setError('A patient with this email already exists.');
      } else if (err.response?.status === 400) {
        setError(err.response.data?.message || 'Invalid data. Please check your input.');
      } else {
        setError(err.userMessage || 'Failed to update patient. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm('Are you sure you want to delete this patient?')) {
      return;
    }
    
    setLoading(true);
    setError('');
    
    try {
      await api.delete(`/api/patients/${id}`);
      alert('Patient deleted successfully!');
      navigate('/patients');
    } catch (err) {
      console.error('❌ Error deleting patient:', err);
      setError(err.userMessage || 'Failed to delete patient. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (fetchLoading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading patient data...</p>
      </div>
    );
  }

  return (
    <div className="form-container">
      <h2>Edit Patient</h2>
      
      {error && (
        <div className="error-message">
          <strong>Error:</strong> {error}
        </div>
      )}
      
      <form onSubmit={handleSubmit} className="patient-form" noValidate>
        <div className="form-group">
          <label htmlFor="name">Name *</label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name || ''}
            onChange={handleChange}
            className={`form-input ${fieldErrors.name ? 'error' : ''}`}
            placeholder="Enter full name"
            disabled={loading}
          />
          {fieldErrors.name && (
            <small className="field-error">{fieldErrors.name}</small>
          )}
        </div>
        
        <div className="form-group">
          <label htmlFor="email">Email *</label>
          <input
            type="email"
            id="email"
            name="email"
            value={formData.email || ''}
            onChange={handleChange}
            className={`form-input ${fieldErrors.email ? 'error' : ''}`}
            placeholder="Enter email address"
            disabled={loading}
          />
          {fieldErrors.email && (
            <small className="field-error">{fieldErrors.email}</small>
          )}
        </div>
        
        <div className="form-group">
          <label htmlFor="address">Address *</label>
          <input
            type="text"
            id="address"
            name="address"
            value={formData.address || ''}
            onChange={handleChange}
            className={`form-input ${fieldErrors.address ? 'error' : ''}`}
            placeholder="Enter address"
            disabled={loading}
          />
          {fieldErrors.address && (
            <small className="field-error">{fieldErrors.address}</small>
          )}
        </div>
        
        <div className="form-group">
          <label htmlFor="dateOfBirth">Date of Birth *</label>
          <input
            type="date"
            id="dateOfBirth"
            name="dateOfBirth"
            value={formData.dateOfBirth || ''}
            onChange={handleChange}
            className={`form-input ${fieldErrors.dateOfBirth ? 'error' : ''}`}
            disabled={loading}
          />
          {fieldErrors.dateOfBirth && (
            <small className="field-error">{fieldErrors.dateOfBirth}</small>
          )}
        </div>
        
        <div className="form-group">
          <label htmlFor="registeredDate">Registered Date</label>
          <input
            type="date"
            id="registeredDate"
            name="registeredDate"
            value={formData.registeredDate || ''}
            onChange={handleChange}
            className="form-input"
            disabled={loading}
          />
        </div>
        
        <div className="form-actions">
          <button 
            type="button" 
            onClick={() => navigate('/patients')} 
            className="btn-cancel"
            disabled={loading}
          >
            Cancel
          </button>
          <button 
            type="submit" 
            disabled={loading} 
            className="btn-submit"
          >
            {loading ? (
              <>
                <span className="spinner"></span>
                Updating...
              </>
            ) : 'Update Patient'}
          </button>
          <button 
            type="button" 
            onClick={handleDelete}
            disabled={loading}
            className="btn-delete"
          >
            Delete
          </button>
        </div>
      </form>
    </div>
  );
}

export default EditPatient;