#!/bin/bash

# Projekti absoluutne juurkaust - OLULINE: See tagab töötamise mistahes kataloogist
PROJECT_DIR="/home/gerri/Dokumendid/progemine/nature-photo-db"

# Dünaamiline tuvastus juhuks, kui fikseeritud tee ei toimi
if [ ! -d "$PROJECT_DIR" ]; then
    # Proovi tuvastada projekti kataloog skripti asukoha järgi
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    if [ -d "$SCRIPT_DIR/backend" ] && [ -d "$SCRIPT_DIR/frontend" ]; then
        echo "Kasutan projekti kataloogina skripti kataloogi: $SCRIPT_DIR"
        PROJECT_DIR="$SCRIPT_DIR"
    else
        echo "HOIATUS: Ei suutnud tuvastada projekti kataloogi automaatselt."
        echo "Proovime kasutada praegust kataloogi."
        CURRENT_PWD="$(pwd)"
        if [ -d "$CURRENT_PWD/backend" ] && [ -d "$CURRENT_PWD/frontend" ]; then
            echo "Leiti backend ja frontend kaustad praeguses kataloogis."
            PROJECT_DIR="$CURRENT_PWD"
        fi
    fi
fi

BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
# Kontrolli, kas virtuaalkeskkond on backend kataloogis (uus versioon) või projekti juurkataloogis (vana versioon)
if [ -d "$BACKEND_DIR/venv" ]; then
    VENV_DIR="$BACKEND_DIR/venv"
    echo "Kasutan backend kataloogis olevat virtuaalkeskkonda."
else
    VENV_DIR="$PROJECT_DIR/venv"
    echo "Kasutan projekti juurkataloogis olevat virtuaalkeskkonda."
fi

# Kontrolli, kas skript käivitati õigest kataloogist, kui mitte, siis liigu sinna
CURRENT_DIR="$(pwd)"
if [ "$CURRENT_DIR" != "$PROJECT_DIR" ]; then
    echo "Skript ei käivitatud projekti juurkataloogist. Liigume automaatselt: $PROJECT_DIR"
    cd "$PROJECT_DIR"
    if [ $? -ne 0 ]; then
        echo "Ei õnnestunud liikuda kataloogi $PROJECT_DIR. Palun käivitage skript käsuga:"
        echo "cd $PROJECT_DIR && ./start_servers.sh"
        exit 1
    fi
fi

# Värvid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Looduslike piltide andmebaasi käivitamine ===${NC}"

# Kontrolli, kas virtuaalkeskkond on olemas
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Virtuaalkeskkonda ei leitud. Loon uue virtuaalkeskkonna...${NC}"
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Virtuaalkeskkonna loomine ebaõnnestus. Kontrolli, kas python3-venv on installitud.${NC}"
        exit 1
    fi
fi

# Aktiveeri virtuaalkeskkond
echo -e "${BLUE}Aktiveerin virtuaalkeskkonna...${NC}"
source "$VENV_DIR/bin/activate"

echo -e "${BLUE}Kontrollin ja installin backend Python sõltuvused...${NC}"
if [ -f "$BACKEND_DIR/requirements.txt" ]; then
        pip install -r "$BACKEND_DIR/requirements.txt"
else
        echo -e "${YELLOW}Hoiatus: requirements.txt puudub. Jätkan olemasolevate pakettidega.${NC}"
fi

# Abifunktsioon: oota kuni port on kuulatavas olekus
wait_for_port() {
    local host=$1
    local port=$2
    local retries=${3:-60}
    local delay=${4:-1}
    echo -e "${YELLOW}Ootan, kuni ${host}:${port} on saadaval (max ${retries}s)...${NC}"
    for i in $(seq 1 $retries); do
        if (echo >/dev/tcp/${host}/${port}) &>/dev/null; then
            echo -e "${GREEN}${host}:${port} on saadaval.${NC}"
            return 0
        fi
        sleep "$delay"
    done
    return 1
}

# Käivita Postgres konteiner docker-compose abil (database/docker-compose.yml)
echo -e "${BLUE}Käivitan PostgreSQL andmebaasi (docker-compose)...${NC}"
DOCKER_COMPOSE_CMD=""
if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
fi

if [ -n "$DOCKER_COMPOSE_CMD" ] && [ -f "$PROJECT_DIR/database/docker-compose.yml" ]; then
    pushd "$PROJECT_DIR/database" >/dev/null
    $DOCKER_COMPOSE_CMD up -d
    compose_status=$?
    popd >/dev/null
    if [ $compose_status -ne 0 ]; then
        echo -e "${RED}PostgreSQL konteineri käivitamine ebaõnnestus. Jätkan, kuid skeemi uuendus võib feilib.${NC}"
    fi
else
    echo -e "${YELLOW}Docker Compose ei ole saadaval või docker-compose.yml puudub. Eeldan, et Postgres töötab lokaalselt pordil 5433.${NC}"
fi

# Oota kuni andmebaasi port 5433 on saadaval
if ! wait_for_port localhost 5433 60 1; then
    echo -e "${RED}Andmebaasi port 5433 ei avanenud ooteaja jooksul. Kontrolli, et Postgres töötab.${NC}"
    exit 1
fi

