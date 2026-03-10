import React from 'react';
import { Link, useNavigate } from 'react-router-dom';

function Navbar({ isAuthenticated }) {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('token');
    window.dispatchEvent(new Event('authChange'));
    navigate('/login', { replace: true });
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <nav className="navbar">
      <div className="nav-container">
        <Link to="/patients" className="nav-brand">Patient Management</Link>
        <div className="nav-links">
          <Link to="/patients" className="nav-link">Patients</Link>
          <Link to="/patients/add" className="nav-link">Add Patient</Link>
          <button onClick={handleLogout} className="nav-link logout-btn">Logout</button>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;