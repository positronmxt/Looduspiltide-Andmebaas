#!/bin/bash

# Skript olemasoleva commiti GitHubi laadimiseks tokeni abil

echo "Lükkan olemasoleva commiti GitHubi..."

# Seadista token
GITHUB_TOKEN=`cat ~/.github_token`

# Seadista ajutiselt URL tokeni kasutamiseks
git remote set-url origin https://positronmxt:${GITHUB_TOKEN}@github.com/positronmxt/Looduspiltide-Andmebaas.git

# Lükka commit GitHubi
git push origin main

# Taasta URL ilma tokenita
git remote set-url origin https://github.com/positronmxt/Looduspiltide-Andmebaas.git

echo "Muudatused on GitHubi laaditud!"
echo "Token on git konfiguratsioonist eemaldatud."