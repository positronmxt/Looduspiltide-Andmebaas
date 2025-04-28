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

# Seadista GitHub remote
if git remote | grep -q "origin"; then
    echo -e "${YELLOW}Eemaldan olemasoleva remote'i...${NC}"
    git remote remove origin
fi

echo -e "${YELLOW}Lisan GitHub remote'i...${NC}"
git remote add origin "https://$TOKEN@github.com/$GITHUB_REPO.git"

# Lae üles olemasolevad commitid
echo -e "${YELLOW}Laen projekti GitHubi üles...${NC}"
git push -u origin muudatused:main
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
    exit 1
fi

echo -e "${GREEN}Projekt on edukalt GitHubi üles laaditud!${NC}"
echo -e "Projekti URL: $GITHUB_URL"