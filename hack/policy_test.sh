#!/usr/bin/env bash
# Runs hack/policy.sh on the fixtures: bad-* must fail, good* must pass.
set -uo pipefail
cd "$(dirname "$0")/.."

rc=0
for f in test/policy/bad-*.yaml; do
  if hack/policy.sh "$f" >/dev/null; then echo "FAIL: $f passed"; rc=1; else echo "ok: $f rejected"; fi
done
for f in test/policy/good*.yaml; do
  if hack/policy.sh "$f"; then echo "ok: $f accepted"; else echo "FAIL: $f rejected"; rc=1; fi
done
exit "$rc"
