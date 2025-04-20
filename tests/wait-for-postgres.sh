#!/bin/sh
# 🕊️ wait-for-postgres.sh — Awaiting the database like a patient mystic.
# Adapted (then fully spiritualized) from: https://docs.docker.com/compose/startup-order/

set -eu

uri="$2"
cmd="$@"

>&2 echo "🛌 Entering meditative sleep — skipping initial tantrums from Postgres..."
sleep 10

attempt=0
while ! psql "$uri" -c '\q' 2>/dev/null; do
  attempt=$((attempt + 1))
  >&2 echo "⏳ Postgres still rebirthing... ($attempt)"
  sleep 1
done

>&2 echo "✅ The database has awoken. Executing the final rite:"
>&2 echo "👉 $cmd"

exec $cmd
