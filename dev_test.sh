#!/bin/bash
# dev_test.sh - Arendusversiooni testimine Docker-PostgreSQL keskkonnaga

# Seadista keskkond
cd "$(dirname "$0")"

# Värvid konsoolile
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Arendusversiooni testimine Docker-PostgreSQL keskkonnaga${NC}"
echo "--------------------------------------------------------"

# Kontrolli Docker-PostgreSQL konteineri olekut
echo -e "${BLUE}Kontrollin Docker-PostgreSQL konteineri olekut...${NC}"
if ! docker ps | grep -q nature_photo_db_postgres; then
    echo -e "${YELLOW}PostgreSQL Docker konteiner ei tööta. Käivitan arenduskeskkonna seadistuse...${NC}"
    ./dev_setup.sh
    
    if ! docker ps | grep -q nature_photo_db_postgres; then
        echo -e "${RED}PostgreSQL Docker konteineri käivitamine ebaõnnestus. Palun kontrollige Docker teenust.${NC}"
        exit 1
    fi
fi

# Aktiveeri virtuaalkeskkond
echo -e "${BLUE}Aktiveerin Python virtuaalkeskkonna...${NC}"
if [ ! -d "backend/venv" ]; then
    echo -e "${YELLOW}Virtuaalkeskkond puudub! Käivitan esmalt seadistuse...${NC}"
    ./dev_setup.sh
fi

source backend/venv/bin/activate || {
    echo -e "${RED}Virtuaalkeskkonna aktiveerimine ebaõnnestus!${NC}"
    exit 1
}

# Kontrolli andmebaasi ühendust (Docker-PostgreSQL)
echo -e "${BLUE}Kontrollin andmebaasi ühendust Docker konteineriga...${NC}"
python3 -c "
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os
import sys

try:
    load_dotenv('backend/.env')
    DB_USER = os.getenv('DB_USER')
    DB_PASSWORD = os.getenv('DB_PASSWORD')
    DB_HOST = os.getenv('DB_HOST')
    DB_PORT = os.getenv('DB_PORT')
    DB_NAME = os.getenv('DB_NAME')

    url = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
    print(f'Testin ühendust: {DB_HOST}:{DB_PORT}/{DB_NAME}')

    engine = create_engine(url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1'))
        print('\033[92mAndmebaasi ühendus Dockeris toimib!\033[0m')
except Exception as e:
    print(f'\033[91mAndmebaasi ühenduse viga: {e}\033[0m')
    print('Proovi käivitada: ./dev_setup.sh')
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Soovitav on käivitada Docker-PostgreSQL uuesti.${NC}"
    read -p "Kas soovite taaskäivitada Docker-PostgreSQL konteineri? (j/e): " restart_docker
    if [[ "$restart_docker" == "j" ]]; then
        echo -e "${BLUE}Taaskäivitan Docker-PostgreSQL konteineri...${NC}"
        cd database
        docker-compose down
        docker-compose up -d
        cd ..
        echo -e "${GREEN}Docker-PostgreSQL konteiner taaskäivitatud.${NC}"
        sleep 5  # Anna aega käivituda
    else
        echo -e "${YELLOW}Andmebaasi probleemid võivad takistada rakenduse tööd.${NC}"
    fi
fi

# Loo tabelid, kui vaja
echo -e "${BLUE}Kontrollin andmebaasi tabeleid...${NC}"
cd backend
python create_tables.py || {
    echo -e "${RED}Andmebaasi tabelite loomine ebaõnnestus!${NC}"
    exit 1
}
cd ..

# Loo logikataloog, kui pole olemas
mkdir -p backend/logs
mkdir -p frontend/logs

# Kontrolli, kas serverid juba töötavad
backend_running=false
frontend_running=false

if pgrep -f "uvicorn main:app" > /dev/null; then
    echo -e "${YELLOW}Backend server juba töötab.${NC}"
    backend_running=true
fi

if pgrep -f "npm start" > /dev/null; then
    echo -e "${YELLOW}Frontend server juba töötab.${NC}"
    frontend_running=true
fi

# Käivita arendusserver taustal, kui veel ei tööta
if [ "$backend_running" = false ]; then
    echo -e "${BLUE}Käivitan backend serveri...${NC}"
    cd backend
    nohup uvicorn main:app --reload --host 0.0.0.0 --port 8000 > logs/backend.log 2>&1 &
    SERVER_PID=$!
    cd ..
    echo -e "${GREEN}Backend server käivitatud (PID: $SERVER_PID)${NC}"
else
    SERVER_PID=$(pgrep -f "uvicorn main:app" | head -1)
    echo -e "${GREEN}Backend server juba töötab (PID: $SERVER_PID)${NC}"
fi

# Anna aega serveril käivituda
sleep 2

# Testi API-d
echo -e "${BLUE}Testin API endpointe...${NC}"
curl -s http://localhost:8000/api/health 2>/dev/null | grep -q "ok" && 
    echo -e "${GREEN}API tervisekontroll: OK${NC}" || 
    echo -e "${RED}API tervisekontroll: VIGANE${NC}"

# Käivita frontend arendusrežiimis, kui veel ei tööta
if [ "$frontend_running" = false ]; then
    echo -e "${BLUE}Käivitan frontend serveri arendusrežiimis...${NC}"
    cd frontend
    nohup npm start > logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    cd ..
    echo -e "${GREEN}Frontend käivitatud (PID: $FRONTEND_PID)${NC}"
else
    FRONTEND_PID=$(pgrep -f "npm start" | head -1)
    echo -e "${GREEN}Frontend server juba töötab (PID: $FRONTEND_PID)${NC}"
fi

echo ""
echo -e "${GREEN}Arendusserverid on käivitatud:${NC}"
echo -e "- Backend: ${BLUE}http://localhost:8000${NC}"
echo -e "- Frontend: ${BLUE}http://localhost:3000${NC}"
echo -e "- PostgreSQL: ${BLUE}localhost:5433${NC} (Docker konteineris)"
echo ""
echo -e "${YELLOW}Logi vaatamiseks kasuta:${NC}"
echo "- Backend: tail -f backend/logs/backend.log"
echo "- Frontend: tail -f frontend/logs/frontend.log"
echo "- Docker: docker logs -f nature_photo_db_postgres"
echo ""
echo -e "${YELLOW}Serverite peatamiseks kasuta:${NC}"
echo "kill $SERVER_PID $FRONTEND_PID"
echo "docker-compose -f database/docker-compose.yml down  # PostgreSQL peatamiseks"
echo ""
echo -e "${GREEN}Arenduskeskkond on valmis kasutamiseks!${NC}"