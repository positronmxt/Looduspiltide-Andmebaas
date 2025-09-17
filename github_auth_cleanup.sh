#!/bin/bash
# github_auth_cleanup.sh - Eemaldab GitHubi autentimise andmed

echo "===== GitHubi Autentimise Puhastamine ====="

# Eemalda salvestatud token
rm -f ~/.git-credentials
git config --local --unset credential.helper

echo "Autentimise andmed on eemaldatud."