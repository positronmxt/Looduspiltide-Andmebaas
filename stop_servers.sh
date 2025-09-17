#!/bin/bash

# Projekti absoluutne juurkaust (sama loogika mis start_servers.sh skriptis)
PROJECT_DIR="/home/gerri/Dokumendid/progemine/nature-photo-db"

if [ ! -d "$PROJECT_DIR" ]; then
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  if [ -d "$SCRIPT_DIR/backend" ] && [ -d "$SCRIPT_DIR/frontend" ]; then
    echo "Kasutan projekti kataloogina skripti kataloogi: $SCRIPT_DIR"
    PROJECT_DIR="$SCRIPT_DIR"
  else
    CURRENT_PWD="$(pwd)"
    if [ -d "$CURRENT_PWD/backend" ] && [ -d "$CURRENT_PWD/frontend" ]; then
      echo "Leiti backend ja frontend kaustad praeguses kataloogis."
      PROJECT_DIR="$CURRENT_PWD"
    else
      echo "Ei leia projekti kataloogi. Käivita skript projekti juurest."
      exit 1
    fi
  fi
fi

BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Värvid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Serverite peatamine (backend, frontend, andmebaas) ===${NC}"

# Abifunktsioon: leia kuulatava pordi protsessid
find_listen_pids() {
  local port=$1
  # tagasta ainult kuulavad protsessid (-sTCP:LISTEN)
  lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null || true
}

kill_pids() {
  local pids=("$@")
  if [ ${#pids[@]} -eq 0 ]; then
    return 0
  fi
  echo -e "${YELLOW}Saadan SIGTERM protsessidele: ${pids[*]}${NC}"
  kill "${pids[@]}" 2>/dev/null || true
  sleep 2
  # kontrolli, mis jäi alles
  local still=()
  for p in "${pids[@]}"; do
    if ps -p "$p" > /dev/null 2>&1; then
      still+=("$p")
    fi
  done
  if [ ${#still[@]} -gt 0 ]; then
    echo -e "${YELLOW}Sundpeatamine (SIGKILL) protsessidele: ${still[*]}${NC}"
    kill -9 "${still[@]}" 2>/dev/null || true
  fi
}

# 1) Peata frontend (port 3000 või 3001)
echo -e "${BLUE}Peatan frontend serveri...${NC}"
FE_PIDS=()
for p in 3000 3001; do
  mapfile -t found < <(find_listen_pids "$p")
  if [ ${#found[@]} -gt 0 ]; then
    echo -e "${YELLOW}Leidsin porti ${p} kuulavad protsessid: ${found[*]}${NC}"
    FE_PIDS+=("${found[@]}")
  fi
done
kill_pids "${FE_PIDS[@]}"
# Fallback muster (kui portide põhine ei leidnud)
pkill -f "node.*react-scripts start" 2>/dev/null && echo -e "${YELLOW}Peatasin frontendi pkill mustriga.${NC}" || true

# 2) Peata backend (port 8001)
echo -e "${BLUE}Peatan backend serveri...${NC}"
mapfile -t BE_PIDS < <(find_listen_pids 8001)
if [ ${#BE_PIDS[@]} -gt 0 ]; then
  echo -e "${YELLOW}Leidsin backend protsessid: ${BE_PIDS[*]}${NC}"
  kill_pids "${BE_PIDS[@]}"
fi
# Fallback muster
pkill -f "python3 main.py" 2>/dev/null && echo -e "${YELLOW}Peatasin backendi pkill mustriga.${NC}" || true

# 3) Peata Postgres konteiner (docker compose)
echo -e "${BLUE}Peatan PostgreSQL konteineri...${NC}"
DCMD=""
if command -v docker-compose >/dev/null 2>&1; then
  DCMD="docker-compose"
elif command -v docker >/dev/null 2>&1; then
  DCMD="docker compose"
fi

if [ -n "$DCMD" ] && [ -f "$PROJECT_DIR/database/docker-compose.yml" ]; then
  pushd "$PROJECT_DIR/database" >/dev/null
  $DCMD down >/dev/null 2>&1 && echo -e "${GREEN}PostgreSQL konteiner peatatud.${NC}" || echo -e "${YELLOW}Ei suutnud konteinerit peatada või ei tööta.${NC}"
  popd >/dev/null
else
  echo -e "${YELLOW}Docker Compose puudub või faili ei leitud; eeldan, et andmebaas ei jookse konteineris.${NC}"
fi

echo -e "${GREEN}Kõik peatamiskäsud on käivitatud.${NC}"
echo -e "${BLUE}Kontrolli pordid:${NC}"
echo -e "  - Backend 8001: (peaks olema tühi)"
echo -e "  - Frontend 3000/3001: (peaks olema tühi)"
echo -e "  - Postgres 5433: (peaks olla kinni, kui kasutasid konteinerit)"
