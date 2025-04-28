#!/bin/bash

# Lisame värvid parema loetavuse jaoks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Alustame projekti üleslaadimist GitHub-i${NC}"

# Küsi kasutajalt GitHubi kasutajanime ja repo nime
read -p "Sisesta oma GitHubi kasutajanimi: " GITHUB_USERNAME
read -p "Sisesta GitHubi repositooriumi nimi (ilma .git lõputa): " REPO_NAME

# GitHub info
GITHUB_REPO="${GITHUB_USERNAME}/${REPO_NAME}.git"
GITHUB_URL="https://github.com/${GITHUB_REPO}"

echo -e "${YELLOW}Projekti üleslaadimise sihtkoht: ${GITHUB_URL}${NC}"

# Küsi Git kasutajainfo
read -p "Sisesta oma Git kasutajanimi (näiteks täisnimi): " GIT_USERNAME
read -p "Sisesta oma Git e-post: " GIT_EMAIL

# Seadista Git kasutajainfo
git config --global user.name "${GIT_USERNAME}"
git config --global user.email "${GIT_EMAIL}"
echo -e "${GREEN}Git kasutajainfo seadistatud.${NC}"

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

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
.pnp/
.pnp.js
.node_repl_history

# IDE
.idea/
.vscode/
*.swp
*.swo

# Database
*.sqlite3
*.db-journal

# Logs
*.log
nohup.out

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# OS specific
.DS_Store
Thumbs.db
EOL
echo -e "${GREEN}.gitignore fail on loodud.${NC}"

# Lisa kõik failid
echo -e "${YELLOW}Lisan kõik failid jälgimiseks...${NC}"
git add .
if [ $? -ne 0 ]; then
    echo -e "${RED}Failide lisamine ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Failid on lisatud.${NC}"

# Tee commit
read -p "Sisesta commit sõnum (nt. 'Esialgne projekti üleslaadimine'): " COMMIT_MESSAGE
git commit -m "${COMMIT_MESSAGE}"
if [ $? -ne 0 ]; then
    echo -e "${RED}Commit ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Commit on tehtud.${NC}"

# Lisa remote
echo -e "${YELLOW}Lisan GitHubi remote...${NC}"
git remote add origin "https://github.com/${GITHUB_REPO}"
if [ $? -ne 0 ]; then
    echo -e "${RED}Remote lisamine ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Remote on lisatud.${NC}"

# Küsi autentimise meetodit
echo -e "${YELLOW}Vali autentimismeetod:${NC}"
echo "1) GitHub kasutajanimi ja parool"
echo "2) GitHub Personal Access Token (soovitatav)"
read -p "Vali (1/2): " AUTH_METHOD

if [ "$AUTH_METHOD" = "1" ]; then
    # Push koos kasutajanime ja parooliga
    echo -e "${YELLOW}Laen projekti GitHubi...${NC}"
    echo -e "${YELLOW}Peale seda küsitakse sinu GitHubi kasutajanime ja parooli.${NC}"
    git push -u origin master
    if [ $? -ne 0 ]; then
        echo -e "${RED}Üleslaadimine ebaõnnestus.${NC}"
        echo -e "${YELLOW}Proovi uuesti Personal Access Token meetodiga (valik 2).${NC}"
        exit 1
    fi
elif [ "$AUTH_METHOD" = "2" ]; then
    # Push koos tokeniga
    read -p "Sisesta oma GitHub Personal Access Token: " GITHUB_TOKEN
    echo -e "${YELLOW}Laen projekti GitHubi kasutades Personal Access Token...${NC}"
    git push -u https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO} master
    if [ $? -ne 0 ]; then
        echo -e "${RED}Üleslaadimine ebaõnnestus.${NC}"
        exit 1
    fi
else
    echo -e "${RED}Vigane valik. Palun käivita skript uuesti.${NC}"
    exit 1
fi

echo -e "${GREEN}Projekt on edukalt üles laaditud GitHubi: ${GITHUB_URL}${NC}"
echo -e "${YELLOW}Nüüd saad oma repositooriumi vaadata aadressil: ${GITHUB_URL}${NC}"