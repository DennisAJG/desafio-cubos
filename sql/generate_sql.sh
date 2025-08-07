#!/usr/bin/env bash

set -a
source "$(dirname "$0")/../.env"
set +a

envsubst '${DB_USER},${DB_PASS},${DB_ROLE}' < "$(dirname "$0")/script.sql.tpl" > "$(dirname "$0")/script.sql"

echo "script.sql gerado com sucesso:"
cat "$(dirname "$0")/script.sql"
