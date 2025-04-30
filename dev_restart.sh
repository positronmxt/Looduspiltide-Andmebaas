#!/bin/bash
# dev_restart.sh - Arenduskeskkonna serverite taaskäivitamise skript

# Värvid konsoolile
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Arenduskeskkonna serverite taaskäivitamine${NC}"
echo "---------------------------------------"

# Määra töökataloog
cd "$(dirname "$0")"
BASE_DIR=$(pwd)

# Funktsioon protsesside lõpetamiseks
kill_process() {
    local process_pattern=$1
    local process_name=$2
    
    echo -e "${YELLOW}Lõpetan $process_name protsessid...${NC}"
    
    # Laiendatud otsingumuster parem vastavus
    local pids=$(pgrep -f "$process_pattern" 2>/dev/null)
    if [ -n "$pids" ]; then
        echo -e "Leitud ${process_name} protsessid (PID: $pids), lõpetan need..."
        for pid in $pids; do
            echo -e "Lõpetan protsessi $pid..."
            kill $pid 2>/dev/null
            # Anname protsessile natuke aega korralikult lõpetada
            sleep 1
            # Kui protsess ikka veel töötab, siis lõpetame selle jõuga
            if ps -p $pid > /dev/null 2>&1; then
                echo -e "${YELLOW}Protsess $pid ei lõpetanud tööd, kasutan jõudu (kill -9)${NC}"
                kill -9 $pid 2>/dev/null
            fi
        done
        echo -e "${GREEN}${process_name} protsessid on lõpetatud.${NC}"
    else
        echo -e "${GREEN}Ühtegi töötavat ${process_name} protsessi ei leitud ${process_pattern} mustri järgi.${NC}"
    fi
}

# Funktsioon pordi järgi protsessi lõpetamiseks
kill_process_by_port() {
    local port=$1
    local process_name=$2
    
    echo -e "${YELLOW}Lõpetan $process_name protsessi pordil $port...${NC}"
    
    # Leia protsess, mis kuulab antud porti
    local pid=$(lsof -i:$port -t 2>/dev/null)
    if [ -n "$pid" ]; then
        echo -e "Leitud protsess pordil $port (PID: $pid), lõpetan selle..."
        kill $pid 2>/dev/null
        # Anname protsessile natuke aega korralikult lõpetada
        sleep 1
        # Kui protsess ikka veel töötab, siis lõpetame selle jõuga
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}Protsess $pid ei lõpetanud tööd, kasutan jõudu (kill -9)${NC}"
            kill -9 $pid 2>/dev/null
        fi
        echo -e "${GREEN}Protsess pordil $port on lõpetatud.${NC}"
    else
        echo -e "${GREEN}Ühtegi protsessi pordil $port ei leitud.${NC}"
    fi
}

# Täiendatud protsesside puhastamine
clean_processes() {
    echo -e "${BLUE}Puhastan kõik vanad protsessid...${NC}"
    
    # Lõpeta protsessid mustrite järgi
    kill_process "uvicorn main:app" "Backend uvicorn"
    kill_process "node.*react-scripts start" "Frontend React"
    kill_process "webpack-dev-server" "Frontend Webpack"
    kill_process "npm start" "Frontend npm"
    
    # Lõpeta protsessid portide järgi
    kill_process_by_port 8000 "Backend API"
    kill_process_by_port 3000 "Frontend React"
    
    # Kontrolli, kas serverid on tõesti peatatud
    if lsof -i:8000 -t &>/dev/null || lsof -i:3000 -t &>/dev/null; then
        echo -e "${YELLOW}Mõned protsessid töötavad endiselt, proovin veel kord lõpetada...${NC}"
        pkill -f "node.*react-scripts" &>/dev/null
        pkill -f "webpack-dev-server" &>/dev/null
        pkill -f "uvicorn" &>/dev/null
        
        # Viimane võimalus: Lõpeta kõik node protsessid, mis on seotud antud kasutajaga
        echo -e "${YELLOW}Lõpetan kõik node protsessid, mis võivad olla seotud React rakendusega...${NC}"
        pkill -u $USER node &>/dev/null
        
        # Oota, et protsessid saaksid lõpetada
        sleep 2
    fi
    
    # Veendu, et ükski protsess ei kuula enam vajalikke porte
    if lsof -i:8000 -t &>/dev/null || lsof -i:3000 -t &>/dev/null; then
        echo -e "${RED}HOIATUS: Mõned protsessid kasutavad endiselt porte 8000 või 3000!${NC}"
        echo -e "${YELLOW}Võite käivitada käsitsi:${NC}"
        echo -e "sudo fuser -k 8000/tcp  # Backend pordi vabastamiseks"
        echo -e "sudo fuser -k 3000/tcp  # Frontend pordi vabastamiseks"
    else
        echo -e "${GREEN}Kõik vanad serverite protsessid on peatatud.${NC}"
    fi
}

