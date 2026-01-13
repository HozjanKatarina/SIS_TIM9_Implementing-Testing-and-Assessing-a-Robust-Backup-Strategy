#!/usr/bin/env bash
set -euo pipefail

DB_OS_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
TEST_DB="dvdrental_restore_test"
EXPECTED_FILE="/home/kali/db_expected_values.conf"
REPORT_DIR="/var/log/pg-backup-verify"
DEFAULT_DUMP="/home/kali/radni_podaci/database_dumps/dvdrental_backup.dump"

mkdir -p "$REPORT_DIR"
TS="$(date +'%Y-%m-%d_%H-%M-%S')"
REPORT="$REPORT_DIR/verify_${TS}.log"

log() { echo "[$(date +'%F %T')] $*" | tee -a "$REPORT" ; }

DUMP_FILE="${1:-$DEFAULT_DUMP}"
DO_RESTORE_TEST="0"
DO_HASH="0"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-test) DO_RESTORE_TEST="1" ;;
    --hash) DO_HASH="1" ;;
    *) log "WARN: Nepoznata opcija: $1" ;;
  esac
  shift
done

run_pg() {
  sudo -n -u "$DB_OS_USER" PGPASSWORD='postgres' "$@"
}

load_expected() {
  MIN_FILM=1
  MIN_CUSTOMER=1
  MIN_RENTAL=1

  if [[ -f "$EXPECTED_FILE" ]]; then
    source "$EXPECTED_FILE"
  fi
}

log "=== START VERIFY ==="
log "Dump file: $DUMP_FILE"

if [[ ! -f "$DUMP_FILE" ]]; then
  log "FAIL(2): Dump ne postoji."
  exit 2
fi

if [[ ! -s "$DUMP_FILE" ]]; then
  log "FAIL(2): Dump je prazan."
  exit 2
fi

if ! run_pg pg_restore -l "$DUMP_FILE" > /dev/null; then
  log "FAIL(2): pg_restore ne može pročitati dump (loš format)."
  exit 2
fi
log "OK: Tehnička ispravnost dumpa potvrđena."

if [[ "$DO_HASH" == "1" ]]; then
  SHA_FILE="${DUMP_FILE}.sha256"
  sha256sum "$DUMP_FILE" | tee "$SHA_FILE" >> "$REPORT"
  log "OK: SHA256 zapisan."
fi

if [[ "$DO_RESTORE_TEST" == "1" ]]; then
  load_expected
  log "[5] Restore test na bazi: $TEST_DB"

  run_pg dropdb --if-exists "$TEST_DB" >/dev/null 2>&1 || true
  run_pg createdb "$TEST_DB"

  if ! run_pg pg_restore -d "$TEST_DB" "$DUMP_FILE"; then
    log "FAIL(3): Restore nije uspio."
    run_pg dropdb --if-exists "$TEST_DB" >/dev/null 2>&1 || true
    exit 3
  fi

  FILM_COUNT="$(run_pg psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TEST_DB" -Atc "SELECT COUNT(*) FROM film;")"
  CUSTOMER_COUNT="$(run_pg psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TEST_DB" -Atc "SELECT COUNT(*) FROM customer;")"
  RENTAL_COUNT="$(run_pg psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TEST_DB" -Atc "SELECT COUNT(*) FROM rental;")"

  NULL_CUSTOMERS_IN_RENTAL="$(run_pg psql -d "$TEST_DB" -Atc "SELECT COUNT(*) FROM rental WHERE customer_id IS NULL;")"
  DATE_RANGE="$(run_pg psql -d "$TEST_DB" -Atc "SELECT COALESCE(MIN(rental_date)::date::text,'NULL') || ' .. ' || COALESCE(MAX(rental_date)::date::text,'NULL') FROM rental;")"

  log "Counts: film=$FILM_COUNT, customer=$CUSTOMER_COUNT, rental=$RENTAL_COUNT"
  log "Sanity: Null customers=$NULL_CUSTOMERS_IN_RENTAL, Range=$DATE_RANGE"

  if [[ "$FILM_COUNT" -lt "$MIN_FILM" || "$CUSTOMER_COUNT" -lt "$MIN_CUSTOMER" || "$RENTAL_COUNT" -lt "$MIN_RENTAL" ]]; then
    log "FAIL(4): Nedovoljan broj zapisa u tablicama."
    exit 4
  fi

  if [[ "$NULL_CUSTOMERS_IN_RENTAL" -ne 0 ]] || [[ "$DATE_RANGE" == "NULL .. NULL" ]]; then
    log "FAIL(4): Semantička provjera podataka nije prošla."
    exit 4
  fi

  run_pg dropdb --if-exists "$TEST_DB"
  log "OK: Semantička provjera uspješna."
fi

log "=== VERIFY OK ==="
exit 0
