import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import PatientList from './components/PatientList';
import AddPatient from './components/AddPatient';
import EditPatient from './components/EditPatient';
import Navbar from './components/Navbar';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(!!localStorage.getItem('token'));

  useEffect(() => {
    // Check authentication status on mount and when token changes
    const checkAuth = () => {
      setIsAuthenticated(!!localStorage.getItem('token'));
    };

    // Check immediately
    checkAuth();

    // Listen for storage changes (when token is set in another tab)
    window.addEventListener('storage', checkAuth);
    
    // Custom event for same-tab updates
    window.addEventListener('authChange', checkAuth);

    return () => {
      window.removeEventListener('storage', checkAuth);
      window.removeEventListener('authChange', checkAuth);
    };
  }, []);

  return (
    <Router>
      <div className="App">
        <Navbar isAuthenticated={isAuthenticated} />
        <div className="container">
          <Routes>
            <Route path="/login" element={
              isAuthenticated ? <Navigate to="/patients" replace /> : <Login />
            } />
            <Route 
              path="/patients" 
              element={isAuthenticated ? <PatientList /> : <Navigate to="/login" replace />} 
            />
            <Route 
              path="/patients/add" 
              element={isAuthenticated ? <AddPatient /> : <Navigate to="/login" replace />} 
            />
            <Route 
              path="/patients/edit/:id" 
              element={isAuthenticated ? <EditPatient /> : <Navigate to="/login" replace />} 
            />
            <Route path="/" element={<Navigate to="/patients" replace />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;