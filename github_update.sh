#!/bin/bash

# Värvid
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Loe token .env failist
if [ -f ".env" ]; then
    source .env
else
    echo -e "${RED}Ei leia .env faili, mis peaks sisaldama GitHub tokenit.${NC}"
    echo -e "Loo .env fail järgmise sisuga:"
    echo "GITHUB_TOKEN=sinu_github_token"
    exit 1
fi

# GitHub URL
GITHUB_URL="https://github.com/positronmxt/Looduspiltide-Andmebaas.git"

echo -e "${YELLOW}Uuendan projekti GitHubis...${NC}"

# Kontrolli, kas git on juba seadistatud
if [ ! -d ".git" ]; then
    echo -e "${RED}Git pole seadistatud. Palun käivitage esmalt github_upload_with_token.sh${NC}"
    exit 1
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
git commit -m "$commit_message"
if [ $? -ne 0 ]; then
    echo -e "${RED}Commit ebaõnnestus.${NC}"
    exit 1
fi
echo -e "${GREEN}Commit tehtud: $commit_message${NC}"

# Eemalda vana remote, kui eksisteerib
if git remote | grep -q "origin"; then
    git remote remove origin
fi

# Lisa uus remote tokeniga
git remote add origin "https://${GITHUB_TOKEN}@github.com/positronmxt/Looduspiltide-Andmebaas.git"

# Lae üles
echo -e "${YELLOW}Laen muudatused GitHubi...${NC}"
git push -u origin main
if [ $? -ne 0 ]; then
    echo -e "${RED}Üleslaadimine ebaõnnestus.${NC}"
    exit 1
fi

# Puhasta token konfiguratsioonist
git remote set-url origin "$GITHUB_URL"

echo -e "${GREEN}Projekt on edukalt uuendatud GitHubis!${NC}"
echo -e "Projekti URL: $GITHUB_URL"