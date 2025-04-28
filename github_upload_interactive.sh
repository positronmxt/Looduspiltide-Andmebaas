#!/bin/bash

# Lisame värvid parema loetavuse jaoks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub info
GITHUB_REPO="positronmxt/Looduspiltide-Andmebaas.git"
GITHUB_URL="https://github.com/${GITHUB_REPO}"

echo -e "${YELLOW}Alustame projekti üleslaadimist GitHub-i: ${GITHUB_URL}${NC}"

# Kontrolli, kas git on juba seadistatud
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Seadistan Git-i repositooriumi...${NC}"
    git init
    if [ $? -ne 0 ]; then
        echo -e "${RED}Git-i initsialiseerimine ebaõnnestus.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Git on seadistatud.${NC}"
else
    echo -e "${GREEN}Git on juba seadistatud.${NC}"
fi

# Loome .gitignore faili
echo -e "${YELLOW}Loon .gitignore faili...${NC}"
cat > .gitignore << 'EOL'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg
.pytest_cache/
.coverage
htmlcov/

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
package-lock.json
.DS_Store

# Logs
*.log
nohup.out

# Database
*.db-journal

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE settings
.idea/
.vscode/
*.swp
*.swo

# Script with token
github_upload_with_token.sh
EOL
echo -e "${GREEN}.gitignore fail on loodud.${NC}"

# Kontrolli, kas frontend kataloogis on .git kaust ja eemalda see
if [ -d "frontend/.git" ]; then
    echo -e "${YELLOW}Eemaldan frontend kataloogist Git konfiguratsiooni...${NC}"
    rm -rf frontend/.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ei õnnestunud frontend kataloogist .git kausta eemaldada. Proovige käsitsi:${NC}"
        echo "rm -rf frontend/.git"
    else
        echo -e "${GREEN}Frontend kataloogist on Git konfiguratsioon eemaldatud.${NC}"
    fi
fi

# Seadistame ajutised Git konfiguratsiooni parameetrid, kui need puuduvad
if [ -z "$(git config user.name)" ]; then
    git config user.name "Positron MXT"
fi

if [ -z "$(git config user.email)" ]; then
    git config user.email "positronmxt@example.com"
fi

# Lisa kõik failid jälgimiseks
echo -e "${YELLOW}Lisan kõik failid Git jälgimisse...${NC}"
git add .
if [ $? -ne 0 ]; then
    echo -e "${RED}Failide lisamine ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Kõik failid on lisatud.${NC}"

# Tee kinnitus (commit)
echo -e "${YELLOW}Teen esialgse kinnituse (commit)...${NC}"
git commit -m "Esialgne kinnitus: looduspiltide andmebaas kuufiltritega"
if [ $? -ne 0 ]; then
    echo -e "${RED}Kinnituse (commit) tegemine ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Esialgne kinnitus on tehtud.${NC}"

# Muuda peaharu nimeks "main"
echo -e "${YELLOW}Nimetan peaharu ümber 'main'-iks...${NC}"
git branch -M main
if [ $? -ne 0 ]; then
    echo -e "${RED}Peaharu ümbernimetamine ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Peaharu on nüüd 'main'.${NC}"

# Kontrolli, kas remote on juba seadistatud
if git remote | grep -q "origin"; then
    echo -e "${YELLOW}Remote 'origin' on juba seadistatud. Eemaldan selle...${NC}"
    git remote remove origin
    if [ $? -ne 0 ]; then
        echo -e "${RED}Remote 'origin' eemaldamine ebaõnnestus.${NC}"
        exit 1
    fi
fi

# Lisa GitHub remote
echo -e "${YELLOW}Lisan GitHub repositooriumi remote'ina...${NC}"
git remote add origin "$GITHUB_URL"
if [ $? -ne 0 ]; then
    echo -e "${RED}GitHub repositooriumi lisamine remote'ina ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}GitHub repositoorium on lisatud remote'ina.${NC}"

# Küsi kasutaja andmeid interaktiivselt
echo -e "${YELLOW}Nüüd vajame GitHub autentimist.${NC}"
echo -e "Kui küsitakse kasutajanime ja parooli, siis:"
echo -e "1. Kasutajanimi on teie GitHub kasutajanimi"
echo -e "2. Paroolina kasutage GitHub Personal Access Token'it"

# Lae projekt üles (push)
echo -e "${YELLOW}Laen projekti GitHub-i üles...${NC}"
git push -u origin main --force
PUSH_RESULT=$?

if [ $PUSH_RESULT -ne 0 ]; then
    echo -e "${RED}Projekti üleslaadimine ebaõnnestus.${NC}"
    echo -e "${YELLOW}Võimalikud põhjused:${NC}"
    echo -e "1. Token võib olla vale või kehtetu"
    echo -e "2. Teil pole õigusi sellesse repositooriumisse laadida"
    echo -e "3. Remote URL võib olla vale"
    
    echo -e "\n${YELLOW}Proovi järgmisi käsureavõtteid:${NC}"
    echo -e "1. Seadista token otseselt käsureal:"
    echo -e "   git remote set-url origin https://YourGitHubUsername:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}"
    echo -e "   git push -u origin main --force"
    
    echo -e "\n2. Kasuta Git'i vahemälu salvestamist (võib küsida sinu kasutajanime ja tokenit):"
    echo -e "   git config --global credential.helper cache"
    echo -e "   git push -u origin main --force"
    
    exit 1
fi

echo -e "${GREEN}Projekt on edukalt GitHub-i üles laaditud!${NC}"
echo -e "Projekti URL: ${GITHUB_URL}"