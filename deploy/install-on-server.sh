#!/usr/bin/env bash
# Runs ON sgp1 (uploaded and started by deploy-chronomancer.ps1).
# Swaps the staged Chronomancer page into the live whispr.dev web root.
# Usage: bash install.sh <web-root> <site-url>
set -euo pipefail

WEBROOT="${1:-/srv/whispr-static/whispr.dev}"
SITE_URL="${2:-https://whispr.dev}"
STAGE="$HOME/chronomancer-staging/chronomancer"
TARGET="$WEBROOT/chronomancer"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "==> Web root : $WEBROOT"
echo "==> Staged   : $STAGE"

[ -d "$WEBROOT" ]            || { echo "ERROR: web root $WEBROOT doesn't exist on this server."; exit 1; }
[ -f "$STAGE/index.html" ]   || { echo "ERROR: nothing staged at $STAGE (upload step failed?)."; exit 1; }
[ -d "$STAGE/download" ]     || { echo "ERROR: $STAGE/download missing."; exit 1; }

# Use sudo only if we can't write to the web root ourselves.
if [ -w "$WEBROOT" ] && { [ ! -e "$TARGET" ] || [ -w "$TARGET" ]; }; then
  SUDO=""
else
  SUDO="sudo"
  echo "==> Web root isn't writable by $(whoami); using sudo (you may be asked for your password)."
  sudo -v
fi

# Match ownership of the rest of the site (only possible with sudo).
OWNER="$(stat -c '%U:%G' "$WEBROOT")"

echo "==> Preparing new copy"
$SUDO rm -rf "$TARGET.new"
$SUDO cp -r "$STAGE" "$TARGET.new"
$SUDO find "$TARGET.new" -type d -exec chmod 755 {} +
$SUDO find "$TARGET.new" -type f -exec chmod 644 {} +
if [ -n "$SUDO" ]; then
  $SUDO chown -R "$OWNER" "$TARGET.new"
fi

echo "==> Swapping into place"
if [ -e "$TARGET" ]; then
  BACKUP="$HOME/chronomancer-backup-$STAMP"
  $SUDO mv "$TARGET" "$BACKUP"
  echo "    previous version moved to $BACKUP"
fi
$SUDO mv "$TARGET.new" "$TARGET"

echo "==> Live files"
ls -la "$TARGET" "$TARGET/download"

if command -v curl >/dev/null 2>&1; then
  echo "==> HTTP check"
  msi_path=""
  for f in "$TARGET"/download/*.msi; do [ -e "$f" ] && msi_path="/chronomancer/download/${f##*/}" && break; done
  for path in "/chronomancer/" ${msi_path:+"$msi_path"}; do
    code="$(curl -s -o /dev/null -w '%{http_code}' -I "$SITE_URL$path" || true)"
    echo "    $code  $SITE_URL$path"
  done
fi

rm -rf "$HOME/chronomancer-staging"
echo "==> Done."
