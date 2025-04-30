# Looduspiltide Andmebaasi Paigaldusjuhend

See juhend kirjeldab, kuidas paigaldada ja seadistada Looduspiltide Andmebaas süsteemi erinevatel operatsioonisüsteemidel.

## Süsteeminõuded

- Python 3.11 või uuem
- Node.js 16.x või uuem
- NPM 8.x või uuem
- PostgreSQL 13.x või uuem (soovituslik) või SQLite3 (arenduses)
- Vähemalt 2GB vaba kettaruumi piltide salvestamiseks
- Git

## Üldine paigaldamise protsess

Kõigi operatsioonisüsteemide puhul on paigaldamise üldine protsess järgmine:

1. Lae alla lähtekood GitHubist
2. Seadista andmebaas (PostgreSQL või SQLite)
3. Paigalda ja seadista backend
4. Paigalda ja seadista frontend
5. Käivita rakendus

## Paigaldamine Linuxis

### 1. Eeltingimused

Paigalda vajalikud paketid:

```bash
# Debian/Ubuntu süsteemides
sudo apt update
sudo apt install python3 python3-pip python3-venv nodejs npm git postgresql postgresql-contrib libpq-dev

# Fedora/RHEL süsteemides
sudo dnf install python3 python3-pip nodejs npm git postgresql-server postgresql-contrib libpq-devel
sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Lae alla lähtekood

```bash
git clone https://github.com/sinu-kasutaja/nature-photo-db.git
cd nature-photo-db
```

### 3. PostgreSQL seadistamine (soovituslik)

```bash
# PostgreSQL teenuse käivitamine (kui see pole juba käivitatud)
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Kasutaja ja andmebaasi loomine
sudo -u postgres psql -c "CREATE USER nature_user WITH PASSWORD 'valige_turvaline_parool';"
sudo -u postgres psql -c "CREATE DATABASE nature_photo_db OWNER nature_user;"
sudo -u postgres psql -c "ALTER USER nature_user WITH SUPERUSER;"

# Muuda PostgreSQL kasutama teist porti (vajadusel, vaikimisi 5432)
sudo nano /etc/postgresql/$(pg_config --version | cut -d' ' -f2 | cut -d'.' -f1)/main/postgresql.conf
# Muutke rida "port = 5432" -> "port = 5433"

# Taaskäivita PostgreSQL
sudo systemctl restart postgresql
```

### 4. Backendi seadistamine

```bash
# Virtuaalkeskkonna loomine ja aktiveerimine
python3 -m venv venv
source venv/bin/activate

# Sõltuvuste paigaldamine
cd backend
pip install -r requirements.txt

# Keskkonna muutujate seadistamine
cat > .env << EOF
DATABASE_URL=postgresql://nature_user:valige_turvaline_parool@localhost:5433/nature_photo_db
# Arendustöö jaoks võite kasutada ka SQLite
# DATABASE_URL=sqlite:///./database/photos.db
FILE_STORAGE_PATH=../file_storage
DEBUG=True
EOF

# Andmebaasi tabelite loomine
python create_tables.py
```

### 5. Frontendi seadistamine

```bash
cd ../frontend
npm install

