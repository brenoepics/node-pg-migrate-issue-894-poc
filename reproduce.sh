#!/usr/bin/env bash
# Reproduces salsita/node-pg-migrate#894 from scratch. See README.md for the why.
# Steps 2 and 4 are supposed to fail: that is the bug.
set -uo pipefail
cd "$(dirname "$0")"

export DATABASE_URL=postgres://app_user:app_password@localhost:54894/app

step() { printf '\n== %s ==\n' "$*"; }

# Prints the command (quoting what needs it), then runs it. The error object
# node-pg-migrate dumps after a failure is trimmed down to its first line.
migrate() {
  printf '$ node-pg-migrate'
  for arg in "$@"; do
    if [[ $arg =~ [^A-Za-z0-9_./=:-] ]]; then printf " '%s'" "$arg"; else printf ' %s' "$arg"; fi
  done
  printf '\n'
  npx node-pg-migrate "$@" 2>&1 | awk '
    /^    at / { if (!noted) { print "    (stack trace trimmed)"; noted = 1 } if (/\{$/) skip = 1; next }
    skip { if (/^}$/) skip = 0; next }
    { print }'
  return "${PIPESTATUS[0]}"
}
sql() { printf '$ psql -c "%s"\n' "$1"; docker compose exec -T postgres psql -U app_user -d app -c "$1"; }

step '0. Fresh database: tables live in schema "app", the role search_path is "app, public"'
docker compose down -v >/dev/null 2>&1
docker compose up -d --wait

step '1. Some time ago: the first migration was applied with the schema configured'
migrate up 1 --schema app

step '   psql (like pgAdmin) finds the migrations table without "app." and shows it ran'
sql 'SELECT name, run_on FROM pgmigrations'

step '2. Today: `node-pg-migrate up`, with no --schema'
migrate up
echo "(exit code $? - it replayed a migration that already ran, see the error above)"

step '3. The history is untouched in app.pgmigrations; the run looked in public instead'
sql "SELECT 'app.pgmigrations' AS table_name, count(*) AS recorded FROM app.pgmigrations
     UNION ALL
     SELECT 'public.pgmigrations', count(*) FROM public.pgmigrations"

step '4. Like the reporter: set the old migration aside and try again'
migrate up --ignore-pattern '1654693101518.*'
echo "(exit code $? - business_profile exists, just not in public)"

step '5. Workaround: tell node-pg-migrate where the history lives'
migrate up --schema app

printf '\nDone. Stop the database with: docker compose down -v\n'
