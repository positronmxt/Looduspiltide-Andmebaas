import React, { useState } from 'react';
import './App.css';
import SpeciesVerification from './components/SpeciesVerification';
import FotodeBrowser from './components/FotodeBrowser';
import PhotoUploader from './components/PhotoUploader';
import MassPhotoUploader from './components/MassPhotoUploader';

function App() {
  const [activeView, setActiveView] = useState('browser'); // 'verification', 'browser', 'uploader' või 'massUploader'

  return (
    <div className="App">
      <header className="App-header">
        <h1>Looduspiltide Andmebaas</h1>
        <p>Tuvasta ja katalogiseeri taimede liigid oma fotodel</p>
        
        <nav className="main-navigation">
          <button 
            className={activeView === 'verification' ? 'active' : ''}
            onClick={() => setActiveView('verification')}
          >
            Taime Tuvastamine
          </button>
          <button 
            className={activeView === 'uploader' ? 'active' : ''}
            onClick={() => setActiveView('uploader')}
          >
            Pildi Üleslaadimine
          </button>
          <button 
            className={activeView === 'massUploader' ? 'active' : ''}
            onClick={() => setActiveView('massUploader')}
          >
            Massiline Üleslaadimine
          </button>
          <button 
            className={activeView === 'browser' ? 'active' : ''}
            onClick={() => setActiveView('browser')}
          >
            Piltide Sirvimine
          </button>
        </nav>
      </header>
      
      <main>
        {activeView === 'verification' && <SpeciesVerification />}
        {activeView === 'uploader' && <PhotoUploader />}
        {activeView === 'massUploader' && <MassPhotoUploader />}
        {activeView === 'browser' && <FotodeBrowser />}
      </main>
      
      <footer>
        <p>&copy; {new Date().getFullYear()} Looduspiltide Andmebaas</p>
      </footer>
    </div>
  );
}

export default App;