# Funktsioon logifailide puhastamiseks
clean_logs() {
    echo -e "${YELLOW}Puhastan logifailid...${NC}"
    
    # Loo logikaustad, kui neid pole
    mkdir -p "${BASE_DIR}/backend/logs"
    mkdir -p "${BASE_DIR}/frontend/logs"
    
    # Puhastan või loon logifailid
    echo "" > "${BASE_DIR}/backend/logs/backend.log"
    echo "" > "${BASE_DIR}/frontend/logs/frontend.log"
    
    echo -e "${GREEN}Logifailid on puhastatud.${NC}"
}

# Kontrolli Docker'i olekut
check_docker() {
    echo -e "${BLUE}Kontrollin PostgreSQL Docker konteineri olekut...${NC}"
    
    if ! docker ps &>/dev/null; then
        echo -e "${RED}Docker ei ole käivitatud!${NC}"
        echo -e "Käivita Docker daemon: ${YELLOW}sudo systemctl start docker${NC}"
        return 1
    fi
    
    if ! docker ps | grep -q nature_photo_db_postgres; then
        echo -e "${YELLOW}PostgreSQL Docker konteiner ei ole käivitatud, käivitan...${NC}"
        cd "${BASE_DIR}/database"
        docker-compose up -d
        cd "${BASE_DIR}"
        
        echo -e "${YELLOW}Ootan PostgreSQL käivitumist...${NC}"
        sleep 5
        
        if ! docker ps | grep -q nature_photo_db_postgres; then
            echo -e "${RED}PostgreSQL Docker konteineri käivitamine ebaõnnestus!${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}PostgreSQL Docker konteiner on juba käivitatud.${NC}"
    fi
    
    return 0
}

# Kontrolli npm pakette
check_npm_packages() {
    echo -e "${BLUE}Kontrollin npm pakette...${NC}"
    
    cd "${BASE_DIR}/frontend"
    
    # Kontrolli, kas kõik Node.js polyfill'id on paigaldatud
    local packages=("axios" "url" "stream-http" "https-browserify" "util" "browserify-zlib" "stream-browserify" "assert" "buffer" "process")
    local missing=0
    
    for pkg in "${packages[@]}"; do
        if [ ! -d "node_modules/$pkg" ]; then
            echo -e "${YELLOW}Paigaldamata pakett: $pkg${NC}"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo -e "${YELLOW}Vajalikud npm paketid puuduvad, paigaldan need...${NC}"
        npm install --save axios url stream-http https-browserify util browserify-zlib stream-browserify assert buffer process
        
        # Kontrolli, kas meie craco.config.js fail on olemas ja korrektne
        if [ ! -f "craco.config.js" ]; then
            echo -e "${YELLOW}craco.config.js puudub, loon selle...${NC}"
            cat > craco.config.js << EOL
// craco.config.js
const webpack = require('webpack');

module.exports = {
  webpack: {
    configure: {
      resolve: {
        fallback: {
          url: require.resolve('url/'),
          http: require.resolve('stream-http'),
          https: require.resolve('https-browserify'),
          util: require.resolve('util/'),
          zlib: require.resolve('browserify-zlib'),
          stream: require.resolve('stream-browserify'),
          assert: require.resolve('assert/'),
          buffer: require.resolve('buffer/'),
          process: require.resolve('process/browser'),
        }
      }
    },
    plugins: [
      // Lisa uued Node.js/Browserify polyfill-id
      new webpack.ProvidePlugin({
        process: 'process/browser',
        Buffer: ['buffer', 'Buffer'],
      }),
    ]
  }
};
EOL
        fi
        
        # Kontrolli, kas package.json kasutab craco skripte
        if grep -q "\"start\": \"react-scripts start\"" package.json; then
            echo -e "${YELLOW}package.json kasutab react-scripts, muudan selle craco peale...${NC}"
            # Installin CRACO kui see puudub
            if [ ! -d "node_modules/@craco" ]; then
                npm install --save-dev @craco/craco
            fi
            
            # Asendan skriptid package.json failis
            sed -i 's/"start": "react-scripts start"/"start": "craco start"/g' package.json
            sed -i 's/"build": "react-scripts build"/"build": "craco build"/g' package.json
            sed -i 's/"test": "react-scripts test"/"test": "craco test"/g' package.json
        fi
        
        # Alternatiivne lahendus polyfill'ide jaoks (juhuks kui CRACO ei tööta)
        if [ ! -f "src/polyfills.js" ]; then
            echo -e "${YELLOW}Loon ka alternatiivse polyfill'ide lahenduse...${NC}"
            cat > src/polyfills.js << EOL
// Node.js polyfill'id
import { Buffer } from 'buffer';
window.Buffer = Buffer;
window.process = require('process');
EOL
            
            # Lisa polyfill'ide import index.js faili algusesse
            if [ -f "src/index.js" ]; then
                # Salvesta algne sisu ajutiselt
                cp src/index.js src/index.js.bak
                # Lisa import polyfill'id
                echo -e "// Import Node.js polyfill'id\nimport './polyfills';\n\n$(cat src/index.js.bak)" > src/index.js
                # Eemalda ajutine fail
                rm src/index.js.bak
            fi
        fi
    else
        echo -e "${GREEN}npm paketid on juba paigaldatud.${NC}"
    fi
    
    cd "${BASE_DIR}"
}

