#!/bin/bash

# Värvid
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# GitHub repositoorium
GITHUB_REPO="positronmxt/Looduspiltide-Andmebaas"
GITHUB_URL="https://github.com/$GITHUB_REPO.git"

echo -e "${YELLOW}Looduspiltide andmebaasi projekti GitHubi üleslaadija${NC}"
echo -e "---------------------------------------------------"

# Küsi kasutajalt token (seda ei salvestata koodifaili)
echo -n "Sisesta oma GitHub Personal Access Token: "
read -s TOKEN
echo ""

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Token on vajalik. Proovi uuesti.${NC}"
    exit 1
fi

# Kontrolli, kas Git on juba seadistatud
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Git pole veel seadistatud. Seadistan...${NC}"
    git init
    if [ $? -ne 0 ]; then
        echo -e "${RED}Git'i initsialiseerimine ebaõnnestus.${NC}"
        exit 1
    fi
    
    # Seadista Git
    if [ -z "$(git config user.name)" ]; then
        echo -n "Sisesta oma nimi Git'i jaoks: "
        read GIT_NAME
        git config user.name "$GIT_NAME"
    fi
    
    if [ -z "$(git config user.email)" ]; then
        echo -n "Sisesta oma e-post Git'i jaoks: "
        read GIT_EMAIL
        git config user.email "$GIT_EMAIL"
    fi
    
    # Loo või uuenda .gitignore
    if [ ! -f ".gitignore" ]; then
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

# Skriptid, mis võivad sisaldada tundlikke andmeid
github_upload_token.sh
github_upload_with_token.sh
.env
EOL
        echo -e "${GREEN}.gitignore fail on loodud.${NC}"
    fi
else
    echo -e "${GREEN}Git on juba seadistatud.${NC}"
fi

# Lisa muudatused
echo -e "${YELLOW}Lisan muudatused...${NC}"
git add .
if [ $? -ne 0 ]; then
    echo -e "${RED}Muudatuste lisamine ebaõnnestus.${NC}"
    exit 1
fi

# Küsi commit sõnumit
echo -n "Sisesta commit sõnum (vajuta Enter, et kasutada vaikimisi sõnumit): "
read commit_message
if [ -z "$commit_message" ]; then
    commit_message="Projekti uuendus $(date +%d.%m.%Y)"
fi

# Tee commit
echo -e "${YELLOW}Teen commit'i...${NC}"
git commit -m "$commit_message"
if [ $? -ne 0 ]; then
    echo -e "${RED}Commit ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Commit tehtud: $commit_message${NC}"

# Seadista GitHub remote
if git remote | grep -q "origin"; then
    echo -e "${YELLOW}Eemaldan olemasoleva remote'i...${NC}"
    git remote remove origin
fi

echo -e "${YELLOW}Lisan GitHub remote'i...${NC}"
git remote add origin "https://$TOKEN@github.com/$GITHUB_REPO.git"

# Lae üles
echo -e "${YELLOW}Laen projekti GitHubi üles...${NC}"
git push -u origin muudatused
PUSH_RESULT=$?

# Puhasta token konfiguratsioonist (turvalisuse huvides)
git remote set-url origin "$GITHUB_URL"

if [ $PUSH_RESULT -ne 0 ]; then
    echo -e "${RED}Üleslaadimine ebaõnnestus.${NC}"
    echo -e "${YELLOW}Võimalikud põhjused:${NC}"
    echo -e "1. Token võib olla vale või kehtetu"
    echo -e "2. Teil pole õigusi sellesse repositooriumisse laadida"
    echo -e "3. GitHub tuvastas varasemaid tokenieid Git ajaloos - sellisel juhul:"
    echo -e "   a) Külasta GitHub'i lehte ja luba token, kui sulle vastav link kuvatakse"
    echo -e "   b) Või alusta nullist uue tühja repositooriumiga"
    echo -e ""
    echo -e "Probleemi lahendamiseks: Kui viga näitab 'repository rule violations',"
    echo -e "siis ilmselt leidis GitHub teie koodist tundlikke andmeid. Valige üks järgmistest:"
    echo -e "1. Kasutage GitHubi veebiliidest, et luba konkreetsele tokenile"
    echo -e "2. Looge uus puhas repo ja lükake ainult praegused failid (mitte ajalugu)"
    exit 1
fi

echo -e "${GREEN}Projekt on edukalt GitHubi üles laaditud!${NC}"
echo -e "Projekti URL: $GITHUB_URL"