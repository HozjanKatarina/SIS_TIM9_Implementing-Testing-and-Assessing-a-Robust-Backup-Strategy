#!/bin/bash
set -euo pipefail

LEVEL=$1
POOL=${2:-"None"}
LOG_FILE="/var/log/duplicity_bacula.log"

export HOME="/var/lib/bacula"
export PASSPHRASE="kali-backup"
export GPG_KEY_ID="01116997692469C7"
BACKUP_SRC="/home/kali/radni_podaci/"
CACHE_DIR="/var/lib/bacula/.cache/duplicity"
SSH_OPTS="--ssh-options=-o BatchMode=yes -o StrictHostKeyChecking=no"

DEST_SUBFOLDER=$(echo "$POOL" | tr '[:upper:]' '[:lower:]' | sed 's/-job//g')
BACKUP_DEST="scp://vbox:vbox@10.0.2.4//home/vbox/backup/$DEST_SUBFOLDER"

exec > >(tee -a "$LOG_FILE") 2>&1

run_postgres_dump() {
    DUMP_DIR="${BACKUP_SRC}database_dumps/"
    mkdir -p "$DUMP_DIR"
    export PGPASSWORD='postgres'
    pg_dump -h localhost -U postgres -Fc dvdrental > "${DUMP_DIR}dvdrental_backup.dump"
    sudo chown -R kali:kali "$DUMP_DIR"
    unset PGPASSWORD
}

echo "--- START: $LEVEL za $POOL ---"

case "$LEVEL" in
    "Full")
        run_postgres_dump
        
        echo "Izvršavam glavni Full backup u $BACKUP_DEST..."
        /usr/bin/duplicity full --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"

        if [[ "$POOL" == *"Father"* ]] || [[ "$POOL" == *"Grandfather"* ]]; then
            [[ "$POOL" == *"Demo"* ]] && TARGET="demo-son" || TARGET="son"
            SON_DEST="scp://vbox:vbox@10.0.2.4//home/vbox/backup/$TARGET"
            
            echo "Prepisujem Full backup u $TARGET..."
            /usr/bin/duplicity full --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
              --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$SON_DEST"
        fi
        ;;

    "Incremental")
        /usr/bin/duplicity incremental --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"
        ;;

    "Restore")
        TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
        RESTORE_PATH="/home/kali/Restore_Test/${POOL}_${TIMESTAMP}"
        mkdir -p "$RESTORE_PATH"
        /usr/bin/duplicity restore --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_DEST" "$RESTORE_PATH"
        ;;
esac

echo "--- PROVJERA RETENTION POLITIKE ---"

if [[ "$POOL" == "Demo-Son" ]]; then
    /usr/bin/duplicity remove-all-inc-of-but-n-full 1 --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    /usr/bin/duplicity remove-older-than 2m --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"

elif [[ "$POOL" == "Son" ]]; then
    /usr/bin/duplicity remove-all-inc-of-but-n-full 2 --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    /usr/bin/duplicity remove-older-than 30D --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    
elif [[ "$POOL" == "Demo-Father" ]]; then
    /usr/bin/duplicity remove-older-than 10m --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    
elif [[ "$POOL" == "Father" ]]; then
    /usr/bin/duplicity remove-older-than 1Y --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
fi

echo "--- KRAJ: $(date) ---"
