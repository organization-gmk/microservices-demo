import axios from 'axios';

// Create axios instance with defaults
const api = axios.create({
  baseURL: '',  // Relative URLs
  headers: {
    'Content-Type': 'application/json'
  },
  timeout: 10000 // 10 second timeout
});

// Request interceptor to add token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Log requests in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`🚀 ${config.method.toUpperCase()} ${config.url}`, config.data);
    }
    
    return config;
  },
  (error) => {
    console.error('❌ Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    // Log responses in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`✅ ${response.status} ${response.config.url}`, response.data);
    }
    return response;
  },
  (error) => {
    // Log errors
    console.error('❌ Response Error:', {
      message: error.message,
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
      data: error.response?.data
    });

    // Handle specific error statuses
    if (error.response) {
      switch (error.response.status) {
        case 400:
          error.userMessage = error.response.data?.message || 'Bad request. Please check your input.';
          break;
        case 401:
          error.userMessage = 'Your session has expired. Please login again.';
          // Clear token and redirect to login
          localStorage.removeItem('token');
          window.location.href = '/login';
          break;
        case 403:
          error.userMessage = 'You don\'t have permission to perform this action.';
          break;
        case 404:
          error.userMessage = 'Resource not found.';
          break;
        case 409:
          error.userMessage = error.response.data?.message || 'Conflict with existing data.';
          break;
        case 422:
          error.userMessage = error.response.data?.message || 'Validation failed. Please check your input.';
          break;
        case 500:
          error.userMessage = 'Server error. Please try again later.';
          break;
        case 503:
          error.userMessage = 'Service unavailable. Please try again later.';
          break;
        default:
          error.userMessage = error.response.data?.message || 'An unexpected error occurred.';
      }
    } else if (error.request) {
      // Request was made but no response received
      error.userMessage = 'No response from server. Please check your network connection.';
    } else {
      // Something happened in setting up the request
      error.userMessage = error.message || 'Failed to make request.';
    }

    return Promise.reject(error);
  }
);

export default api;