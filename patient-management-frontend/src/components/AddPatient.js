import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/config';

function AddPatient() {
  const navigate = useNavigate();
  
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    address: '',
    dateOfBirth: '',
    registeredDate: new Date().toISOString().split('T')[0]
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
    // Clear field error when user starts typing
    if (fieldErrors[name]) {
      setFieldErrors({
        ...fieldErrors,
        [name]: ''
      });
    }
  };

  const validateForm = () => {
    const errors = {};
    
    if (!formData.name.trim()) {
      errors.name = 'Name is required';
    } else if (formData.name.length < 2) {
      errors.name = 'Name must be at least 2 characters';
    }
    
    if (!formData.email.trim()) {
      errors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      errors.email = 'Email is invalid';
    }
    
    if (!formData.address.trim()) {
      errors.address = 'Address is required';
    }
    
    if (!formData.dateOfBirth) {
      errors.dateOfBirth = 'Date of birth is required';
    } else {
      const dob = new Date(formData.dateOfBirth);
      const today = new Date();
      if (dob > today) {
        errors.dateOfBirth = 'Date of birth cannot be in the future';
      }
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
      console.log('📤 Submitting patient:', formData);
      
      const response = await api.post('/api/patients', formData);
      
      console.log('✅ Patient created:', response.data);
      
      // Show success message (optional)
      alert('Patient created successfully!');
      
      // Navigate back to patient list
      navigate('/patients');
      
    } catch (err) {
      console.error('❌ Error creating patient:', err);
      
      // Handle field-specific errors from server
      if (err.response?.data?.fieldErrors) {
        setFieldErrors(err.response.data.fieldErrors);
      }
      
      // Handle specific error cases
      if (err.response?.status === 409) {
        setError('A patient with this email already exists.');
      } else if (err.response?.status === 400) {
        setError(err.response.data?.message || 'Invalid data. Please check your input.');
      } else {
        // Use the user-friendly message from the interceptor
        setError(err.userMessage || 'Failed to create patient. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="form-container">
      <h2>Add New Patient</h2>
      
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
            value={formData.name}
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
            value={formData.email}
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
            value={formData.address}
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
            value={formData.dateOfBirth}
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
            value={formData.registeredDate}
            onChange={handleChange}
            className="form-input"
            disabled={loading}
          />
          <small className="help-text">Defaults to today's date</small>
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
                Creating...
              </>
            ) : 'Create Patient'}
          </button>
        </div>
      </form>
    </div>
  );
}

export default AddPatient;