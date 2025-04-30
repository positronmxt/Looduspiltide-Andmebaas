#!/bin/bash

# Skript olemasoleva commiti GitHubi laadimiseks ilma uut commiti tegemata

echo "Lükkan olemasoleva commiti GitHubi..."

# Vaatame, millised GitHub skriptid on saadaval
if [ -f "./github_push.sh" ]; then
  # Kasutame github_push.sh skripti
  ./github_push.sh
elif [ -f "./push_github.sh" ]; then
  # Kasutame push_github.sh skripti
  ./push_github.sh
else
  # Kasutame github_upload_with_token.sh skripti, aga modifitseerime seda
  # nii, et see ei teeks uut commiti
  GITHUB_SCRIPT="./github_upload_with_token.sh"
  
  # Teeme skriptist ajutise koopia
  cp $GITHUB_SCRIPT ${GITHUB_SCRIPT}.bak
  
  # Kommenteerime välja read, mis teevad uue commit'i
  sed -i 's/^git add/#git add/' $GITHUB_SCRIPT
  sed -i 's/^git commit/#git commit/' $GITHUB_SCRIPT
  
  # Käivitame modifitseeritud skripti
  $GITHUB_SCRIPT
  
  # Taastame originaalskripti
  mv ${GITHUB_SCRIPT}.bak $GITHUB_SCRIPT
fi

echo "Protsess on lõpetatud!"