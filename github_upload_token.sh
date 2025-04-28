#!/bin/bash

# Lisame värvid parema loetavuse jaoks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repositooriumi info
GITHUB_USERNAME="positronmxt"
GITHUB_REPO="Looduspiltide-Andmebaas"
GITHUB_TOKEN="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"

# Konstrueerime URL-i tokeniga
GITHUB_URL_WITH_TOKEN="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
GITHUB_URL_DISPLAY="https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"

echo -e "${YELLOW}Alustame projekti üleslaadimist GitHub-i: ${GITHUB_URL_DISPLAY}${NC}"

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
github_upload_token.sh
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

# Lisa GitHub remote koos tokeniga
echo -e "${YELLOW}Lisan GitHub repositooriumi remote'ina...${NC}"
git remote add origin "$GITHUB_URL_WITH_TOKEN"
if [ $? -ne 0 ]; then
    echo -e "${RED}GitHub repositooriumi lisamine remote'ina ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}GitHub repositoorium on lisatud remote'ina.${NC}"

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
    
    echo -e "\n${YELLOW}Proovige järgmist:${NC}"
    echo -e "1. Kontrollige, kas tokenil on õiged õigused (repo, workflow)"
    echo -e "2. Kontrollige, kas repositooriumi nimi on õige"
    echo -e "3. Proovige käsitsi käsuga:"
    echo -e "   git push https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git main"
    
    exit 1
fi

echo -e "${GREEN}Projekt on edukalt GitHub-i üles laaditud!${NC}"
echo -e "Projekti URL: ${GITHUB_URL_DISPLAY}"

# Puhastame salvestatud tokeni lokaalsest git konfiguratsioonist turvalisuse huvides
echo -e "${YELLOW}Eemaldan tokeni git konfiguratsioonist...${NC}"
git remote set-url origin "$GITHUB_URL_DISPLAY"
echo -e "${GREEN}Token on eemaldatud. Projekt on nüüd GitHubis kättesaadav!${NC}"