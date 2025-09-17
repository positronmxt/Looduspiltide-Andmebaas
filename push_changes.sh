#!/bin/bash

# Modifitseeritud skript ilma uue commit'ita
# Lisame värvid parema loetavuse jaoks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Küsi token kasutajalt
echo -e "${YELLOW}Sisesta GitHubi personal access token:${NC}"
read -s GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}Token on tühi. Protsess katkestatud.${NC}"
    exit 1
fi

# GitHub repositooriumi URL tokeni põhise autentimisega
GITHUB_URL_WITH_TOKEN="https://${GITHUB_TOKEN}@github.com/positronmxt/Looduspiltide-Andmebaas.git"
GITHUB_URL_DISPLAY="https://github.com/positronmxt/Looduspiltide-Andmebaas.git"

echo -e "${YELLOW}Lükkan olemasolevad muudatused GitHub-i: ${GITHUB_URL_DISPLAY}${NC}"

# Kontrolli, kas remote on juba seadistatud
if git remote | grep -q "origin"; then
    echo -e "${YELLOW}Remote 'origin' on juba seadistatud. Muudan seda...${NC}"
    git remote set-url origin "$GITHUB_URL_WITH_TOKEN"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Remote 'origin' muutmine ebaõnnestus.${NC}"
        exit 1
    fi
else
    # Lisa GitHub remote koos tokeniga
    echo -e "${YELLOW}Lisan GitHub repositooriumi remote'ina...${NC}"
    git remote add origin "$GITHUB_URL_WITH_TOKEN"
    if [ $? -ne 0 ]; then
        echo -e "${RED}GitHub repositooriumi lisamine remote'ina ebaõnnestus.${NC}"
        exit 1
    fi
fi

# Lae projekt üles (push) - FORCE PUSH hoiatus!
echo -e "${YELLOW}Laen olemasolevad muudatused GitHub-i üles...${NC}"
git push -u origin main
PUSH_RESULT=$?

if [ $PUSH_RESULT -ne 0 ]; then
    echo -e "${RED}Muudatuste üleslaadimine ebaõnnestus.${NC}"
    echo -e "${YELLOW}Võimalikud põhjused:${NC}"
    echo -e "1. Token võib olla vale või aegunud"
    echo -e "2. Sul pole õigusi sellesse repositooriumisse laadida"
    exit 1
fi

echo -e "${GREEN}Muudatused on edukalt GitHub-i laaditud!${NC}"
echo -e "Projekti URL: ${GITHUB_URL_DISPLAY}"

# Puhastame salvestatud tokeni lokaalsest git konfiguratsioonist turvalisuse huvides
echo -e "${YELLOW}Eemaldan tokeni git konfiguratsioonist...${NC}"
git remote set-url origin "$GITHUB_URL_DISPLAY"
echo -e "${GREEN}Token on eemaldatud. Muudatused on nüüd GitHubis kättesaadavad!${NC}"