# Peamine funktsioon
main() {
    # 1. Lõpeta töötavad serverid
    clean_processes
    
    # 2. Puhastan logid
    clean_logs
    
    # 3. Kontrolli Docker'i
    check_docker || {
        echo -e "${RED}Docker'i kontrollimine ebaõnnestus! Katkestan.${NC}"
        exit 1
    }
    
    # 4. Kontrolli npm pakette
    check_npm_packages
    
    # 5. Kontrolli, kas Python virtuaalkeskkond on olemas ja aktiveeri see
    echo -e "${BLUE}Kontrollin Python virtuaalkeskkonda...${NC}"
    if [ ! -d "${BASE_DIR}/backend/venv" ]; then
        echo -e "${YELLOW}Python virtuaalkeskkond puudub, loon selle...${NC}"
        cd "${BASE_DIR}/backend"
        python3 -m venv venv
        cd "${BASE_DIR}"
    fi
    
    # 6. Aktiveeri virtuaalkeskkond
    echo -e "${YELLOW}Aktiveerin Python virtuaalkeskkonna...${NC}"
    source "${BASE_DIR}/backend/venv/bin/activate"
    
    # 7. Kontrolli Python sõltuvusi
    echo -e "${BLUE}Kontrollin Python sõltuvusi...${NC}"
    cd "${BASE_DIR}/backend"
    pip install -r requirements.txt > /dev/null
    cd "${BASE_DIR}"
    
    # 8. Käivita backend server
    echo -e "${BLUE}Käivitan backend serveri...${NC}"
    cd "${BASE_DIR}/backend"
    nohup uvicorn main:app --reload --host 0.0.0.0 --port 8000 > logs/backend.log 2>&1 &
    BACKEND_PID=$!
    cd "${BASE_DIR}"
    
    echo -e "${GREEN}Backend server käivitatud (PID: $BACKEND_PID)${NC}"
    
    # 9. Oota natuke, et backend server jõuaks käivituda
    echo -e "${YELLOW}Ootan backend serveri käivitumist...${NC}"
    sleep 3
    
    # 10. Kontrolli, kas backend server vastab
    echo -e "${BLUE}Kontrollin backend serveri vastamist...${NC}"
    if curl -s http://localhost:8000/api/health 2>/dev/null | grep -q "ok"; then
        echo -e "${GREEN}Backend server vastab korrektselt!${NC}"
    else
        echo -e "${YELLOW}Backend server ei vasta veel. Vaata logi: ${BASE_DIR}/backend/logs/backend.log${NC}"
    fi
    
    # 11. Käivita frontend server
    echo -e "${BLUE}Käivitan frontend serveri...${NC}"
    cd "${BASE_DIR}/frontend"
    nohup npm start > logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    cd "${BASE_DIR}"
    
    echo -e "${GREEN}Frontend server käivitatud (PID: $FRONTEND_PID)${NC}"
    
    # 12. Kokkuvõte
    echo ""
    echo -e "${GREEN}Serverid on taaskäivitatud:${NC}"
    echo -e "- Backend: ${BLUE}http://localhost:8000${NC} (PID: $BACKEND_PID)"
    echo -e "- Frontend: ${BLUE}http://localhost:3000${NC} (PID: $FRONTEND_PID)"
    echo -e "- PostgreSQL: ${BLUE}localhost:5433${NC} (Docker konteineris)"
    echo ""
    echo -e "${YELLOW}Logifailid:${NC}"
    echo "- Backend: ${BASE_DIR}/backend/logs/backend.log"
    echo "- Frontend: ${BASE_DIR}/frontend/logs/frontend.log"
    echo "- Docker: docker logs -f nature_photo_db_postgres"
    echo ""
    echo -e "${GREEN}Arenduskeskkond on valmis kasutamiseks!${NC}"
}

# Käivita peamine funktsioon
main