# Kui docker compose on kasutusel, kasuta pg_isready valmisoleku kontrolliks
if [ -n "$DOCKER_COMPOSE_CMD" ]; then
    echo -e "${YELLOW}Kontrollin konteineris pg_isready abil valmisolekut...${NC}"
    for i in {1..30}; do
        $DOCKER_COMPOSE_CMD -f "$PROJECT_DIR/database/docker-compose.yml" exec -T postgres pg_isready -h 127.0.0.1 -p 5432 -U nature_user >/dev/null 2>&1 && break
        sleep 1
        if [ $i -eq 30 ]; then
            echo -e "${RED}pg_isready ei kinnitanud valmisolekut. Jätkan siiski skeemi uuendusega.${NC}"
        fi
    done
fi

# Uuenda andmebaasi skeemi (nüüd, kui DB on üleval)
echo -e "${BLUE}Uuendan andmebaasi skeemi...${NC}"
cd "$BACKEND_DIR"
# Proovi skeemi uuendust kuni 5 korda, vahedega
tries=0
until python3 update_schema.py; do
    tries=$((tries+1))
    if [ $tries -ge 5 ]; then
        break
    fi
    echo -e "${YELLOW}Skeemi uuendus feilis, proovin uuesti (${tries}/5) 2s pärast...${NC}"
    sleep 2
done
if [ $? -ne 0 ]; then
    echo -e "${RED}Andmebaasi skeemi uuendamine ebaõnnestus. Kontrolli logifaile.${NC}"
    exit 1
else
    echo -e "${GREEN}Andmebaasi skeem on edukalt uuendatud!${NC}"
fi

# Kontrolli, kas port 8001 on juba kasutusel
function check_port() {
    local port=$1
    local process_info=$(lsof -i:$port -sTCP:LISTEN -t 2>/dev/null)
    if [ -n "$process_info" ]; then
        echo "$process_info"
        return 0
    else
        return 1
    fi
}

# Käivita backend server
function start_backend() {
    echo -e "${BLUE}Käivitan backend serveri...${NC}"
    cd "$BACKEND_DIR"
    
    # Alusta backend serverit taustal ja suuna väljund logifaili
    nohup python3 main.py > "$BACKEND_DIR/server.log" 2>&1 &
    backend_pid=$!
    
    # Oota, et server käivituks
    echo -e "${YELLOW}Ootan backend serveri käivitumist...${NC}"
    sleep 3
    
    # Kontrolli, kas server käivitus edukalt
    if ps -p $backend_pid > /dev/null; then
        echo -e "${GREEN}Backend server käivitatud edukalt (PID: $backend_pid)${NC}"
        echo -e "${GREEN}Backend server on kättesaadav aadressil: http://localhost:8001${NC}"
        echo -e "${BLUE}Backend logi: $BACKEND_DIR/server.log${NC}"
    else
        echo -e "${RED}Backend serveri käivitamine ebaõnnestus. Vaata logifaili: $BACKEND_DIR/server.log${NC}"
        cat "$BACKEND_DIR/server.log"
        exit 1
    fi
}

# Käivita frontend server
function start_frontend() {
    echo -e "${BLUE}Käivitan frontend serveri...${NC}"
    cd "$FRONTEND_DIR"
    
    # Kontrolli, kas Reacti sõltuvused on installitud
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installin frontend sõltuvused...${NC}"
        npm install
    fi
    
    # Alusta frontend serverit taustal ja suuna väljund logifaili
    nohup npm start > "$FRONTEND_DIR/server.log" 2>&1 &
    frontend_pid=$!
    
    # Oota, et server käivituks
    echo -e "${YELLOW}Ootan frontend serveri käivitumist...${NC}"
    sleep 5
    
    # Kontrolli, kas server käivitus edukalt
    if ps -p $frontend_pid > /dev/null; then
        echo -e "${GREEN}Frontend server käivitatud edukalt (PID: $frontend_pid)${NC}"
        echo -e "${GREEN}Frontend on tõenäoliselt kättesaadav aadressil: http://localhost:3000 või http://localhost:3001${NC}"
        echo -e "${BLUE}Frontend logi: $FRONTEND_DIR/server.log${NC}"
    else
        echo -e "${RED}Frontend serveri käivitamine ebaõnnestus. Vaata logifaili: $FRONTEND_DIR/server.log${NC}"
        cat "$FRONTEND_DIR/server.log"
        exit 1
    fi
}

# Kontrolli, kas backend server on juba käivitatud
backend_pid=$(check_port 8001)
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}Backend server on juba käivitatud (PID: $backend_pid)${NC}"
else
    start_backend
fi

# Kontrolli, kas frontend server on juba käivitatud (kas port 3000 või 3001)
frontend_pid=$(check_port 3000)
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}Frontend server on juba käivitatud pordil 3000 (PID: $frontend_pid)${NC}"
else
    frontend_pid=$(check_port 3001)
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Frontend server on juba käivitatud pordil 3001 (PID: $frontend_pid)${NC}"
    else
        start_frontend
    fi
fi

echo -e "${GREEN}Kõik serverid on käivitatud!${NC}"
echo -e "${BLUE}Rakenduste aadressid:${NC}"
echo -e "${GREEN}Backend API: http://localhost:8001${NC}"
echo -e "${GREEN}Frontend: http://localhost:3000 või http://localhost:3001${NC}"
echo -e "${YELLOW}Serverite peatamiseks kasuta 'pkill -f \"python3 main.py\"' ja 'pkill -f \"node.*react-scripts start\"'${NC}"