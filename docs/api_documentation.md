# API Dokumentatsioon

## Ülevaade

Looduspiltide Andmebaas pakub RESTful API liideseid piltide, taimeliikide ja andmete haldamiseks. Siin on kirjeldatud kõik saadaolevad API endpointid ja nende funktsioonid.

## Baas-URL

Arenduskeskkonnas: `http://localhost:8001`

## Piltide API

### Piltide Üles Laadimine

**Endpoint:** `POST /photos/upload`

**Kirjeldus:** Laadib üles ühe pildifaili ja teeb sellele lihtsa töötluse.

**Parameetrid:**
- `file` (kohustuslik): Pildifail
- `date` (valikuline): Pildi kuupäev (YYYY-MM-DD)
- `location` (valikuline): Pildi asukoht tekstina

**Vastus:**
```json
{
  "photo_id": 123,
  "file_path": "/file_storage/uuid-filename.jpg",
  "date": "2025-04-30",
  "location": "Tallinn, Estonia"
}
```

### Massiline Piltide Üles Laadimine

**Endpoint:** `POST /photos/upload/batch`

**Kirjeldus:** Laadib üles mitu pildifaili korraga.

**Parameetrid:**
- `photos` (kohustuslik): Pildifailide massiiv
- `date` (valikuline): Kuupäev kõigile piltidele
- `location` (valikuline): Asukoht kõigile piltidele

**Vastus:**
```json
{
  "photos": [
    {
      "photo_id": 123,
      "file_path": "/file_storage/uuid-filename1.jpg",
      "success": true
    },
    {
      "photo_id": 124,
      "file_path": "/file_storage/uuid-filename2.jpg",
      "success": true
    }
  ],
  "failed": []
}
```

### Pildi Info Muutmine

**Endpoint:** `PUT /photos/{photo_id}`

**Kirjeldus:** Uuendab olemasoleva pildi metaandmeid.

**Parameetrid:**
- `date` (valikuline): Uus kuupäev
- `location` (valikuline): Uus asukoht

**Vastus:**
```json
{
  "id": 123,
  "file_path": "/file_storage/uuid-filename.jpg",
  "date": "2025-05-01",
  "location": "Tartu, Estonia"
}
```

### Pildi Kustutamine

**Endpoint:** `DELETE /photos/{photo_id}`

**Kirjeldus:** Kustutab pildi ja sellega seotud andmed.

**Vastus:**
```json
{
  "success": true,
  "message": "Foto edukalt kustutatud"
}
```

### Piltide Otsimine

**Endpoint:** `GET /photos/`

**Kirjeldus:** Otsib pilte määratud filtrite alusel.

**Päringuparmeetrid:**
- `species_name` (valikuline): Taimeliigi nimi
- `location` (valikuline): Asukoht
- `date` (valikuline): Kuupäev (YYYY-MM-DD)

**Vastus:**
```json
[
  {
    "id": 123,
    "file_path": "/file_storage/uuid-filename1.jpg",
    "date": "2025-04-30",
    "location": "Tallinn, Estonia",
    "species": [
      {
        "id": 45,
        "scientific_name": "Taraxacum officinale",
        "common_name": "Võilill"
      }
    ]
  },
  ...
]
```

### Pildi Detailid

**Endpoint:** `GET /photos/{photo_id}`

**Kirjeldus:** Tagastab ühe pildi detailse info koos tuvastatud liikidega.

**Vastus:**
```json
{
  "id": 123,
  "file_path": "/file_storage/uuid-filename.jpg",
  "date": "2025-04-30",
  "location": "Tallinn, Estonia",
  "gps_latitude": 59.4370,
  "gps_longitude": 24.7536,
  "gps_altitude": 10,
  "camera_make": "Canon",
  "camera_model": "EOS 5D",
  "species": [
    {
      "id": 45,
      "scientific_name": "Taraxacum officinale",
      "common_name": "Võilill",
      "family": "Asteraceae"
    }
  ]
}
```

## Taimetuvastuse API

### Taime Tuvastamine Uuel Pildil

**Endpoint:** `POST /plant_id/`

**Kirjeldus:** Tuvastab taimeliigid üleslaetud pildil ja salvestab pildi.

**Parameetrid:**
- `file` (kohustuslik): Pildifail
- `location` (valikuline): Pildi asukoht

**Vastus:**
```json
[
  {
    "scientific_name": "Taraxacum officinale",
    "common_names": ["Võilill", "Dandelion"],
    "probability": 0.95,
    "family": "Asteraceae",
    "description": "..."
  },
  ...
]
```

### Taime Tuvastamine Olemasoleval Pildil

**Endpoint:** `POST /plant_id/existing/{photo_id}`

**Kirjeldus:** Tuvastab taimeliigid juba üleslaetud pildil.

**Vastus:**
```json
[
  {
    "scientific_name": "Taraxacum officinale",
    "common_names": ["Võilill", "Dandelion"],
    "probability": 0.95,
    "family": "Asteraceae",
    "description": "..."
  },
  ...
]
```

### Massiline Taimetuvastus

**Endpoint:** `POST /plant_id/batch`

**Kirjeldus:** Tuvastab taimeliigid mitmel olemasoleval pildil korraga.

**Parameetrid:**
```json
{
  "photo_ids": [123, 124, 125]
}
```

**Vastus:**
```json
{
  "results": [
    {
      "photo_id": 123,
      "species": [...],
      "success": true
    },
    ...
  ],
  "errors": []
}
```

## Liikide API

### Liigi Info Muutmine

**Endpoint:** `PUT /species/{species_id}`

**Kirjeldus:** Uuendab olemasoleva taimeliigi infot.

**Parameetrid:**
```json
{
  "scientific_name": "Taraxacum officinale",
  "common_name": "Võilill",
  "family": "Asteraceae"
}
```

**Vastus:**
```json
{
  "id": 45,
  "scientific_name": "Taraxacum officinale",
  "common_name": "Võilill",
  "family": "Asteraceae"
}
```

### Liigi Kustutamine

**Endpoint:** `DELETE /species/{species_id}`

**Kirjeldus:** Kustutab taimeliigi ja selle seosed piltidega.

**Vastus:**
```json
{
  "success": true,
  "message": "Liik edukalt kustutatud"
}
```

## Seadistuste API

### Kõik Seadistused

**Endpoint:** `GET /settings/`

**Kirjeldus:** Tagastab kõik rakenduse seadistused.

**Vastus:**
```json
[
  {
    "key": "PLANT_ID_API_KEY",
    "value": "xxxx",
    "description": "Plant.ID API võti taimetuvastuseks"
  },
  ...
]
```

### Seadistuse Uuendamine

**Endpoint:** `PUT /settings/{key}`

**Kirjeldus:** Uuendab konkreetse seadistuse väärtust.

**Parameetrid:**
```json
{
  "value": "uus väärtus",
  "description": "Uus kirjeldus"
}
```

**Vastus:**
```json
{
  "key": "PLANT_ID_API_KEY",
  "value": "uus väärtus",
  "description": "Uus kirjeldus"
}
```

## Võimalikud Veateated

API võib tagastada järgmisi HTTP staatuskoode:

- **200 OK**: Päring õnnestus
- **400 Bad Request**: Vigased sisendandmed
- **404 Not Found**: Ressurssi ei leitud
- **500 Internal Server Error**: Serveri viga

Veateadete puhul tagastatakse täpsem info JSON formaadis:

```json
{
  "detail": "Veateade koos täpsema infoga"
}
```