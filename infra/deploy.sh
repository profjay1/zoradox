#!/usr/bin/env bash
# Syncs site/ to the web root on the server. rsync only: no sudo, no Caddy changes.
# The Caddy vhost lives in portfolio-hub's Ansible role, not in this repo.
#
# Usage (from anywhere in the repo):
#   DEPLOY_HOST=<host> infra/deploy.sh --dry-run   # show what would change
#   DEPLOY_HOST=<host> infra/deploy.sh             # deploy
# DEPLOY_HOST: the host string from your known_hosts / ~/.ssh/config.
# DEPLOY_USER: defaults to "deploy".
set -euo pipefail

: "${DEPLOY_HOST:?Set DEPLOY_HOST to the host string of the server (see infra/README.md)}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
REMOTE_DIR="/var/www/zoradox/"

DRY_RUN=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=(--dry-run) ;;
    *) echo "Unknown option: $arg (only --dry-run is supported)" >&2; exit 2 ;;
  esac
done

cd "$(dirname "$0")/.."

# rsync --delete mirrors the source exactly, so a wrong source folder
# would wipe the web root. Refuse unless this really is the site.
if [[ ! -f site/index.html ]]; then
  echo "Refusing to deploy: site/index.html not found in $(pwd)" >&2
  exit 1
fi

# Rollback means re-deploying a commit, so uncommitted changes are worth a warning.
if [[ -n "$(git status --porcelain -- site/ 2>/dev/null)" ]]; then
  echo "Warning: site/ has uncommitted changes; they will be deployed too." >&2
fi

echo "Deploying site/ to ${DEPLOY_USER}@${DEPLOY_HOST}:${REMOTE_DIR}${DRY_RUN:+ (dry run)}"

rsync -az --delete --chmod=D755,F644 --itemize-changes "${DRY_RUN[@]}" \
  site/ "${DEPLOY_USER}@${DEPLOY_HOST}:${REMOTE_DIR}"

echo "Done.${DRY_RUN:+ Nothing was changed (dry run).}"