# Keskkonna muutujate seadistamine
cat > .env << EOF
REACT_APP_API_URL=http://localhost:8001
EOF
```

### 6. Käivitamine arendusrežiimis

Backendi käivitamine:

```bash
cd backend
source ../venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8001
```

Frontendi käivitamine (uues terminaliaknas):

```bash
cd frontend
npm start
```

Rakendusele pääseb juurde aadressil: http://localhost:3000

### 7. Käivitamine skriptiga

Projektiga on kaasas skript, mis käivitab nii backendi kui frontendi:

```bash
chmod +x start_servers.sh
./start_servers.sh
```

## Paigaldamine Windowsil

### 1. Eeltingimused

1. **Paigalda Python 3.11+**:
   - Laadi alla Python paigaldaja aadressilt: https://www.python.org/downloads/windows/
   - Käivita paigaldaja ja märgi kindlasti "Add Python to PATH"

2. **Paigalda Node.js ja npm**:
   - Laadi alla Node.js paigaldaja aadressilt: https://nodejs.org/
   - Käivita paigaldaja ja järgi juhiseid

3. **Paigalda Git**:
   - Laadi alla Git paigaldaja aadressilt: https://git-scm.com/download/win
   - Käivita paigaldaja, vali "Git from the command line and also from 3rd-party software"

4. **Paigalda PostgreSQL** (soovituslik):
   - Laadi alla PostgreSQL paigaldaja aadressilt: https://www.postgresql.org/download/windows/
   - Käivita paigaldaja
   - Määra paigaldamisel järgmised parameetrid:
     - Kasutajanimi: `nature_user`
     - Parool: `valige_turvaline_parool`
     - Port: `5433`

### 2. Lae alla lähtekood

Ava käsurida (cmd või PowerShell) ja sisesta:

```cmd
git clone https://github.com/sinu-kasutaja/nature-photo-db.git
cd nature-photo-db
```

### 3. PostgreSQL andmebaasi loomine

Ava PostgreSQL käsurida (SQL Shell psql) ja sisesta:

```sql
CREATE DATABASE nature_photo_db;
```

### 4. Backendi seadistamine

```cmd
:: Virtuaalkeskkonna loomine ja aktiveerimine
python -m venv venv
venv\Scripts\activate

:: Sõltuvuste paigaldamine
cd backend
pip install -r requirements.txt

:: Keskkonna muutujate seadistamine
echo DATABASE_URL=postgresql://nature_user:valige_turvaline_parool@localhost:5433/nature_photo_db > .env
echo FILE_STORAGE_PATH=..\file_storage >> .env
echo DEBUG=True >> .env

:: Andmebaasi tabelite loomine
python create_tables.py
```

### 5. Frontendi seadistamine

```cmd
cd ..\frontend
npm install

:: Keskkonna muutujate seadistamine
echo REACT_APP_API_URL=http://localhost:8001 > .env
```

### 6. Käivitamine arendusrežiimis

Backendi käivitamine:

```cmd
cd backend
..\venv\Scripts\activate
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8001
```

Frontendi käivitamine (uues cmd või PowerShell aknas):

```cmd
cd frontend
npm start
```

Rakendusele pääseb juurde aadressil: http://localhost:3000

### 7. Käivitamine skriptiga

Looge faili `start_servers.bat` projekti juurkataloogi järgmise sisuga:

```batch
@echo off
:: Backendi käivitamine
start cmd /k "cd backend && ..\venv\Scripts\activate && python -m uvicorn main:app --reload --host 0.0.0.0 --port 8001"
:: Frontendi käivitamine
start cmd /k "cd frontend && npm start"
echo Serverid käivitatud! Ava brauser aadressil http://localhost:3000
```

Käivitage see skript topeltklõpsuga või käsurealt:

```cmd
start_servers.bat
```

## Paigaldamine macOS-il

### 1. Eeltingimused

1. **Paigalda Homebrew** (kui pole veel paigaldatud):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Paigalda vajalikud paketid**:
   ```bash
   brew update
   brew install python@3.11 node git postgresql
   ```

3. **Käivita PostgreSQL**:
   ```bash
   brew services start postgresql
   ```

### 2. Lae alla lähtekood

```bash
git clone https://github.com/sinu-kasutaja/nature-photo-db.git
cd nature-photo-db
```

### 3. PostgreSQL seadistamine

```bash
# Kasutaja ja andmebaasi loomine
psql postgres -c "CREATE USER nature_user WITH PASSWORD 'valige_turvaline_parool';"
psql postgres -c "CREATE DATABASE nature_photo_db OWNER nature_user;"
psql postgres -c "ALTER USER nature_user WITH SUPERUSER;"
```

### 4. Backendi seadistamine

```bash
# Virtuaalkeskkonna loomine ja aktiveerimine
python3 -m venv venv
source venv/bin/activate

# Sõltuvuste paigaldamine
cd backend
pip install -r requirements.txt

# Keskkonna muutujate seadistamine
cat > .env << EOF
DATABASE_URL=postgresql://nature_user:valige_turvaline_parool@localhost:5432/nature_photo_db
FILE_STORAGE_PATH=../file_storage
DEBUG=True
EOF

