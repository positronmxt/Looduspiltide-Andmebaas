#!/bin/bash

# Looduspiltide-Andmebaas - Paigaldusskript Linuxi jaoks
# -------------------------------------------------------

echo "============================================================="
echo "  Looduspiltide-Andmebaas - Paigaldusskript Linuxi jaoks"
echo "============================================================="
echo

# Funktsioonid
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "VIGA: $1 ei ole installitud. Palun installige see enne jätkamist."
        return 1
    fi
    return 0
}

install_dependency() {
    echo "Installin $1..."
    sudo apt-get install -y "$1" || {
        echo "VIGA: $1 installimine ebaõnnestus."
        return 1
    }
    return 0
}

# Kontrolli, kas skript käivitatakse root õigustes
if [[ $EUID -eq 0 ]]; then
    echo "HOIATUS: See skript ei tohiks käivituda root õigustes. Kasutage tavalist kasutajat sudo õigustega."
    read -p "Kas soovite siiski jätkata? (j/e): " continue_as_root
    if [[ "$continue_as_root" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
fi

# Kontrolli operatsioonisüsteemi
if [[ "$(uname)" != "Linux" ]]; then
    echo "VIGA: See skript on mõeldud ainult Linuxi operatsioonisüsteemile."
    exit 1
fi

# Kontrolli vajalikke käske
echo "Kontrollin vajalikke käske..."
check_command apt-get || {
    echo "VIGA: Teie süsteem ei kasuta apt-get paketihaldust. See skript on mõeldud Debiani põhistele süsteemidele."
    exit 1
}

# Küsi kasutaja parameetrid
echo
echo "Palun sisestage järgnevad parameetrid andmebaasi seadistamiseks:"
read -p "PostgreSQL serveri port [5432]: " db_port
db_port=${db_port:-5432}

read -p "Andmebaasi nimi [nature_photo_db]: " db_name
db_name=${db_name:-nature_photo_db}

read -p "Andmebaasi kasutajanimi [nature_user]: " db_user
db_user=${db_user:-nature_user}

read -s -p "Andmebaasi parool [securepassword]: " db_password
echo
db_password=${db_password:-securepassword}

# Määra paigalduse kataloog praeguseks kataloogiks
CURRENT_DIR=$(pwd)
INSTALL_DIR=$CURRENT_DIR
echo "Paigalduse kataloog: $INSTALL_DIR"

# Kinnita andmed
echo
echo "Kontrollige palun üle sisestatud parameetrid:"
echo "- PostgreSQL port: $db_port"
echo "- Andmebaasi nimi: $db_name"
echo "- Andmebaasi kasutaja: $db_user"
echo "- Paigalduskaust: $INSTALL_DIR"
echo
read -p "Kas need andmed on õiged? (j/e): " confirm
if [[ "$confirm" != "j" ]]; then
    echo "Skript katkestatud. Palun käivitage see uuesti õigete parameetritega."
    exit 1
fi

# Paigalda vajalikud pakid
echo
echo "Paigaldan vajalikud pakid..."
sudo apt-get update || {
    echo "VIGA: apt-get update ebaõnnestus."
    exit 1
}

required_packages=("python3" "python3-pip" "python3-venv" "nodejs" "npm" "git" "postgresql" "postgresql-contrib")
for package in "${required_packages[@]}"; do
    if ! check_command "$package"; then
        install_dependency "$package" || exit 1
    fi
done

# Kontrolli Pythoni versiooni
python3 --version | grep -q "Python 3.[1-9][1-9]" || {
    echo "HOIATUS: Soovitatav on Python 3.11+. Teie versioon võib olla liiga vana."
    read -p "Kas soovite siiski jätkata? (j/e): " continue_python
    if [[ "$continue_python" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
}

# Kontrolli NodeJS versiooni
nodejs --version || {
    echo "HOIATUS: NodeJS versiooni kontroll ebaõnnestus."
    read -p "Kas soovite siiski jätkata? (j/e): " continue_nodejs
    if [[ "$continue_nodejs" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
}

# Kontrolli PostgreSQL teenuse staatust
echo "Kontrollin PostgreSQL teenuse staatust..."
if ! systemctl is-active --quiet postgresql; then
    echo "PostgreSQL teenus ei ole aktiivne. Käivitan teenuse..."
    sudo systemctl start postgresql || {
        echo "VIGA: PostgreSQL teenuse käivitamine ebaõnnestus."
        exit 1
    }
    sudo systemctl enable postgresql || {
        echo "VIGA: PostgreSQL teenuse automaatkäivituse aktiveerimine ebaõnnestus."
        exit 1
    }
fi

# Loo PostgreSQL kasutaja ja andmebaas
echo "Loon PostgreSQL kasutaja ja andmebaasi..."
sudo -u postgres psql -c "SELECT 1 FROM pg_user WHERE usename = '$db_user'" | grep -q 1 || {
    sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_password';" || {
        echo "VIGA: Kasutaja $db_user loomine ebaõnnestus."
        exit 1
    }
}

sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = '$db_name'" | grep -q 1 || {
    sudo -u postgres psql -c "CREATE DATABASE $db_name OWNER $db_user;" || {
        echo "VIGA: Andmebaasi $db_name loomine ebaõnnestus."
        exit 1
    }
}

sudo -u postgres psql -c "ALTER USER $db_user WITH SUPERUSER;" || {
    echo "VIGA: Kasutajale $db_user superuser õiguste andmine ebaõnnestus."
    exit 1
}

# Muuda PostgreSQL pordi seadistust, kui kasutaja määras muu pordi kui vaikimisi
if [[ "$db_port" != "5432" ]]; then
    echo "Muudan PostgreSQL pordi seadistust ($db_port)..."
    postgres_conf_path=$(sudo -u postgres psql -c "SHOW config_file;" | grep "postgresql.conf")
    
    if [[ -z "$postgres_conf_path" ]]; then
        # Proovi leida alternatiivne tee
        postgres_version=$(pg_config --version | cut -d' ' -f2 | cut -d'.' -f1)
        postgres_conf_path="/etc/postgresql/$postgres_version/main/postgresql.conf"
    fi

    if [[ -f "$postgres_conf_path" ]]; then
        # Tee varukoopia
        sudo cp "$postgres_conf_path" "${postgres_conf_path}.bak" || {
            echo "HOIATUS: Ei õnnestunud teha varukoopiat PostgreSQL konfiguratsioonifailist."
        }
        
        # Muuda konfiguratsiooni
        sudo sed -i "s/^#\?port = .*/port = $db_port/" "$postgres_conf_path" || {
            echo "VIGA: PostgreSQL pordi seadistuse muutmine ebaõnnestus."
            exit 1
        }
        
        # Taaskäivita PostgreSQL
        echo "Taaskäivitan PostgreSQL teenuse uute seadistustega..."
        sudo systemctl restart postgresql || {
            echo "VIGA: PostgreSQL teenuse taaskäivitamine ebaõnnestus."
            exit 1
        }
    else
        echo "VIGA: PostgreSQL konfiguratsioonifaili ei leitud. Pordi muutmine ebaõnnestus."
        read -p "Kas soovite jätkata? (j/e): " continue_without_port_change
        if [[ "$continue_without_port_change" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
    fi
fi

# Uuenda andmebaasi konfiguratsioonifaili õigete parameetritega
echo "Uuendan andmebaasi konfiguratsiooni..."

# Loo .env fail andmebaasi seadistustega
echo "Loon .env faili backend kataloogi..."
env_file="backend/.env"
cat > "$env_file" << EOL
# Andmebaasi seadistused
DB_USER=$db_user
DB_PASSWORD=$db_password
DB_HOST=localhost
DB_PORT=$db_port
DB_NAME=$db_name
EOL

echo "Loodud .env fail andmebaasi seadistustega."

# Varuvariandina uuendame ka database.py faili otsest ühendusstring'i
db_config_file="backend/database.py"
if [[ -f "$db_config_file" ]]; then
    # Varunda originaal
    cp "$db_config_file" "${db_config_file}.bak" || {
        echo "HOIATUS: Ei õnnestunud teha varukoopiat andmebaasi konfiguratsioonifailist."
    }
    
    # Uuenda konfiguratsiooni, kui kasutatakse vana formaati
    if grep -q "DATABASE_URL = \"postgresql://" "$db_config_file"; then
        echo "Uuendan legacy andmebaasi ühendusstring'i..."
        sed -i "s|DATABASE_URL = \"postgresql://.*@localhost:[0-9]*/.*\"|DATABASE_URL = \"postgresql://${db_user}:${db_password}@localhost:${db_port}/${db_name}\"|g" "$db_config_file" || {
            echo "VIGA: Andmebaasi konfiguratsiooni uuendamine ebaõnnestus."
            exit 1
        }
    else
        echo "Kasutusele on võetud keskkonna muutujad andmebaasi seadistusteks - .env fail on loodud."
    fi
else
    echo "VIGA: Andmebaasi konfiguratsioonifaili ei leitud."
    exit 1
fi

# Seadista ja käivita backend
echo "Seadistan backend'i..."
cd backend || {
    echo "VIGA: Ei õnnestunud liikuda backend kataloogi."
    exit 1
}

# Kontrolli, kas python3-full on installitud (vajalik virtuaalkeskkonna jaoks)
if ! dpkg -l | grep -q python3-full; then
    echo "Python3-full pakett pole installitud. Proovin installida..."
    sudo apt-get install -y python3-full || {
        echo "HOIATUS: Python3-full paketi installimine ebaõnnestus."
        echo "Virtuaalkeskkonna loomine võib ebaõnnestuda."
    }
fi

# Virtuaalkeskkonna seadistamine
echo "Seadistan Python virtuaalkeskkonda..."
if [ ! -d "venv" ]; then
    echo "Loon uue virtuaalkeskkonna..."
    # Veendu, et python3-venv on installitud
    if ! dpkg -l | grep -q python3-venv; then
        echo "Python3-venv pakett pole installitud. Proovin installida..."
        sudo apt-get install -y python3-venv || {
            echo "HOIATUS: python3-venv paketi installimine ebaõnnestus."
            echo "Proovi käsitsi: sudo apt-get install python3-venv"
            exit 1
        }
    fi
    
    # Loo virtuaalkeskkond
    python3 -m venv venv || {
        echo "VIGA: Pythoni virtuaalkeskkonna loomine ebaõnnestus."
        echo "Proovi käsitsi järgmisi käske:"
        echo "  sudo apt-get install python3-venv python3-full"
        echo "  python3 -m venv venv"
        exit 1
    }
else
    echo "Kasutan olemasolevat virtuaalkeskkonda."
fi

# Kontrolli, kas pip on virtuaalkeskkonnas olemas
if [ ! -f "venv/bin/pip" ] && [ ! -f "venv/bin/pip3" ]; then
    echo "VIGA: Pip ei ole virtuaalkeskkonnas saadaval."
    echo "Proovin taastada virtuaalkeskkonda..."
    rm -rf venv
    python3 -m venv venv --clear || {
        echo "VIGA: Virtuaalkeskkonna taastamine ebaõnnestus."
        echo ""
        echo "Proovige käsitsi järgmisi käske:"
        echo "  rm -rf venv"
        echo "  python3 -m venv venv"
        exit 1
    }
fi

# Aktiveeri virtuaalkeskkond
echo "Aktiveerin virtuaalkeskkonna..."
source venv/bin/activate || {
    echo "VIGA: Pythoni virtuaalkeskkonna aktiveerimine ebaõnnestus."
    exit 1
}

# Uuenda pip virtuaalkeskkonnas
echo "Uuendan pip-i virtuaalkeskkonnas..."
python -m pip install --upgrade pip || {
    echo "HOIATUS: Pip-i uuendamine ebaõnnestus, kuid jätkan."
}

# Paigalda sõltuvused
echo "Installin Python sõltuvused virtuaalkeskkonnas..."
python -m pip install -r requirements.txt || {
    # Kui tavaline install ebaõnnestub, proovi PEP668 lipuga
    echo "Tavaline install ebaõnnestus, proovin alternatiivset meetodit..."
    python -m pip install --break-system-packages -r requirements.txt || {
        # Kui ka see ebaõnnestub, anna selged juhised käsitsi lahendamiseks
        echo "VIGA: Pythoni sõltuvuste paigaldamine ebaõnnestus."
        echo ""
        echo "Detailsed sammud probleemi lahendamiseks käsitsi:"
        echo "1. Mine backend kataloogi: cd $INSTALL_DIR/backend"
        echo "2. Loo virtuaalkeskkond: python3 -m venv venv"
        echo "3. Aktiveeri virtuaalkeskkond: source venv/bin/activate"
        echo "4. Uuenda pip: pip install --upgrade pip"
        echo "5. Installeeri sõltuvused: pip install -r requirements.txt"
        echo ""
        echo "Veateade:"
        python -m pip install -r requirements.txt
        exit 1
    }
}

# Loo andmebaasi tabelid
python create_tables.py || {
    echo "VIGA: Andmebaasi tabelite loomine ebaõnnestus."
    exit 1
}

# Liigu tagasi projekti juurkataloogi
cd ..

# Seadista ja käivita frontend
echo "Seadistan frontend'i..."
cd frontend || {
    echo "VIGA: Ei õnnestunud liikuda frontend kataloogi."
    exit 1
}

# Paigalda sõltuvused
npm install || {
    echo "VIGA: NPM sõltuvuste paigaldamine ebaõnnestus."
    exit 1
}

# Liigu tagasi projekti juurkataloogi
cd ..

# Uuenda start_servers.sh skriptis projekti kataloogi tee
echo "Uuendan start_servers.sh skripti projekti kataloogi teega..."
start_script="start_servers.sh"
if [[ -f "$start_script" ]]; then
    # Varunda originaal
    cp "$start_script" "${start_script}.bak" || {
        echo "HOIATUS: Ei õnnestunud teha varukoopiat $start_script failist."
    }
    
    # Uuenda projekti kataloogi tee
    sed -i "s|PROJECT_DIR=\".*\"|PROJECT_DIR=\"$INSTALL_DIR\"|g" "$start_script" || {
        echo "HOIATUS: start_servers.sh skripti uuendamine ebaõnnestus."
        echo "Võite käsitsi uuendada PROJECT_DIR muutujat $start_script failis."
    }
    echo "start_servers.sh on uuendatud õige projekti kataloogiga."
else
    echo "HOIATUS: start_servers.sh faili ei leitud. Serveri käivitamine võib ebaõnnestuda."
fi

# Tee käivitusskript käivitatavaks
chmod +x start_servers.sh || {
    echo "HOIATUS: Käivitusskripti käivitatavaks tegemine ebaõnnestus."
}

# Loo vajalikud kaustad, kui neid veel pole
mkdir -p file_storage || {
    echo "HOIATUS: Piltide salvestuskataloogi loomine ebaõnnestus."
}

# Lõpetuseks
echo
echo "============================================================="
echo "  Paigaldus on lõpetatud!"
echo "============================================================="
echo
echo "Käivitage rakendus käsuga:"
echo "cd $INSTALL_DIR && ./start_servers.sh"
echo
echo "Backend käivitub aadressil: http://localhost:8000"
echo "Frontend käivitub aadressil: http://localhost:3000"
echo
echo "Täname, et kasutate Looduspiltide Andmebaasi!"
echo "============================================================="