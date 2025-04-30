import React, { useState } from 'react';
import './App.css';
import FotodeBrowser from './components/FotodeBrowser';
import MassPhotoUploader from './components/MassPhotoUploader';
import AdminPanel from './components/AdminPanel';
import { API_BASE_URL, API_ENDPOINTS } from './config/config';

function App() {
  const [activeView, setActiveView] = useState('browser'); // 'browser', 'massUploader' või 'admin'

  return (
    <div className="App">
      <header className="App-header">
        <h1>Looduspiltide Andmebaas</h1>
        <p>Tuvasta ja katalogiseeri taimede liigid oma fotodel</p>
        
        <nav className="main-navigation">
          <button 
            className={activeView === 'massUploader' ? 'active' : ''}
            onClick={() => setActiveView('massUploader')}
          >
            Piltide Üleslaadimine
          </button>
          <button 
            className={activeView === 'browser' ? 'active' : ''}
            onClick={() => setActiveView('browser')}
          >
            Piltide Sirvimine
          </button>
          <button 
            className={activeView === 'admin' ? 'active' : ''}
            onClick={() => setActiveView('admin')}
          >
            Administreerimine
          </button>
        </nav>
      </header>
      
      <main>
        {activeView === 'massUploader' && <MassPhotoUploader />}
        {activeView === 'browser' && <FotodeBrowser />}
        {activeView === 'admin' && <AdminPanel />}
      </main>
      
      <footer>
        <p>&copy; {new Date().getFullYear()} Looduspiltide Andmebaas</p>
      </footer>
    </div>
  );
}

export default App;
