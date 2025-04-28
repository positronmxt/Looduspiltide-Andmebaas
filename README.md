# Looduspiltide Andmebaas

Looduspiltide Andmebaas on tööriist looduspiltide kogumiseks, katalogiseerimiseks ning sirvimiseks. Rakendus sisaldab kuufiltritega otsingusüsteemi, mis võimaldab fotosid leida nende tegemise ajaperioodi järgi.

## Projekti ülevaade

Rakendus koosneb kolmest peamisest komponendist:
- **Backend**: FastAPI-l põhinev serverrakendus, mis haldab andmebaasi ja pakub API-t
- **Frontend**: React-põhine kasutajaliides piltide sirvimiseks ja haldamiseks
- **Andmebaas**: SQLite andmebaas, mis säilitab metaandmed piltide ja liikide kohta

## Funktsionaalsus

- Looduspiltide üleslaadimine ja säilitamine
- Kuufiltritega detailne otsing
- Piltide kategoriseerimine liikide järgi
- Metaandmete automaatne lugemine EXIF andmetest
- Kasutajasõbralik veebiliides piltide sirvimiseks

## Tehnoloogiad

- **Backend**: Python, FastAPI, SQLAlchemy
- **Frontend**: JavaScript, React
- **Andmebaas**: SQLite
- **Andmemudelid**: Pydantic

## Paigaldamine

### Eeldused
- Python 3.11+
- Node.js ja npm
- Git

### Backend'i käivitamine
```bash
cd backend
pip install -r requirements.txt
python main.py
```

### Frontend'i käivitamine
```bash
cd frontend
npm install
npm start
```

### Mõlemad serverid korraga käivitamine
```bash
./start_servers.sh
```

## Projekti struktuur

```
backend/
  ├── main.py                  # Peamine API rakendus
  ├── database.py              # Andmebaasi konfiguratsioon
  ├── models/                  # Andmemudelid
  │   ├── base_models.py       # Baasmudelid
  │   ├── photo_models.py      # Foto mudelid
  │   ├── relation_models.py   # Seosemudelid
  │   └── species_models.py    # Liikide mudelid
  ├── routers/                 # API marsruuterid
  └── services/                # Äriloogika teenused

frontend/
  ├── public/                  # Staatilised failid
  └── src/                     # React komponendid ja loogika
      └── components/          # UI komponendid

file_storage/                  # Piltide salvestuskoht
database/                      # Andmebaasi failid
```

## Kuufiltritega otsing

Rakenduse peamine omadus on kuufiltritega otsingusüsteem, mis võimaldab kasutajatel leida fotosid konkreetsete kuude järgi. See on eriti kasulik loodusvaatluste puhul, kus aastaaja järgi otsing annab olulist informatsiooni.

## Arendamine

Projekti arendamiseks:
1. Kloonige repositoorium
2. Seadistage arenduskeskkond
3. Tehke oma muudatused
4. Esitage pull request

## Litsents

[MIT](https://choosealicense.com/licenses/mit/)