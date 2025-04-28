#!/bin/bash

# GitHub repositooriumi URL
GITHUB_URL="https://github.com/positronmxt/Looduspiltide-Andmebaas.git"

# Kontrolli, kas git on juba seadistatud
if [ ! -d ".git" ]; then
  echo "Seadistan Git-i repositooriumi..."
  git init
  echo "Git on seadistatud."
else
  echo "Git on juba seadistatud."
fi

# Loome .gitignore faili
echo "Loon .gitignore faili..."
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
echo ".gitignore fail on loodud."

# Kontrolli, kas frontend kataloogis on .git kaust ja eemalda see
if [ -d "frontend/.git" ]; then
  echo "Eemaldan frontend kataloogist Git konfiguratsiooni..."
  rm -rf frontend/.git
  echo "Frontend kataloogist on Git konfiguratsioon eemaldatud."
fi

# Lisa kõik failid jälgimiseks
echo "Lisan kõik failid Git jälgimisse..."
git add .
echo "Kõik failid on lisatud."

# Tee esialgne kinnitus (commit)
echo "Teen esialgse kinnituse (commit)..."
git commit -m "Esialgne kinnitus: looduspiltide andmebaas kuufiltritega"
echo "Esialgne kinnitus on tehtud."

# Muuda peaharu nimeks "main"
echo "Nimetan peaharu ümber 'main'-iks..."
git branch -M main
echo "Peaharu on nüüd 'main'."

# Kontrolli, kas remote on juba seadistatud
if git remote | grep -q "origin"; then
  echo "Remote 'origin' on juba seadistatud. Eemaldan selle..."
  git remote remove origin
fi

# Lisa GitHub remote
echo "Lisan GitHub repositooriumi remote'ina..."
git remote add origin $GITHUB_URL
echo "GitHub repositoorium on lisatud remote'ina."

# Lae projekt üles (push)
echo "Laen projekti GitHub-i üles..."
git push -u origin main --force
echo "Projekt on edukalt GitHub-i üles laaditud!"
echo "Projekti URL: $GITHUB_URL"
echo ""
echo "NB! Kui näete veateadet, siis võib põhjuseks olla, et pole GitHub-i sisselogitud."
echo "Logige sisse käsuga: git config --global user.name \"TEIE_NIMI\" ja git config --global user.email \"TEIE_EMAIL\""
echo "Seejärel proovige uuesti: git push -u origin main"