# Nature Photo Database Architecture Plan

## Overview
The application allows users to upload nature photos, automatically detects plant species in the photos using an AI model, and stores the data in a database. Users can later search and filter photos by species, location, date, and other categories.

## Components

### 1. Frontend (Web Application)
- **Features**:
  - Photo upload functionality
  - Preview and edit detection results before saving
  - Search and filter forms
- **Recommended Technology**: React.js / Next.js

### 2. Backend (API Server)
- **Features**:
  - Receive uploaded files
  - Analyze photos using an AI model (e.g., TensorFlow, PyTorch, or external services like Google Vision API / Plant.id API)
  - Save data to the database
  - Handle search and filter queries
- **Recommended Technology**: Python (FastAPI)

### 3. Database
- **Tables**:
  - `Photos`: Stores photo metadata (id, file path, date, location, etc.)
  - `Species`: Stores species information (id, scientific name, common name, family, etc.)
  - `PhotoSpeciesRelation`: Links photos to species (photo_id, species_id, additional categories)
- **Recommended Technology**: PostgreSQL

### 4. AI Component
- **Functionality**:
  - Analyze photos and return species names with confidence percentages
- **Recommended Technology**: Plant.id API / TensorFlow model

### 5. File Storage
- **Options**:
  - AWS S3
  - Local server

## Workflow

### Uploading a Photo
1. User uploads a photo via the frontend.
2. The photo is sent to the backend API.
3. The backend saves the photo and triggers the AI detection.
4. The AI model analyzes the photo and returns detection results.
5. The backend sends the results back to the frontend for preview and editing.

### Saving Data
1. User confirms or edits the AI detection results.
2. The backend saves the photo-species relationships and metadata to the database.

### Searching
1. User searches for a species or applies filters via the frontend.
2. The frontend sends a query to the backend API.
3. The backend retrieves matching results from the database and returns them to the frontend.

## Pseudocode Plan

### Uploading a Photo
```
User -> Upload photo -> API
API -> Save photo -> Run AI detection -> Return detection results
```

### Saving Data
```
User confirms or edits AI results
API -> Save species and photo relationships to the database
```

### Searching
```
User searches for a species or applies filters -> API query -> Return results
```