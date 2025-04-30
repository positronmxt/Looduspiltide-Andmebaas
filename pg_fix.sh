#!/bin/bash
# pg_fix.sh - PostgreSQL probleemide diagnoosimine ja parandamine

echo "PostgreSQL teenuse diagnostika..."

# Kontrolli staatust
echo "Kontrollin PostgreSQL teenuse staatust..."
sudo systemctl status postgresql

# Kontrolli versiooni ja klastreid
echo "Kontrollin PostgreSQL klastreid..."
pg_lsclusters

# Kui klastrid puuduvad, proovi luua
if [ -z "$(pg_lsclusters)" ]; then
    echo "PostgreSQL klastreid ei leitud! Proovime luua uue klastri..."
    
    # Leia installitud PostgreSQL versioon
    pg_version=$(ls -1 /usr/lib/postgresql/ 2>/dev/null | sort -V | tail -n1)
    
    if [ -n "$pg_version" ]; then
        echo "Leitud PostgreSQL versioon: $pg_version"
        echo "Loon uue klastri..."
        sudo pg_createcluster $pg_version main --start
        
        # Kontrolli, kas klaster loodi edukalt
        if pg_lsclusters | grep -q "online"; then
            echo "PostgreSQL klaster edukalt loodud ja käivitatud!"
        else
            echo "PostgreSQL klastri loomine ebaõnnestus."
        fi
    else
        echo "PostgreSQL versiooni ei leitud. Kas PostgreSQL on installitud?"
    fi
fi

# Kontrolli logisid
echo "PostgreSQL logid:"
sudo journalctl -u postgresql --since "1 hour ago" | tail -n 20

# Proovi taaskäivitada
echo "Proovin PostgreSQL teenust taaskäivitada..."
sudo systemctl restart postgresql

# Kontrolli uuesti staatust
echo "Uus PostgreSQL teenuse staatus:"
sudo systemctl status postgresql

# Näita ühenduse info
echo "PostgreSQL ühenduse info:"
pg_isready -h localhost

# Kui staatus on "active (exited)", siis proovi täiendavat lahendust
if systemctl status postgresql | grep -q "active (exited)"; then
    echo "PostgreSQL on staatuses 'active (exited)'. See viitab probleemile."
    echo "Proovin täiendavat lahendust..."
    
    # Proovi klastrit käivitada otse
    pg_version=$(pg_lsclusters | awk 'NR>1 {print $1; exit}')
    if [ -n "$pg_version" ]; then
        echo "Käivitan klastri manuaalselt..."
        sudo pg_ctlcluster $pg_version main start
    else
        echo "Ei leidnud ühtegi PostgreSQL klastrit."
        echo "Proovime ainult daemoni taaskäivitada:"
        sudo systemctl restart postgresql
    fi
    
    # Kontrolli staatust pärast manuaalset käivitamist
    echo "Staatus pärast manuaalset käivitamist:"
    sudo systemctl status postgresql
fi

# Kontrolli, kas vaikimisi postgres kasutaja on loodud
if ! id -u postgres &>/dev/null; then
    echo "Postgres kasutajat ei leitud! See on ebatavaline."
    echo "Proovime parandada..."
    sudo useradd -r -m -d /var/lib/postgresql -s /bin/bash postgres
    echo "Postgres kasutaja loodud."
fi

# Kontrolli õigusi andmekaustadele
echo "Kontrollin PostgreSQL andmekaustade õigusi..."
for dir in /var/lib/postgresql /etc/postgresql /var/run/postgresql; do
    if [ -d "$dir" ]; then
        echo "$dir: $(ls -la $dir | head -n 2)"
        if [ "$(stat -c '%U' $dir)" != "postgres" ]; then
            echo "Parandan õigusi kaustal $dir..."
            sudo chown -R postgres:postgres $dir
        fi
    else
        echo "$dir ei eksisteeri!"
    fi
done

echo "PostgreSQL diagnostika on lõppenud."
echo "Kui probleem püsib, proovige järgmist:"
echo "1. sudo apt-get purge postgresql* --auto-remove"
echo "2. sudo apt-get install postgresql postgresql-contrib"
echo "3. sudo systemctl start postgresql"