#!/bin/bash

# Lisame värvid parema loetavuse jaoks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub repositooriumi URL
GITHUB_URL="https://github.com/positronmxt/Looduspiltide-Andmebaas.git"

echo -e "${YELLOW}Alustame projekti üleslaadimist GitHub-i: ${GITHUB_URL}${NC}"

# Kontrolli, kas git on installitud
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git pole installitud. Palun installige Git:${NC}"
    echo "sudo apt-get install git"
    exit 1
fi

# Kontrolli, kas git kasutaja on seadistatud
GIT_USER_NAME=$(git config --global user.name)
GIT_USER_EMAIL=$(git config --global user.email)

if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    echo -e "${YELLOW}Git kasutaja pole seadistatud. Seadistame selle nüüd:${NC}"
    
    # Küsi kasutajalt nime ja meili
    echo -n "Sisestage oma nimi Git-i jaoks: "
    read git_name
    echo -n "Sisestage oma email Git-i jaoks: "
    read git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    echo -e "${GREEN}Git kasutaja on nüüd seadistatud.${NC}"
fi

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

# Lisa kõik failid jälgimiseks
echo -e "${YELLOW}Lisan kõik failid Git jälgimisse...${NC}"
git add .
if [ $? -ne 0 ]; then
    echo -e "${RED}Failide lisamine ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Kõik failid on lisatud.${NC}"

# Kontrolli, kas commitimine õnnestub (võib-olla on eelnevalt vaja seadistada email ja nimi)
echo -e "${YELLOW}Teen esialgse kinnituse (commit)...${NC}"
git commit -m "Esialgne kinnitus: looduspiltide andmebaas kuufiltritega"
if [ $? -ne 0 ]; then
    echo -e "${RED}Kinnituse (commit) tegemine ebaõnnestus.${NC}"
    echo -e "${YELLOW}Veenduge, et Git kasutaja on seadistatud:${NC}"
    echo "git config --global user.name \"TEIE_NIMI\""
    echo "git config --global user.email \"TEIE_EMAIL\""
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
git remote add origin $GITHUB_URL
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
    
    # Paku alternatiivset HTTPS autentimise võimalust
    echo -e "${YELLOW}Võimalikud põhjused:${NC}"
    echo -e "1. Te pole GitHub-i sisse logitud"
    echo -e "2. Teil pole õigusi sellesse repositooriumisse laadida"
    echo -e "3. Remote URL võib olla vale"
    
    echo -e "\n${YELLOW}Proovige järgmisi lahendusi:${NC}"
    echo -e "1. Kasutage isiklikku pääsutokenit (Personal Access Token - PAT):"
    echo -e "   a. Minge GitHub-is: Settings > Developer settings > Personal access tokens"
    echo -e "   b. Looge uus token õigusega 'repo'"
    echo -e "   c. Kasutage tokenit paroolina, kui Git seda küsib"
    
    echo -e "\n2. Kui olete repositooriumi omanik, kontrollige URL-i:"
    echo -e "   git remote set-url origin https://github.com/positronmxt/Looduspiltide-Andmebaas.git"
    
    echo -e "\n3. Kasutage SSH võtme põhist autentimist (soovitatud):"
    echo -e "   a. Looge SSH võti: ssh-keygen -t ed25519 -C \"teie-email@näide.com\""
    echo -e "   b. Lisage avalik võti GitHub-i: Settings > SSH and GPG keys"
    echo -e "   c. Seadistage remote URL kasutama SSH-d:"
    echo -e "      git remote set-url origin git@github.com:positronmxt/Looduspiltide-Andmebaas.git"
    
    echo -e "\nProovige pärast muudatusi uuesti käivitada: ./github_upload.sh"
    exit 1
fi

echo -e "${GREEN}Projekt on edukalt GitHub-i üles laaditud!${NC}"
echo -e "Projekti URL: ${GITHUB_URL}"