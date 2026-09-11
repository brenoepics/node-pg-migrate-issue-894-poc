#!/usr/bin/env bash
# Runs `node-pg-migrate <args>` and fails if it runs a migration again that
# app.pgmigrations already records: the bug from salsita/node-pg-migrate#894.
#
# Used by .github/workflows/reproduce.yml. Works locally too, once the database
# is up (`docker compose up -d --wait`), e.g. `ci/expect-no-replay.sh up`.
set -uo pipefail
cd "$(dirname "$0")/.."

export DATABASE_URL="${DATABASE_URL:-postgres://app_user:app_password@localhost:54894/app}"

recorded=$(docker compose exec -T postgres psql -U app_user -d app -tAc 'SELECT name FROM app.pgmigrations')

printf '$ node-pg-migrate %s\n' "$*"
npx node-pg-migrate "$@" 2>&1 | tee node-pg-migrate.log
status=${PIPESTATUS[0]}

for name in $recorded; do
  if grep -qxF -- "> - $name" node-pg-migrate.log; then
    failure=$(grep -m1 -oE 'relation "[^"]+" does not exist' node-pg-migrate.log)
    echo "::error title=Bug #894 reproduced::node-pg-migrate $* ran $name again, although app.pgmigrations already records it.${failure:+ It then failed: $failure}"
    exit 1
  fi
done

exit "$status"
