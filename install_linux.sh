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

# Kontrolli, kas skripti käivitatakse projekti kataloogis
CURRENT_DIR=$(pwd)
echo "Paigalduse kataloog: $CURRENT_DIR"

# Täiustatud projekti tuvastus - kontrolli mitmeid indikaatoreid
if [ -d "$CURRENT_DIR/backend" ] && [ -d "$CURRENT_DIR/frontend" ]; then
    # Otsene tuvastus juurkataloogis
    INSTALL_FROM_GITHUB=false
    INSTALL_DIR=$CURRENT_DIR
    echo "Tuvastatud olemasolev projekt praeguses kataloogis. Ei klooni uuesti."
elif [ -f "$CURRENT_DIR/github_upload_with_token.sh" ] || [ -f "$CURRENT_DIR/install_linux.sh" ] || [ -f "$CURRENT_DIR/start_servers.sh" ]; then
    # Tuvastus projekti skriptide põhjal
    INSTALL_FROM_GITHUB=false
    INSTALL_DIR=$CURRENT_DIR
    echo "Tuvastatud olemasolev projekt praeguses kataloogis skriptide põhjal. Ei klooni uuesti."
elif [ "$(basename "$CURRENT_DIR")" = "Looduspiltide-Andmebaas" ] || [ "$(basename "$CURRENT_DIR")" = "nature-photo-db" ]; then
    # Tuvastus kataloogi nime põhjal
    INSTALL_FROM_GITHUB=false
    INSTALL_DIR=$CURRENT_DIR
    echo "Tuvastatud olemasolev projekt kataloogi nime põhjal. Ei klooni uuesti."
else
    echo "Praegune kataloog ei sisalda Looduspiltide-Andmebaas projekti."
    read -p "Millises kaustas soovite projekti kloonida? [$(pwd)]: " install_dir
    INSTALL_DIR=${install_dir:-$(pwd)}
    INSTALL_FROM_GITHUB=true
fi

# Kinnita andmed
echo
echo "Kontrollige palun üle sisestatud parameetrid:"
echo "- PostgreSQL port: $db_port"
echo "- Andmebaasi nimi: $db_name"
echo "- Andmebaasi kasutaja: $db_user"
if [ "$INSTALL_FROM_GITHUB" = true ]; then
    echo "- Paigalduskaust: $INSTALL_DIR (projekti kloonitakse GitHubist)"
else
    echo "- Paigalduskaust: $INSTALL_DIR (kasutatakse olemasolevat projekti)"
fi
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

# Liigu projekti kataloogi
if [ "$INSTALL_FROM_GITHUB" = true ]; then
    # Liigu paigalduskataloogi
    mkdir -p "$INSTALL_DIR" || {
        echo "VIGA: Ei õnnestunud luua kataloogi $INSTALL_DIR."
        exit 1
    }
    cd "$INSTALL_DIR" || {
        echo "VIGA: Ei õnnestunud liikuda kataloogi $INSTALL_DIR."
        exit 1
    }

    # Klooni repositoorium
    echo "Kloonin projekti repositooriumi..."
    git clone https://github.com/positronmxt/Looduspiltide-Andmebaas.git || {
        echo "VIGA: Projekti kloonimine GitHubist ebaõnnestus."
        exit 1
    }

    cd Looduspiltide-Andmebaas || {
        echo "VIGA: Ei õnnestunud liikuda projekti kataloogi."
        exit 1
    }
else
    # Kui skript käivitatakse juba projekti kataloogis, pole vaja liikuda
    echo "Kasutan olemasolevat projekti kataloogis: $INSTALL_DIR"
fi

# Uuenda andmebaasi konfiguratsioonifaili õigete parameetritega
echo "Uuendan andmebaasi konfiguratsiooni..."
db_config_file="backend/database.py"
if [[ -f "$db_config_file" ]]; then
    # Varunda originaal
    cp "$db_config_file" "${db_config_file}.bak" || {
        echo "HOIATUS: Ei õnnestunud teha varukoopiat andmebaasi konfiguratsioonifailist."
    }
    
    # Uuenda konfiguratsiooni
    sed -i "s|postgresql://.*@localhost:[0-9]*/.*|postgresql://${db_user}:${db_password}@localhost:${db_port}/${db_name}|g" "$db_config_file" || {
        echo "VIGA: Andmebaasi konfiguratsiooni uuendamine ebaõnnestus."
        exit 1
    }
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

# Loo virtuaalkeskkond
python3 -m venv venv || {
    echo "VIGA: Pythoni virtuaalkeskkonna loomine ebaõnnestus."
    exit 1
}

# Aktiveeri virtuaalkeskkond
source venv/bin/activate || {
    echo "VIGA: Pythoni virtuaalkeskkonna aktiveerimine ebaõnnestus."
    exit 1
}

# Paigalda sõltuvused
pip install -r requirements.txt || {
    echo "VIGA: Pythoni sõltuvuste paigaldamine ebaõnnestus."
    exit 1
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