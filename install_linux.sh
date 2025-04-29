#!/bin/bash

# Looduspiltide-Andmebaas - Paigaldusskript Linuxi jaoks
# -------------------------------------------------------

echo "============================================================="
echo "  Looduspiltide-Andmebaas - Paigaldusskript Linuxi jaoks"
echo "============================================================="
echo

# Värvid terminalis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktsioonid
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[HOIATUS]${NC} $1"
}

log_error() {
    echo -e "${RED}[VIGA]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 ei ole installitud. Palun installige see enne jätkamist."
        return 1
    fi
    return 0
}

install_dependency() {
    log_info "Installin $1..."
    sudo apt-get install -y "$1" || {
        log_error "$1 installimine ebaõnnestus."
        return 1
    }
    log_success "$1 edukalt installitud."
    return 0
}

check_network() {
    log_info "Kontrollin internetiühendust..."
    if ping -c 1 google.com &> /dev/null; then
        log_success "Internetiühendus töötab."
        return 0
    else
        log_error "Internetiühenduse kontroll ebaõnnestus. Pakettide allalaadimine võib ebaõnnestuda."
        read -p "Kas soovite jätkata? (j/e): " continue_without_network
        if [[ "$continue_without_network" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
        return 1
    fi
}

check_disk_space() {
    log_info "Kontrollin vaba kettaruumi..."
    # Vähemalt 500MB vaba ruumi on vajalik
    free_space=$(df -m . | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 500 ]; then
        log_error "Vähe vaba kettaruumi (${free_space}MB). Soovitav on vähemalt 500MB."
        read -p "Kas soovite jätkata? (j/e): " continue_without_space
        if [[ "$continue_without_space" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
        return 1
    else
        log_success "Piisavalt vaba kettaruumi (${free_space}MB)."
        return 0
    fi
}

check_postgres_socket() {
    log_info "Kontrollin PostgreSQL sokli seadistust..."
    # Kontrolli, kas postgres kasutaja eksisteerib
    if id -u postgres &>/dev/null; then
        # Kontrolli, kas sokli kataloog eksisteerib ja on õigete õigustega
        if [ -d "/var/run/postgresql" ]; then
            log_success "PostgreSQL sokli kataloog on olemas."
            # Kontrolli õigusi
            if sudo -u postgres test -w "/var/run/postgresql"; then
                log_success "PostgreSQL sokli kataloogil on õiged õigused."
            else
                log_warning "PostgreSQL sokli kataloogil pole õigeid õigusi."
                log_info "Proovin õigusi parandada..."
                sudo chmod 775 /var/run/postgresql
                sudo chown postgres:postgres /var/run/postgresql
            fi
        else
            log_warning "PostgreSQL sokli kataloog puudub, proovin luua..."
            sudo mkdir -p /var/run/postgresql
            sudo chmod 775 /var/run/postgresql
            sudo chown postgres:postgres /var/run/postgresql
        fi
    else
        log_warning "PostgreSQL kasutajat ei leitud, mis võib põhjustada probleeme."
    fi
}

fix_common_postgres_issues() {
    log_info "Kontrollin ja parandan levinud PostgreSQL probleeme..."
    
    # Kontrolli, kas postgres kataloogid on olemas ja õigete õigustega
    for dir in "/var/lib/postgresql" "/etc/postgresql"; do
        if [ -d "$dir" ]; then
            log_success "Kataloog $dir on olemas."
        else
            log_warning "Kataloog $dir puudub, mis viitab probleemidele PostgreSQL paigalduses."
            log_info "Proovi täielikult eemaldada ja uuesti installida PostgreSQL:"
            log_info "sudo apt-get purge postgresql* && sudo apt-get install postgresql postgresql-contrib"
            read -p "Kas soovite proovida automaatselt uuesti paigaldada? (j/e): " reinstall_postgres
            if [[ "$reinstall_postgres" == "j" ]]; then
                log_info "Eemaldan PostgreSQL paketi..."
                sudo apt-get purge -y postgresql* && sudo apt-get install -y postgresql postgresql-contrib
                if [ $? -eq 0 ]; then
                    log_success "PostgreSQL edukalt uuesti paigaldatud."
                else
                    log_error "PostgreSQL uuesti paigaldamine ebaõnnestus."
                    return 1
                fi
            fi
        fi
    done
    
    # Kontrolli, kas postgresql teenus on õigesti seadistatud
    if systemctl list-unit-files | grep -q postgresql; then
        log_success "PostgreSQL teenus on süsteemis registreeritud."
    else
        log_warning "PostgreSQL teenust ei leitud süsteemist."
        log_info "Proovin PostgreSQL-i teenuse käivitada ja registreerida..."
        sudo systemctl daemon-reload
        sudo systemctl enable postgresql || true
    fi
    
    return 0
}

restart_postgres() {
    log_info "Taaskäivitan PostgreSQL teenuse..."
    
    sudo systemctl stop postgresql || true
    sudo systemctl start postgresql || {
        log_error "PostgreSQL taaskäivitamine ebaõnnestus."
        
        # Proovi leida teenuse täpne nimi
        postgres_service=$(systemctl list-unit-files | grep -i postgres | head -1 | awk '{print $1}')
        if [ -n "$postgres_service" ]; then
            log_info "Leitud teenus: $postgres_service, proovin seda käivitada..."
            sudo systemctl stop "$postgres_service" || true
            sudo systemctl start "$postgres_service" || {
                log_error "Ka alternatiivse teenuse käivitamine ebaõnnestus."
                return 1
            }
            log_success "PostgreSQL teenus käivitatud kasutades alternatiivset nime."
        else
            # Viimane katse: proovi käivitada pg_ctlcluster käsuga
            pg_version=$(find /etc/postgresql -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1 | xargs basename)
            
            if [ -n "$pg_version" ]; then
                log_info "Leitud PostgreSQL versioon $pg_version, proovin käivitada pg_ctlcluster käsuga..."
                sudo pg_ctlcluster "$pg_version" main start || {
                    log_error "Ka pg_ctlcluster käsuga käivitamine ebaõnnestus."
                    return 1
                }
                log_success "PostgreSQL teenus käivitatud kasutades pg_ctlcluster."
            else
                return 1
            fi
        fi
    }
    
    log_success "PostgreSQL teenus edukalt taaskäivitatud."
    return 0
}

# Kontrolli, kas skript käivitatakse root õigustes
if [[ $EUID -eq 0 ]]; then
    log_warning "See skript ei tohiks käivituda root õigustes. Kasutage tavalist kasutajat sudo õigustega."
    read -p "Kas soovite siiski jätkata? (j/e): " continue_as_root
    if [[ "$continue_as_root" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
fi

# Kontrolli operatsioonisüsteemi
if [[ "$(uname)" != "Linux" ]]; then
    log_error "See skript on mõeldud ainult Linuxi operatsioonisüsteemile."
    exit 1
fi

# Kontrolli vajalikke käske
log_info "Kontrollin vajalikke käske..."
check_command apt-get || {
    log_error "Teie süsteem ei kasuta apt-get paketihaldust. See skript on mõeldud Debiani põhistele süsteemidele."
    exit 1
}

# Kontrolli internetiühendust
check_network

# Kontrolli kettaruumi
check_disk_space

# Küsi kasutaja parameetrid
echo
log_info "Palun sisestage järgnevad parameetrid andmebaasi seadistamiseks:"
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
log_info "Paigalduse kataloog: $INSTALL_DIR"

# Kinnita andmed
echo
log_info "Kontrollige palun üle sisestatud parameetrid:"
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
log_info "Paigaldan vajalikud pakid..."
sudo apt-get update || {
    log_warning "apt-get update ebaõnnestus, kuid proovime jätkata."
}

# Laiendatud vajalike pakettide nimekiri
required_packages=(
    "python3" "python3-pip" "python3-venv" "python3-dev" 
    "python3-full" "python3-psycopg2" "python3-setuptools" 
    "nodejs" "npm" "git" 
    "postgresql" "postgresql-contrib" "postgresql-client"
    "build-essential" "libpq-dev" "curl" "wget"
    "libimage-exiftool-perl" # ExifTool piltide metaandmete jaoks
)

missing_packages=()
for package in "${required_packages[@]}"; do
    if ! dpkg -l | grep -q " $package "; then
        missing_packages+=("$package")
    fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
    log_info "Installin puuduvad paketid: ${missing_packages[*]}"
    sudo apt-get install -y "${missing_packages[@]}" || {
        log_warning "Mõne paketi installimine ebaõnnestus, kuid proovime jätkata."
    }
else
    log_success "Kõik vajalikud paketid on juba installitud."
fi

# Kontrolli Pythoni versiooni
python3_version=$(python3 --version | awk '{print $2}')
python3_major=$(echo "$python3_version" | cut -d. -f1)
python3_minor=$(echo "$python3_version" | cut -d. -f2)

log_info "Leitud Python versioon: $python3_version"
if [ "$python3_major" -lt 3 ] || ([ "$python3_major" -eq 3 ] && [ "$python3_minor" -lt 10 ]); then
    log_warning "Soovitatav on Python 3.10+. Teie versioon võib olla liiga vana."
    read -p "Kas soovite jätkata? (j/e): " continue_python
    if [[ "$continue_python" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
else
    log_success "Python versioon on sobilik (3.10+)."
fi

# Kontrolli NodeJS versiooni
if check_command nodejs; then
    nodejs_version=$(nodejs --version | sed 's/v//')
    nodejs_major=$(echo "$nodejs_version" | cut -d. -f1)
    log_info "Leitud NodeJS versioon: $nodejs_version"
    
    if [ "$nodejs_major" -lt 14 ]; then
        log_warning "Soovitatav on NodeJS 14+. Teie versioon võib olla liiga vana."
        read -p "Kas soovite proovida installida uuem versioon? (j/e): " update_nodejs
        if [[ "$update_nodejs" == "j" ]]; then
            log_info "Installin NodeJS repositooriumi..."
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || {
                log_warning "NodeJS repositooriumi lisamine ebaõnnestus, kuid proovime jätkata olemasoleva versiooniga."
            }
            sudo apt-get install -y nodejs npm || {
                log_warning "NodeJS uuendamine ebaõnnestus, kuid proovime jätkata olemasoleva versiooniga."
            }
        else
            log_info "Jätkan olemasoleva NodeJS versiooniga ($nodejs_version)."
        fi
    else
        log_success "NodeJS versioon on sobilik (14+)."
    fi
else
    log_error "NodeJS ei ole installitud!"
    install_dependency "nodejs" || {
        log_error "NodeJS installimine ebaõnnestus. Frontend ei pruugi töötada."
        read -p "Kas soovite jätkata ilma NodeJS-ita? (j/e): " continue_without_nodejs
        if [[ "$continue_without_nodejs" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
    }
    install_dependency "npm" || log_warning "NPM installimine ebaõnnestus. Frontend ei pruugi töötada."
fi

# Põhjalik PostgreSQL kontrollimine ja parandamine
log_info "Kontrollin PostgreSQL paigaldust..."

# Kontrolli, kas PostgreSQL on installitud
if ! check_command psql; then
    log_warning "PostgreSQL klienti ei leitud, proovin installida..."
    sudo apt-get install -y postgresql postgresql-contrib postgresql-client || {
        log_error "PostgreSQL installimine ebaõnnestus."
        exit 1
    }
fi

# Paranda levinud PostgreSQL probleeme
fix_common_postgres_issues || log_warning "Mõned PostgreSQL probleemid võivad endiselt esineda."

# Kontrolli PostgreSQL sokli seadistust
check_postgres_socket

# Kontrolli PostgreSQL teenuse staatust
log_info "Kontrollin PostgreSQL teenuse staatust..."
if ! systemctl is-active --quiet postgresql; then
    log_warning "PostgreSQL teenus ei ole aktiivne. Käivitan teenuse..."
    if ! restart_postgres; then
        log_error "PostgreSQL teenuse käivitamine ebaõnnestus kõigil viisidel."
        log_info "Proovime viimast võimalust - PostgreSQL täielik uuestipaigaldus..."
        
        read -p "Kas soovite proovida PostgreSQL täielikku uuestipaigaldust? (j/e): " reinstall_postgres
        if [[ "$reinstall_postgres" == "j" ]]; then
            log_info "Eemaldan PostgreSQL paketi..."
            sudo apt-get purge -y postgresql*
            sudo rm -rf /var/lib/postgresql/ /var/log/postgresql/ /etc/postgresql/ /run/postgresql/ 2>/dev/null || true
            
            log_info "Installin PostgreSQL paketi uuesti..."
            sudo apt-get install -y postgresql postgresql-contrib
            
            if ! systemctl is-active --quiet postgresql; then
                sudo systemctl start postgresql || {
                    log_error "PostgreSQL teenuse käivitamine ebaõnnestus ka pärast uuestipaigaldust."
                    log_error "Palun käivitage PostgreSQL teenus käsitsi või vaadake süsteemi logisid vigade leidmiseks."
                    read -p "Kas soovite jätkata ilma töötava PostgreSQL-ita? (j/e): " continue_without_pg
                    if [[ "$continue_without_pg" != "j" ]]; then
                        echo "Skript katkestatud."
                        exit 1
                    fi
                }
            else
                log_success "PostgreSQL teenus edukalt käivitatud pärast uuestipaigaldust."
            fi
        else
            log_error "Palun käivitage PostgreSQL teenus käsitsi või vaadake süsteemi logisid vigade leidmiseks."
            read -p "Kas soovite jätkata ilma töötava PostgreSQL-ita? (j/e): " continue_without_pg
            if [[ "$continue_without_pg" != "j" ]]; then
                echo "Skript katkestatud."
                exit 1
            fi
        fi
    fi
else
    log_success "PostgreSQL teenus on aktiivne."
fi

# Kontrolli, kas PostgreSQL teenus vastab päringutele
log_info "Kontrollin PostgreSQL ühendust..."
MAX_RETRIES=3
retry_count=0
postgres_ok=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$postgres_ok" = false ]; do
    if timeout 5 sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "PostgreSQL ühendus töötab."
        postgres_ok=true
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warning "PostgreSQL ühendus ebaõnnestus. Katse $retry_count/$MAX_RETRIES. Proovin uuesti..."
            restart_postgres
            sleep 3
        fi
    fi
done

if [ "$postgres_ok" = false ]; then
    log_error "Ei õnnestunud PostgreSQL serveriga ühendust luua pärast $MAX_RETRIES katset."
    log_info "Kontrollin teenuse staatust..."
    
    # Kontrolli täpsemat staatust
    systemctl status postgresql --no-pager || {
        log_info "Proovime kontrollida alternatiivset teenust..."
        postgres_service=$(systemctl list-units | grep -i postgres | head -1 | awk '{print $1}')
        if [ -n "$postgres_service" ]; then
            systemctl status "$postgres_service" --no-pager
        fi
    }
    
    echo ""
    log_info "Soovitused probleemi lahendamiseks:"
    echo "1. Kontrollige, kas PostgreSQL on korrektselt paigaldatud:"
    echo "   sudo apt-get install --reinstall postgresql postgresql-contrib"
    echo "2. Taaskäivitage PostgreSQL teenus:"
    echo "   sudo systemctl restart postgresql"
    echo "3. Kontrollige logisid võimalike probleemide leidmiseks:"
    echo "   sudo journalctl -u postgresql"
    echo ""
    read -p "Kas soovite proovida jätkata ilma kohese ühenduse kontrollita? (j/e): " continue_without_pg_check
    if [[ "$continue_without_pg_check" != "j" ]]; then
        echo "Skript katkestatud. Lahendage PostgreSQL probleem ja käivitage skript uuesti."
        exit 1
    fi
    log_warning "Jätkame, kuid andmebaasi tabelite loomine võib hiljem ebaõnnestuda."
fi

# Loo PostgreSQL kasutaja ja andmebaas
log_info "Loon PostgreSQL kasutaja ja andmebaasi..."

# Funktsiooni pgsql käskude proovimiseks
run_postgres_command() {
    local cmd="$1"
    local error_msg="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if sudo -u postgres psql -c "$cmd" 2>/dev/null; then
            return 0
        else
            log_warning "Katse $attempt/$max_attempts: $error_msg"
            attempt=$((attempt + 1))
            if [ $attempt -le $max_attempts ]; then
                log_info "Ootan 2 sekundit ja proovin uuesti..."
                sleep 2
            fi
        fi
    done
    
    log_error "Kõik katsed ebaõnnestusid: $error_msg"
    return 1
}

# Kontrolli, kas kasutaja on juba olemas
if ! run_postgres_command "SELECT 1 FROM pg_user WHERE usename = '$db_user'" "Kasutaja kontrollimine ebaõnnestus"; then
    log_warning "Kasutaja kontrollimise SQL päring ebaõnnestus, kuid proovime jätkata."
    # Proovime igal juhul kasutaja luua või muuta
    if ! run_postgres_command "CREATE USER $db_user WITH PASSWORD '$db_password';" "Kasutaja $db_user loomine ebaõnnestus"; then
        log_warning "Kasutaja loomine ebaõnnestus, proovin muuta olemasolevat kasutajat..."
        run_postgres_command "ALTER USER $db_user WITH PASSWORD '$db_password';" "Kasutaja $db_user parooli muutmine ebaõnnestus" || {
            log_error "Ei õnnestunud kasutajat luua ega muuta."
            read -p "Kas soovite jätkata? (j/e): " continue_anyway
            if [[ "$continue_anyway" != "j" ]]; then
                echo "Skript katkestatud."
                exit 1
            fi
        }
    else
        log_success "Kasutaja $db_user edukalt loodud."
    fi
else
    log_info "Kasutaja $db_user on juba olemas, muudan parooli..."
    run_postgres_command "ALTER USER $db_user WITH PASSWORD '$db_password';" "Kasutaja $db_user parooli muutmine ebaõnnestus" || {
        log_warning "Parooli muutmine ebaõnnestus, kuid proovime jätkata."
    }
fi

# Kontrolli, kas andmebaas on juba olemas
if ! run_postgres_command "SELECT 1 FROM pg_database WHERE datname = '$db_name'" "Andmebaasi kontrollimine ebaõnnestus"; then
    log_warning "Andmebaasi kontrollimise SQL päring ebaõnnestus, kuid proovime jätkata."
    # Proovime igal juhul andmebaasi luua
    if ! run_postgres_command "CREATE DATABASE $db_name OWNER $db_user;" "Andmebaasi $db_name loomine ebaõnnestus"; then
        log_error "Ei õnnestunud andmebaasi luua."
        read -p "Kas soovite jätkata? (j/e): " continue_anyway
        if [[ "$continue_anyway" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
    else
        log_success "Andmebaas $db_name edukalt loodud."
    fi
else
    log_info "Andmebaas $db_name on juba olemas."
    # Võiksime kaaluda ka DROP DATABASE ja CREATE DATABASE, et andmebaas oleks täiesti puhas
    read -p "Kas soovite andmebaasi $db_name tühjendada ja uuesti luua? (j/e): " recreate_db
    if [[ "$recreate_db" == "j" ]]; then
        log_info "Tühjendan andmebaasi $db_name..."
        # Veendu, et ükski aktiivne ühendus ei takistaks andmebaasi kustutamist
        run_postgres_command "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db_name';" "Aktiivsete ühenduste katkestamine ebaõnnestus" || true
        if run_postgres_command "DROP DATABASE $db_name;" "Andmebaasi $db_name kustutamine ebaõnnestus"; then
            if run_postgres_command "CREATE DATABASE $db_name OWNER $db_user;" "Andmebaasi $db_name uuesti loomine ebaõnnestus"; then
                log_success "Andmebaas $db_name edukalt uuesti loodud."
            else
                log_error "Andmebaasi uuesti loomine ebaõnnestus pärast kustutamist!"
                exit 1
            fi
        else
            log_warning "Andmebaasi kustutamine ebaõnnestus, jätkame olemasoleva andmebaasiga."
        fi
    fi
fi

# Anna superuser õigused
run_postgres_command "ALTER USER $db_user WITH SUPERUSER;" "Kasutajale $db_user superuser õiguste andmine ebaõnnestus" || {
    log_warning "Superuser õiguste andmine ebaõnnestus, kuid proovime jätkata."
}

# Muuda PostgreSQL pordi seadistust, kui kasutaja määras muu pordi kui vaikimisi
if [[ "$db_port" != "5432" ]]; then
    log_info "Muudan PostgreSQL pordi seadistust ($db_port)..."
    postgres_conf_path=$(sudo -u postgres psql -c "SHOW config_file;" 2>/dev/null | grep "postgresql.conf")
    
    if [[ -z "$postgres_conf_path" ]]; then
        # Proovi leida alternatiivne tee
        log_info "Otsin PostgreSQL konfiguratsioonifaili..."
        if check_command pg_config; then
            postgres_version=$(pg_config --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "")
        else
            postgres_version=""
        fi
        
        if [ -z "$postgres_version" ]; then
            # Proovi leida versioonikataloog /etc/postgresql/ alt
            postgres_version=$(find /etc/postgresql -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r | head -n 1 | xargs basename 2>/dev/null || echo "")
        fi
        
        if [ -n "$postgres_version" ]; then
            postgres_conf_path="/etc/postgresql/$postgres_version/main/postgresql.conf"
            log_info "Leitud võimalik konfiguratsioonifail: $postgres_conf_path"
        else
            # Otsi konfiguratsioonifaili üle kogu süsteemi
            log_info "Otsin PostgreSQL konfiguratsioonifaili üle süsteemi..."
            postgres_conf_path=$(sudo find /etc -name "postgresql.conf" -type f 2>/dev/null | head -1)
        fi
    fi

    if [[ -f "$postgres_conf_path" ]]; then
        # Tee varukoopia
        sudo cp "$postgres_conf_path" "${postgres_conf_path}.bak" || {
            log_warning "Ei õnnestunud teha varukoopiat PostgreSQL konfiguratsioonifailist."
        }
        
        # Muuda konfiguratsiooni
        log_info "Uuendan pordi seadistust failis $postgres_conf_path..."
        sudo sed -i "s/^#\?port = .*/port = $db_port/" "$postgres_conf_path" || {
            log_error "PostgreSQL pordi seadistuse muutmine ebaõnnestus."
            log_warning "Võimalik, et peate muutma pordi seadistust käsitsi."
        }
        
        # Muuda ka listen_addresses, et veenduda, et server kuulab ühendusi
        if sudo grep -q "^#listen_addresses" "$postgres_conf_path"; then
            log_info "Aktiveerin listen_addresses seadistuse..."
            sudo sed -i "s/^#listen_addresses.*/listen_addresses = 'localhost'/" "$postgres_conf_path" || log_warning "listen_addresses seadistuse muutmine ebaõnnestus."
        fi
        
        # Taaskäivita PostgreSQL
        log_info "Taaskäivitan PostgreSQL teenuse uute seadistustega..."
        if ! restart_postgres; then
            log_error "PostgreSQL teenuse taaskäivitamine ebaõnnestus."
            read -p "Kas soovite jätkata? (j/e): " continue_anyway
            if [[ "$continue_anyway" != "j" ]]; then
                echo "Skript katkestatud."
                exit 1
            fi
        fi
        
        # Kontrolli, kas uus port on aktiivne
        log_info "Kontrollin, kas PostgreSQL kuulab pordil $db_port..."
        if sudo ss -tunlp | grep -q ":$db_port.*LISTEN.*postgres"; then
            log_success "PostgreSQL kuulab edukalt pordil $db_port."
        else
            log_warning "PostgreSQL ei kuula pordil $db_port, mis võib põhjustada ühendusprobleeme."
            
            if [ "$db_port" != "5432" ]; then
                log_info "Proovime tagasi minna vaikimisi pordile 5432..."
                db_port="5432"
                log_warning "Pordi muutmine ebaõnnestus. Kasutame vaikimisi porti 5432."
            fi
        fi
    else
        log_error "PostgreSQL konfiguratsioonifaili ei leitud. Pordi muutmine ebaõnnestus."
        log_info "Otsitud asukohtadest: /etc/postgresql/*/main/postgresql.conf"
        read -p "Kas soovite jätkata vaikimisi pordiga 5432? (j/e): " continue_without_port_change
        if [[ "$continue_without_port_change" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
        db_port="5432"
        log_warning "Pordi muutmine ebaõnnestus. Kasutame vaikimisi porti 5432."
    fi
fi

# Uuenda andmebaasi konfiguratsioonifaili õigete parameetritega
log_info "Uuendan andmebaasi konfiguratsiooni..."

# Veendu, et backend kataloog oleks olemas
if [ ! -d "backend" ]; then
    log_error "Backend kataloogi ei leitud. Veenduge, et olete õiges kaustas."
    exit 1
fi

# Loo .env fail andmebaasi seadistustega
log_info "Loon .env faili backend kataloogi..."
env_file="backend/.env"
mkdir -p backend
cat > "$env_file" << EOL
# Andmebaasi seadistused
DB_USER=$db_user
DB_PASSWORD=$db_password
DB_HOST=localhost
DB_PORT=$db_port
DB_NAME=$db_name
EOL

log_success "Loodud .env fail andmebaasi seadistustega."

# Varuvariandina uuendame ka database.py faili otsest ühendusstring'i
db_config_file="backend/database.py"
if [[ -f "$db_config_file" ]]; then
    # Varunda originaal
    cp "$db_config_file" "${db_config_file}.bak" || {
        log_warning "Ei õnnestunud teha varukoopiat andmebaasi konfiguratsioonifailist."
    }
    
    # Uuenda konfiguratsiooni, kui kasutatakse vana formaati
    if grep -q "DATABASE_URL = \"postgresql://" "$db_config_file"; then
        log_info "Uuendan legacy andmebaasi ühendusstring'i..."
        sed -i "s|DATABASE_URL = \"postgresql://.*@localhost:[0-9]*/.*\"|DATABASE_URL = \"postgresql://${db_user}:${db_password}@localhost:${db_port}/${db_name}\"|g" "$db_config_file" || {
            log_error "Andmebaasi konfiguratsiooni uuendamine ebaõnnestus."
            log_info "Proovime faili käsitsi redigeerida..."
            
            # Kogu faili sisu
            db_file_content=$(cat "$db_config_file")
            
            # Otsi ja asenda ühendusstring regulaaravaldisega
            new_db_file_content=$(echo "$db_file_content" | sed "s|DATABASE_URL = \"postgresql://[^\"]*\"|DATABASE_URL = \"postgresql://${db_user}:${db_password}@localhost:${db_port}/${db_name}\"|g")
            
            # Kirjuta uus sisu faili
            echo "$new_db_file_content" > "$db_config_file"
            
            if [ $? -ne 0 ]; then
                log_error "Andmebaasi konfiguratsioonifaili käsitsi uuendamine ebaõnnestus."
                exit 1
            else
                log_success "Andmebaasi konfiguratsioonifail edukalt uuendatud alternatiivse meetodiga."
            fi
        }
    else
        log_success "Kasutusele on võetud keskkonna muutujad andmebaasi seadistusteks - .env fail on loodud."
    fi
else
    log_error "Andmebaasi konfiguratsioonifaili ei leitud."
    log_info "Proovin leida backend kaustas olevaid Pythoni faile..."
    python_files=$(find backend -name "*.py" | grep -v __pycache__ | xargs grep -l "postgresql" 2>/dev/null || echo "")
    
    if [ -n "$python_files" ]; then
        log_info "Leitud võimalikud konfiguratsioonifailid, mis sisaldavad PostgreSQL ühenduse seadistusi:"
        echo "$python_files"
        log_info "Palun kontrollige neid faile ja vajadusel uuendage andmebaasi ühenduse parameetrid käsitsi."
    fi
    
    read -p "Kas soovite jätkata ilma andmebaasi konfiguratsioonifaili uuendamata? (j/e): " continue_without_config
    if [[ "$continue_without_config" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
fi

# Seadista ja käivita backend
log_info "Seadistan backend'i..."
cd backend || {
    log_error "Ei õnnestunud liikuda backend kataloogi."
    exit 1
}

# Kontrolli, kas python3-full on installitud (vajalik virtuaalkeskkonna jaoks)
if ! dpkg -l | grep -q python3-full; then
    log_info "Python3-full pakett pole installitud. Proovin installida..."
    sudo apt-get install -y python3-full || {
        log_warning "Python3-full paketi installimine ebaõnnestus."
        log_warning "Virtuaalkeskkonna loomine võib ebaõnnestuda."
    }
fi

# Virtuaalkeskkonna seadistamine
log_info "Seadistan Python virtuaalkeskkonda..."
if [ ! -d "venv" ]; then
    log_info "Loon uue virtuaalkeskkonna..."
    # Veendu, et python3-venv on installitud
    if ! dpkg -l | grep -q python3-venv; then
        log_info "Python3-venv pakett pole installitud. Proovin installida..."
        sudo apt-get install -y python3-venv || {
            log_error "python3-venv paketi installimine ebaõnnestus."
            log_info "Proovi käsitsi: sudo apt-get install python3-venv"
            exit 1
        }
    fi
    
    # Loo virtuaalkeskkond
    python3 -m venv venv || {
        log_error "Pythoni virtuaalkeskkonna loomine ebaõnnestus."
        log_info "Proovime alternatiivset meetodit..."
        
        # Proovi --without-pip lipuga
        log_info "Proovin luua virtuaalkeskkonda ilma pip-ita..."
        python3 -m venv venv --without-pip
        
        if [ -d "venv" ]; then
            log_success "Virtuaalkeskkond loodud --without-pip lipuga."
            log_info "Paigaldan pip käsitsi..."
            source venv/bin/activate
            curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
            python get-pip.py
            rm get-pip.py
        else
            log_error "Ka alternatiivne virtuaalkeskkonna loomine ebaõnnestus."
            log_info "Proovi käsitsi järgmisi käske:"
            log_info "  sudo apt-get install python3-venv python3-full"
            log_info "  python3 -m venv venv"
            exit 1
        fi
    }
else
    log_info "Kasutan olemasolevat virtuaalkeskkonda."
    # Võiksime kaaluda vana virtuaalkeskkonna uuendamist
    read -p "Kas soovite olemasoleva virtuaalkeskkonna uuesti luua? (j/e): " recreate_venv
    if [[ "$recreate_venv" == "j" ]]; then
        log_info "Eemaldan vana virtuaalkeskkonna..."
        rm -rf venv
        log_info "Loon uue virtuaalkeskkonna..."
        python3 -m venv venv || {
            log_error "Pythoni virtuaalkeskkonna loomine ebaõnnestus."
            log_info "Proovi käsitsi järgmisi käske:"
            log_info "  sudo apt-get install python3-venv python3-full"
            log_info "  python3 -m venv venv"
            exit 1
        }
    fi
fi

# Kontrolli, kas pip on virtuaalkeskkonnas olemas
if [ ! -f "venv/bin/pip" ] && [ ! -f "venv/bin/pip3" ]; then
    log_warning "Pip ei ole virtuaalkeskkonnas saadaval."
    log_info "Proovin taastada virtuaalkeskkonda..."
    rm -rf venv
    python3 -m venv venv --clear || {
        log_error "Virtuaalkeskkonna taastamine ebaõnnestus."
        log_info ""
        log_info "Proovige käsitsi järgmisi käske:"
        log_info "  rm -rf venv"
        log_info "  python3 -m venv venv"
        exit 1
    }
    
    # Kui ikka ei õnnestu, proovime pip käsitsi paigaldada
    if [ ! -f "venv/bin/pip" ] && [ ! -f "venv/bin/pip3" ]; then
        log_info "Proovin paigaldada pip käsitsi virtuaalkeskkonda..."
        source venv/bin/activate
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python get-pip.py
        rm get-pip.py
    fi
fi

# Aktiveeri virtuaalkeskkond
log_info "Aktiveerin virtuaalkeskkonna..."
source venv/bin/activate || {
    log_error "Pythoni virtuaalkeskkonna aktiveerimine ebaõnnestus."
    exit 1
}

# Uuenda pip virtuaalkeskkonnas
log_info "Uuendan pip-i virtuaalkeskkonnas..."
python -m pip install --upgrade pip || {
    log_warning "Pip-i uuendamine ebaõnnestus, kuid jätkan."
}

# Veendu, et vajalikud arenduspaketid on installitud
log_info "Kontrollin, kas vajalikud arenduspaketid on installitud..."
for dev_pkg in "python3-dev" "build-essential" "libpq-dev"; do
    if ! dpkg -l | grep -q "$dev_pkg"; then
        log_info "Paigaldan vajaliku arenduspaketi: $dev_pkg"
        sudo apt-get install -y "$dev_pkg" || log_warning "$dev_pkg paigaldamine ebaõnnestus, kuid proovime jätkata."
    fi
done

# Kontrolli requirements.txt olemasolu
if [ ! -f "requirements.txt" ]; then
    log_error "requirements.txt faili ei leitud backend kataloogis."
    log_info "Loon minimaalse requirements.txt faili, mis sisaldab olulisi sõltuvusi..."
    
    cat > requirements.txt << EOL
fastapi>=0.95.0
uvicorn>=0.21.0
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.6
python-dotenv>=1.0.0
python-multipart>=0.0.6
pydantic>=2.0.0
EOL
    
    log_success "Loodud minimaalse requirements.txt fail."
fi

# Paigalda sõltuvused
log_info "Installin Python sõltuvused virtuaalkeskkonnas..."

# Proovime erinevaid meetodeid sõltuvuste paigaldamiseks
install_success=false
install_methods=(
    "python -m pip install -r requirements.txt"
    "python -m pip install --break-system-packages -r requirements.txt"
    "pip install -r requirements.txt"
    "pip install --no-cache-dir -r requirements.txt"
)

for method in "${install_methods[@]}"; do
    log_info "Proovin paigaldamismeetodit: $method"
    if eval "$method"; then
        install_success=true
        log_success "Sõltuvused edukalt paigaldatud kasutades meetodit: $method"
        break
    else
        log_warning "Paigaldamismeetod ebaõnnestus: $method"
    fi
done

if [ "$install_success" = false ]; then
    log_error "Kõik Pythoni sõltuvuste paigaldamise meetodid ebaõnnestusid."
    log_info ""
    log_info "Detailsed sammud probleemi lahendamiseks käsitsi:"
    log_info "1. Mine backend kataloogi: cd $INSTALL_DIR/backend"
    log_info "2. Loo virtuaalkeskkond: python3 -m venv venv"
    log_info "3. Aktiveeri virtuaalkeskkond: source venv/bin/activate"
    log_info "4. Uuenda pip: pip install --upgrade pip"
    log_info "5. Installeeri sõltuvused: pip install -r requirements.txt"
    log_info ""
    log_info "Veateade:"
    python -m pip install -r requirements.txt
    
    read -p "Kas soovite proovida jätkata ilma kõigi sõltuvuste edukata paigaldamiseta? (j/e): " continue_without_deps
    if [[ "$continue_without_deps" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
fi

# Proovi paigaldada põhilised sõltuvused eraldi, kui terve requirements.txt paigaldamine ebaõnnestus
if [ "$install_success" = false ]; then
    log_info "Proovin paigaldada põhilised sõltuvused eraldi..."
    core_deps=("sqlalchemy" "fastapi" "uvicorn" "psycopg2-binary" "psycopg2" "python-dotenv" "pydantic")
    
    for dep in "${core_deps[@]}"; do
        log_info "Paigaldan sõltuvuse: $dep"
        python -m pip install "$dep" || log_warning "$dep paigaldamine ebaõnnestus, kuid proovime jätkata."
    done
fi

# Loo andmebaasi tabelid
log_info "Proovin luua andmebaasi tabeleid..."
python create_tables.py || {
    log_error "Andmebaasi tabelite loomine ebaõnnestus."
    log_info "Kontrollin täpsemat viga..."
    
    # Proovi väljundada täpsem viga
    python -c "
import sys
sys.path.append('.')
try:
    from database import engine
    from models import Base
    print('Ühendus andmebaasiga õnnestus.')
    try:
        Base.metadata.create_all(bind=engine)
        print('Tabelite loomine õnnestus.')
    except Exception as e:
        print(f'Tabelite loomine ebaõnnestus: {e}')
except Exception as e:
    print(f'Ühendus andmebaasiga ebaõnnestus: {e}')
" || log_warning "Ka täpsema vea väljastamine ebaõnnestus."
    
    read -p "Kas soovite proovida andmebaasi tabeleid luua hiljem käsitsi? (j/e): " continue_without_tables
    if [[ "$continue_without_tables" != "j" ]]; then
        echo "Skript katkestatud."
        exit 1
    fi
}

# Liigu tagasi projekti juurkataloogi
cd ..

# Seadista ja käivita frontend
log_info "Seadistan frontend'i..."
cd frontend || {
    log_error "Ei õnnestunud liikuda frontend kataloogi."
    exit 1
}

# Kontrolli, kas package.json on olemas
if [ ! -f "package.json" ]; then
    log_error "package.json faili ei leitud frontend kataloogis. Frontend seadistamine võib ebaõnnestuda."
    log_info "Proovin luua minimaalse package.json faili..."
    
    # Loo minimaalse sisuga package.json fail
    cat > package.json << EOL
{
  "name": "nature-photo-db-frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "axios": "^1.3.5"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOL
    
    log_success "Loodud minimaalse package.json fail."
fi

# Kontrolli, kas npm on installitud ja töötab
if ! check_command npm; then
    log_error "NPM ei ole installitud või ei tööta."
    log_info "Proovin uuesti installida Node.js ja NPM..."
    
    # Proovi uuesti installida node.js ja npm
    sudo apt-get install -y nodejs npm || {
        log_error "Node.js ja NPM installimine ebaõnnestus."
        read -p "Kas soovite jätkata ilma frontendi seadistamiseta? (j/e): " continue_without_frontend
        if [[ "$continue_without_frontend" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
        
        # Liigu tagasi projekti juurkataloogi ilma frontendi seadistamata
        cd ..
        # Märgi, et frontend pole paigaldatud
        frontend_installed=false
    }
fi

frontend_installed=true

if [ "$frontend_installed" = true ]; then
    # Paigalda sõltuvused
    log_info "Installin NPM sõltuvused..."
    npm_install_success=false
    
    # Proovi erinevaid meetodeid npm sõltuvuste paigaldamiseks
    npm_methods=("npm install" "npm install --legacy-peer-deps" "npm install --force")
    
    for method in "${npm_methods[@]}"; do
        log_info "Proovin paigaldamismeetodit: $method"
        if eval "$method"; then
            npm_install_success=true
            log_success "NPM sõltuvused edukalt paigaldatud kasutades meetodit: $method"
            break
        else
            log_warning "NPM paigaldamismeetod ebaõnnestus: $method"
        fi
    done
    
    if [ "$npm_install_success" = false ]; then
        log_error "Kõik NPM sõltuvuste paigaldamise meetodid ebaõnnestusid."
        read -p "Kas soovite jätkata ilma frontendi sõltuvuste edukata paigaldamiseta? (j/e): " continue_without_npm
        if [[ "$continue_without_npm" != "j" ]]; then
            echo "Skript katkestatud."
            exit 1
        fi
    fi
    
    # Liigu tagasi projekti juurkataloogi
    cd ..
else
    log_warning "Frontend'i seadistamine jäi vahele."
fi

# Uuenda start_servers.sh skriptis projekti kataloogi tee
log_info "Uuendan start_servers.sh skripti projekti kataloogi teega..."
start_script="start_servers.sh"
if [[ -f "$start_script" ]]; then
    # Varunda originaal
    cp "$start_script" "${start_script}.bak" || {
        log_warning "Ei õnnestunud teha varukoopiat $start_script failist."
    }
    
    # Uuenda projekti kataloogi tee
    sed -i "s|PROJECT_DIR=\".*\"|PROJECT_DIR=\"$INSTALL_DIR\"|g" "$start_script" || {
        log_warning "start_servers.sh skripti uuendamine ebaõnnestus."
        log_info "Võite käsitsi uuendada PROJECT_DIR muutujat $start_script failis."
    }
    log_success "start_servers.sh on uuendatud õige projekti kataloogiga."
else
    log_warning "start_servers.sh faili ei leitud. Serveri käivitamine võib ebaõnnestuda."
    log_info "Loon lihtsa start_servers.sh skripti..."
    
    cat > start_servers.sh << EOL
#!/bin/bash

# Looduspiltide-Andmebaas käivitusskript
PROJECT_DIR="$INSTALL_DIR"

# Funktsioonid
start_backend() {
    echo "Käivitan backend serveri..."
    cd "\$PROJECT_DIR/backend"
    source venv/bin/activate
    nohup uvicorn main:app --reload --host 0.0.0.0 --port 8000 > server.log 2>&1 &
    echo "Backend server käivitatud. Logifail: \$PROJECT_DIR/backend/server.log"
}

start_frontend() {
    echo "Käivitan frontend serveri..."
    cd "\$PROJECT_DIR/frontend"
    nohup npm start > server.log 2>&1 &
    echo "Frontend server käivitatud. Logifail: \$PROJECT_DIR/frontend/server.log"
}

# Käivita mõlemad serverid
start_backend
start_frontend

echo "Mõlemad serverid on käivitatud. Rakendus on kättesaadav aadressil http://localhost:3000"
EOL
    
    chmod +x start_servers.sh
    log_success "start_servers.sh skript loodud."
fi

# Tee käivitusskript käivitatavaks
chmod +x start_servers.sh || {
    log_warning "Käivitusskripti käivitatavaks tegemine ebaõnnestus."
    log_info "Proovige käsitsi: chmod +x start_servers.sh"
}

# Loo vajalikud kaustad, kui neid veel pole
log_info "Loon vajalikud kaustad..."
mkdir -p file_storage || {
    log_warning "Piltide salvestuskataloogi loomine ebaõnnestus."
    log_info "Proovige käsitsi: mkdir -p file_storage"
}

# Kinnita, et kõik vajalikud õigused on olemas
log_info "Annan vajalikud õigused kataloogidele..."
chmod -R 755 file_storage || log_warning "Piltide salvestuskataloogi õiguste muutmine ebaõnnestus."

# Lõpetuseks
echo
echo "============================================================="
echo -e "${GREEN}  Paigaldus on lõpetatud!${NC}"
echo "============================================================="
echo
echo -e "Käivitage rakendus käsuga:"
echo -e "  ${BLUE}cd $INSTALL_DIR && ./start_servers.sh${NC}"
echo
echo -e "Backend käivitub aadressil: ${BLUE}http://localhost:8000${NC}"
echo -e "Frontend käivitub aadressil: ${BLUE}http://localhost:3000${NC}"
echo
echo -e "${GREEN}Täname, et kasutate Looduspiltide Andmebaasi!${NC}"
echo "============================================================="

# Anna kasulikud juhised, kui midagi läks valesti
if [ "$postgres_ok" = false ] || [ "$install_success" = false ] || [ "$frontend_installed" = false ]; then
    echo
    echo -e "${YELLOW}Märkus: Paigalduse ajal esines mõningaid probleeme:${NC}"
    
    if [ "$postgres_ok" = false ]; then
        echo -e "- PostgreSQL ühendusega oli probleeme. Veenduge, et PostgreSQL teenus töötab."
        echo -e "  Käivitage: ${BLUE}sudo systemctl status postgresql${NC}"
        echo -e "  Taaskäivitamiseks: ${BLUE}sudo systemctl restart postgresql${NC}"
    fi
    
    if [ "$install_success" = false ]; then
        echo -e "- Pythoni sõltuvuste paigaldamisega oli probleeme. Proovige käsitsi paigaldada."
        echo -e "  Käivitage: ${BLUE}cd $INSTALL_DIR/backend && source venv/bin/activate && pip install -r requirements.txt${NC}"
    fi
    
    if [ "$frontend_installed" = false ]; then
        echo -e "- Frontend'i seadistamine ebaõnnestus. Proovige käsitsi paigaldada."
        echo -e "  Käivitage: ${BLUE}cd $INSTALL_DIR/frontend && npm install${NC}"
    fi
    
    echo
    echo -e "Kui rakenduse käivitamisel esineb probleeme, vaadake logi faile:"
    echo -e "- Backend logi: ${BLUE}$INSTALL_DIR/backend/server.log${NC}"
    echo -e "- Frontend logi: ${BLUE}$INSTALL_DIR/frontend/server.log${NC}"
    echo
fi