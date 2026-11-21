#!/usr/bin/env bash
# Checks the AGENTS.md rules that are visible in the text of manifests.
# Usage: hack/policy.sh [path...]   (default: apps platform services; missing paths are skipped)
set -euo pipefail

paths=()
for p in "${@:-apps platform services}"; do
  for q in $p; do [ -e "$q" ] && paths+=("$q"); done
done
if [ "${#paths[@]}" -eq 0 ]; then
  echo "policy: nothing to check"
  exit 0
fi

fail=0
report() { echo "policy: $1"; fail=1; }

scan() { # scan <message> <grep args...>
  local msg=$1; shift
  local out
  out=$(grep -rnE --include='*.yaml' --include='*.yml' "$@" "${paths[@]}" || true)
  if [ -n "$out" ]; then report "$msg"; echo "$out"; fi
}

scan "kind: Namespace is created by the bootstrap layer" '^[[:space:]]*kind:[[:space:]]*"?Namespace"?[[:space:]]*(#.*)?$'
scan "CreateNamespace=true is forbidden" 'CreateNamespace=true'
scan "kind: Secret is forbidden, use ExternalSecret" '^[[:space:]]*kind:[[:space:]]*"?Secret"?[[:space:]]*(#.*)?$'
scan "Bitnami images and charts are forbidden" -i 'bitnami'

while IFS= read -r f; do
  missing=$(yq eval 'select(.kind == "Application" and .metadata.annotations."argocd.argoproj.io/sync-wave" == null) | .metadata.name' "$f" | grep -v '^---$' || true)
  if [ -n "$missing" ]; then report "Application without argocd.argoproj.io/sync-wave in $f: $missing"; fi
done < <(find "${paths[@]}" -type f \( -name '*.yaml' -o -name '*.yml' \))

exit "$fail"