# Andmebaasi tabelite loomine
python create_tables.py
```

### 5. Frontendi seadistamine

```bash
cd ../frontend
npm install

# Keskkonna muutujate seadistamine
cat > .env << EOF
REACT_APP_API_URL=http://localhost:8001
EOF
```

### 6. Käivitamine arendusrežiimis

Backendi käivitamine:

```bash
cd backend
source ../venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8001
```

Frontendi käivitamine (uues terminaliaknas):

```bash
cd frontend
npm start
```

Rakendusele pääseb juurde aadressil: http://localhost:3000

### 7. Käivitamine skriptiga

Looge fail nimega `start_servers_mac.sh` projekti juurkataloogi:

```bash
#!/bin/bash
# Backendi käivitamine
osascript -e 'tell app "Terminal" to do script "cd '$(pwd)'/backend && source ../venv/bin/activate && uvicorn main:app --reload --host 0.0.0.0 --port 8001"'
# Frontendi käivitamine
osascript -e 'tell app "Terminal" to do script "cd '$(pwd)'/frontend && npm start"'
echo "Serverid käivitatud! Ava brauser aadressil http://localhost:3000"
```

Muutke see fail käivitatavaks ja käivitage see:

```bash
chmod +x start_servers_mac.sh
./start_servers_mac.sh
```

## Käivitamine tootmisrežiimis

### 1. Frontendi kompileerimine

```bash
cd frontend
npm run build
```

### 2. Backendi tootmisrežiimis käivitamine

#### Linux/macOS

Looge systemd teenuse fail (ainult Linux):

```bash
sudo tee /etc/systemd/system/nature-photo-db.service << EOF
[Unit]
Description=Nature Photo Database Backend
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$(pwd)/backend
ExecStart=$(pwd)/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8001
Restart=on-failure
Environment="DATABASE_URL=postgresql://nature_user:valige_turvaline_parool@localhost:5432/nature_photo_db"
Environment="FILE_STORAGE_PATH=$(pwd)/file_storage"
Environment="DEBUG=False"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable nature-photo-db
sudo systemctl start nature-photo-db
```

#### Windows

Looge Windows teenus (kasutades nssm - Non-Sucking Service Manager):

1. Laadige alla nssm: https://nssm.cc/download
2. Pakkige lahti ja liigutage nssm.exe süsteemi PATH-ile
3. Installige teenus:

```cmd
nssm install NaturePhotoDB "%CD%\venv\Scripts\uvicorn.exe" "main:app --host 0.0.0.0 --port 8001"
nssm set NaturePhotoDB AppDirectory "%CD%\backend"
nssm set NaturePhotoDB AppEnvironmentExtra "DATABASE_URL=postgresql://nature_user:valige_turvaline_parool@localhost:5433/nature_photo_db" "FILE_STORAGE_PATH=%CD%\file_storage" "DEBUG=False"
nssm start NaturePhotoDB
```

### 3. Frontendi ja staatiliste failide serveerimine

#### Nginx (Linux/macOS)

Installige Nginx:

```bash
# Ubuntu/Debian
sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx

