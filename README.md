# Looduspiltide Andmebaas

Looduspiltide Andmebaas on tööriist looduspiltide kogumiseks, katalogiseerimiseks ning sirvimiseks. Rakendus sisaldab kuufiltritega otsingusüsteemi, mis võimaldab fotosid leida nende tegemise ajaperioodi järgi.

## Projekti ülevaade

Rakendus koosneb kolmest peamisest komponendist:
- **Backend**: FastAPI-l põhinev serverrakendus, mis haldab andmebaasi ja pakub API-t
- **Frontend**: React-põhine kasutajaliides piltide sirvimiseks ja haldamiseks
- **Andmebaas**: PostgreSQL andmebaas, mis säilitab metaandmed piltide ja liikide kohta

## Funktsionaalsus

- Looduspiltide üleslaadimine ja säilitamine
- Kuufiltritega detailne otsing
- Piltide kategoriseerimine liikide järgi
- Metaandmete automaatne lugemine EXIF andmetest
- Kasutajasõbralik veebiliides piltide sirvimiseks

## Tehnoloogiad

- **Backend**: Python, FastAPI, SQLAlchemy
- **Frontend**: JavaScript, React
- **Andmebaas**: PostgreSQL
- **Andmemudelid**: Pydantic

## Paigaldamine

### Eeldused
- Python 3.11+
- Node.js ja npm
- Git
- PostgreSQL (Linux või Windows)

### Linux keskkonna ettevalmistamine
1. **Vajalike pakkide paigaldamine**:
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip python3-venv nodejs npm git postgresql postgresql-contrib
   ```

2. **PostgreSQL seadistamine Linuxil**:
   ```bash
   # PostgreSQL teenuse käivitamine
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   
   # Kasutaja ja andmebaasi loomine
   sudo -u postgres psql -c "CREATE USER nature_user WITH PASSWORD 'securepassword';"
   sudo -u postgres psql -c "CREATE DATABASE nature_photo_db OWNER nature_user;"
   sudo -u postgres psql -c "ALTER USER nature_user WITH SUPERUSER;"
   
   # PostgreSQL pordiseadistus (vaikimisi 5432 -> projekti jaoks 5433)
   sudo nano /etc/postgresql/$(pg_config --version | cut -d' ' -f2 | cut -d'.' -f1)/main/postgresql.conf
   # Muutke rida "port = 5432" -> "port = 5433"
   
   # Taaskäivitage PostgreSQL uue pordiseadistusega
   sudo systemctl restart postgresql
   ```

### Projekti kloonimine ja käivitamine Linuxil

1. **Projekti kloonimine**:
   ```bash
   git clone https://github.com/positronmxt/Looduspiltide-Andmebaas.git
   cd Looduspiltide-Andmebaas
   ```

2. **Backend'i käivitamine Linuxil**:
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python main.py
   ```

3. **Frontend'i käivitamine Linuxil** (avage uus terminaliaken):
   ```bash
   cd frontend
   npm install
   npm start
   ```

4. **Mõlemad serverid korraga käivitamine Linuxil**:
   ```bash
   # See skript on juba projektis olemas
   chmod +x start_servers.sh
   ./start_servers.sh
   ```

### Windows keskkonna ettevalmistamine
1. **Python paigaldamine**:
   - Laadige alla ja installige Python 3.11+ [Python ametlikult veebilehelt](https://www.python.org/downloads/windows/)
   - Installimisel märkige kindlasti "Add Python to PATH"

2. **Node.js paigaldamine**:
   - Laadige alla ja installige Node.js [Node.js ametlikult veebilehelt](https://nodejs.org/)

3. **Git paigaldamine**:
   - Laadige alla ja installige Git [Git ametlikult veebilehelt](https://git-scm.com/download/win)
   - Valige installimisel "Git from the command line and also from 3rd-party software"

4. **PostgreSQL paigaldamine**:
   - Laadige alla ja installige PostgreSQL [PostgreSQL ametlikult veebilehelt](https://www.postgresql.org/download/windows/)
   - Installimisel määrake kasutajanimi 'nature_user', parool 'securepassword' ja port '5433'
   - Looge andmebaas nimega 'nature_photo_db'

### Projekti kloonimine ja käivitamine Windowsil

1. **Projekti kloonimine**:
   ```cmd
   git clone https://github.com/positronmxt/Looduspiltide-Andmebaas.git
   cd Looduspiltide-Andmebaas
   ```

2. **Backend'i käivitamine Windowsil**:
   ```cmd
   cd backend
   pip install -r requirements.txt
   python main.py
   ```

3. **Frontend'i käivitamine Windowsil** (avage uus käsureaaken):
   ```cmd
   cd frontend
   npm install
   npm start
   ```

4. **Mõlemad serverid korraga käivitamine Windowsil**:
   - Looge fail nimega `start_servers.bat` projekti juurkataloogi
   - Lisage sellele järgmine sisu:
   ```batch
   @echo off
   start cmd /k "cd backend && python main.py"
   start cmd /k "cd frontend && npm start"
   echo Mõlemad serverid on käivitatud!
   ```
   - Käivitage skript topeltklõpsuga või käsurealt käsuga `start_servers.bat`

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