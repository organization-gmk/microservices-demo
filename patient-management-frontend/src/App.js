import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import ErrorBoundary from './components/ErrorBoundary';
import Login from './components/Login';
import PatientList from './components/PatientList';
import AddPatient from './components/AddPatient';
import EditPatient from './components/EditPatient';
import Navbar from './components/Navbar';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(!!localStorage.getItem('token'));

  useEffect(() => {
    const checkAuth = () => {
      setIsAuthenticated(!!localStorage.getItem('token'));
    };
    
    window.addEventListener('storage', checkAuth);
    window.addEventListener('authChange', checkAuth);
    
    return () => {
      window.removeEventListener('storage', checkAuth);
      window.removeEventListener('authChange', checkAuth);
    };
  }, []);

  return (
    <ErrorBoundary>
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
                element={
                  isAuthenticated ? 
                    <ErrorBoundary><PatientList /></ErrorBoundary> : 
                    <Navigate to="/login" replace />
                } 
              />
              <Route 
                path="/patients/add" 
                element={
                  isAuthenticated ? 
                    <ErrorBoundary><AddPatient /></ErrorBoundary> : 
                    <Navigate to="/login" replace />
                } 
              />
              <Route 
                path="/patients/edit/:id" 
                element={
                  isAuthenticated ? 
                    <ErrorBoundary><EditPatient /></ErrorBoundary> : 
                    <Navigate to="/login" replace />
                } 
              />
              <Route path="/" element={<Navigate to="/patients" replace />} />
            </Routes>
          </div>
        </div>
      </Router>
    </ErrorBoundary>
  );
}

export default App;