# macOS
brew install nginx
```

Looge Nginx konfiguratsioonifail:

```bash
sudo tee /etc/nginx/sites-available/nature-photo-db << EOF
server {
    listen 80;
    server_name _;  # Asendage oma domeeniga tootmiskeskkonnas

    location / {
        root $(pwd)/frontend/build;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /file_storage/ {
        alias $(pwd)/file_storage/;
    }
}
EOF

# Lubame konfiguratsiooni
sudo ln -s /etc/nginx/sites-available/nature-photo-db /etc/nginx/sites-enabled/
sudo nginx -t  # Kontrolli konfiguratsiooni
sudo systemctl restart nginx
```

#### Apache (Windows)

Paigaldage Apache (XAMPP kaudu): https://www.apachefriends.org/index.html

Looge virtuaalserveri konfiguratsioon (httpd-vhosts.conf):

```
<VirtualHost *:80>
    DocumentRoot "C:/xampp/htdocs/nature-photo-db/frontend/build"
    ServerName looduspildid.lokaalne
    
    <Directory "C:/xampp/htdocs/nature-photo-db/frontend/build">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ProxyPass /api/ http://localhost:8001/
    ProxyPassReverse /api/ http://localhost:8001/
    
    Alias /file_storage/ "C:/xampp/htdocs/nature-photo-db/file_storage/"
    <Directory "C:/xampp/htdocs/nature-photo-db/file_storage">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

## Plant.ID API võtme seadistamine

Taimeliikide tuvastamiseks vajate [Plant.ID](https://web.plant.id/) API võtit:

1. Looge konto Plant.ID veebilehel
2. Genereerige API võti
3. Lisage see võti rakenduse seadistustesse:
   - Failis `.env` (arenduskeskkonnas):
     ```
     PLANT_ID_API_KEY=teie_api_võti_siia
     ```
   - Või andmebaasis (rakenduse käivitamise järel):
     - Navigeerige rakenduses "Seadistused" lehele
     - Lisage uus seadistus võtmega "PLANT_ID_API_KEY" ja väärtusega teie API võti

## Andmebaasi varundamine ja taastamine

### PostgreSQL varundamine

```bash
# Linux/macOS
pg_dump -U nature_user -h localhost -p 5432 nature_photo_db > nature_photo_db_backup.sql

# Windows
"C:\Program Files\PostgreSQL\13\bin\pg_dump.exe" -U nature_user -h localhost -p 5433 nature_photo_db > nature_photo_db_backup.sql
```

### PostgreSQL taastamine

```bash
# Linux/macOS
psql -U nature_user -h localhost -p 5432 nature_photo_db < nature_photo_db_backup.sql

# Windows
"C:\Program Files\PostgreSQL\13\bin\psql.exe" -U nature_user -h localhost -p 5433 nature_photo_db < nature_photo_db_backup.sql
```

## Tõrkeotsing

### Levinud probleemid

1. **Veateade "Port 8001 is already in use":**
   - Kontrolli, et ükski teine protsess ei kasuta seda porti:
     ```bash
     # Linux/macOS
     sudo lsof -i :8001
     # Kui leidub protsess, lõpeta see:
     sudo kill -9 [PID]
     
     # Windows
     netstat -ano | findstr :8001
     # Kui leidub protsess, lõpeta see:
     taskkill /F /PID [PID]
     ```

2. **Piltide üleslaadimine ebaõnnestub:**
   - Kontrolli, et `file_storage` kaust oleks olemas ja kirjutatav:
     ```bash
     # Linux/macOS
     mkdir -p file_storage
     chmod -R 755 file_storage
     
     # Windows
     if not exist file_storage mkdir file_storage
     ```

3. **Taimetuvastus ebaõnnestub:**
   - Kontrolli, et Plant.ID API võti on õigesti sisestatud
   - Kontrolli internetiühendust
   - Vaata rakenduse logifaile:
     ```bash
     # Linux/macOS
     tail -n 100 backend/logs/backend.log
     
     # Windows
     type backend\logs\backend.log
     ```

4. **SQLAlchemy andmebaasi ühenduse vead:**
   - Kontrolli, et andmebaasi server töötab:
     ```bash
     # Linux/macOS
     sudo systemctl status postgresql
     
     # Windows (PowerShell)
     Get-Service -Name postgresql*
     ```
   - Kontrolli andmebaasi kasutaja ja parool
   - Kontrolli andmebaasi URL-i formaati `.env` failis

5. **Frontend ei saa ühendust backend API-ga:**
   - Kontrolli, et backend server töötab
   - Kontrolli, et API URL on korrektne `.env` failis
   - Kontrolli, kas CORS on korrektselt seadistatud backendis

## Täiendav abi

Kui vajate täiendavat abi, saate:
- Vaadata rakenduse logifaile (`backend/logs/backend.log` ja `frontend/logs/frontend.log`)
- Kontrollida API dokumentatsiooni, mis on saadaval aadressil `http://localhost:8001/docs`
- Uurida rakenduse lähtekoodi GitHubis
- Avada probleemide raporteerimiseks uue teema (Issue) GitHub repositooriumis