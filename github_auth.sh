#!/bin/bash
# github_auth.sh - Ajutine autentimine GitHubi jaoks

echo "===== GitHubi Autentimine ====="
echo "Sisesta oma GitHub Personal Access Token:"
read -s TOKEN

# Seadista autentimine
git config --local credential.helper store
echo "https://positronmxt:${TOKEN}@github.com" > ~/.git-credentials

# Lase kasutajal nüüd käivitada git push
echo ""
echo "Autentimine seadistatud. Nüüd saad käivitada:"
echo "git push origin main"
echo ""
echo "Kui oled lõpetanud, käivita järgmine käsk, et eemaldada token:"
echo "./github_auth_cleanup.sh"