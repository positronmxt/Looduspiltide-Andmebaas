#!/bin/bash
# dev_setup.sh - Arenduskeskkonna seadistamine Docker-PostgreSQL jaoks

echo "Seadistan arenduskeskkonda Docker-PostgreSQL jaoks..."

# Kontrolli, kas docker-compose on installitud
if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose ei ole installitud. Palun installige see enne jätkamist."
    exit 1
fi

# Kontrolli, kas Docker daemon töötab
if ! docker info &> /dev/null; then
    echo "Docker daemon ei tööta. Palun käivitage see enne jätkamist."
    echo "Tavaliselt: sudo systemctl start docker"
    exit 1
fi

# Käivita PostgreSQL Docker konteiner, kui see pole juba käivitatud
echo "Kontrollin Docker PostgreSQL konteineri olemasolu..."
if ! docker ps | grep -q nature_photo_db_postgres; then
    echo "PostgreSQL Docker konteiner ei tööta. Käivitan..."
    cd database
    docker-compose up -d
    cd ..
    
    # Oota, kuni PostgreSQL on käivitunud
    echo "Ootan, kuni PostgreSQL on käivitunud..."
    sleep 5
    
    # Kontrolli, kas konteiner on nüüd käivitatud
    if ! docker ps | grep -q nature_photo_db_postgres; then
        echo "PostgreSQL Docker konteineri käivitamine ebaõnnestus."
        exit 1
    fi
fi

echo "PostgreSQL Docker konteiner on käivitatud."

# Loo .env fail arenduskeskkonna seadistustega
echo "Loon .env faili arenduskeskkonna seadistustega..."
cat > backend/.env << EOL
# Arenduskeskkonna seadistused
DB_USER=nature_user
DB_PASSWORD=securepassword
DB_HOST=localhost
DB_PORT=5433
DB_NAME=nature_photo_db
ENVIRONMENT=development
DEBUG=true
EOL

# Loo eraldi keskkondade konfiguratsioonifailid
echo "Loon eraldi konfiguratsioonifailid erinevate keskkondade jaoks..."
cat > backend/.env.development << EOL
DB_USER=nature_user
DB_PASSWORD=securepassword
DB_HOST=localhost
DB_PORT=5433
DB_NAME=nature_photo_db
ENVIRONMENT=development
DEBUG=true
API_KEY_STORAGE=file
API_KEY_FILE=.dev_api_keys.json
EOL

cat > backend/.env.testing << EOL
DB_USER=nature_user
DB_PASSWORD=securepassword
DB_HOST=localhost
DB_PORT=5433
DB_NAME=nature_photo_db
ENVIRONMENT=testing
DEBUG=true
API_KEY_STORAGE=memory
EOL

# Kontrolli Pythoni keskkonda ja too virtuaalkeskkond ajakohaseks
if [ ! -d "backend/venv" ]; then
    echo "Loon Pythoni virtuaalkeskkonna..."
    cd backend
    python3 -m venv venv
    cd ..
fi

# Aktiveeri virtuaalkeskkond ja uuenda sõltuvused
echo "Uuendan Pythoni sõltuvusi..."
cd backend
source venv/bin/activate
pip install -r requirements.txt
python -c "
try:
    import dotenv
    print('python-dotenv on installitud')
except ImportError:
    print('Installin python-dotenv...')
    import pip
    pip.main(['install', 'python-dotenv'])
"
cd ..

echo "Arenduskeskkond on seadistatud Docker-PostgreSQL jaoks!"