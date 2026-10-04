#!/usr/bin/env bash
# Installs the Opacra testnet block explorer on a server that already runs the
# Opacra testnet seed node (contrib/launch/seed-node-setup.sh in the main repo).
#
#   sudo ./explorer-setup.sh [domain]          (default domain: explorer.opacra.org)
#
# Run it from the unpacked opacra-explorer-*.tar.gz folder. It installs the
# explorer under /opt/opacra-explorer, runs it on 127.0.0.1:8081 as a systemd
# service, puts nginx in front of it, and gets an HTTPS certificate once the
# domain's DNS A record points at this server. Safe to run again.
set -euo pipefail

DOMAIN="${1:-explorer.opacra.org}"
EMAIL="opacra@proton.me"
HERE="$(cd "$(dirname "$0")" && pwd)"

[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo)." >&2; exit 1; }
[ -f "$HERE/xmrblocks" ] || { echo "Run this from the unpacked explorer folder." >&2; exit 1; }
id opacra >/dev/null 2>&1 || { echo "User 'opacra' not found: install the seed node first." >&2; exit 1; }
[ -d /var/lib/opacra/testnet/lmdb ] || { echo "No testnet chain at /var/lib/opacra/testnet/lmdb." >&2; exit 1; }

echo "== packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx libunwind8 libevent-2.1-7t64 dnsutils

echo "== explorer files"
mkdir -p /opt/opacra-explorer
rm -rf /opt/opacra-explorer/templates
cp -r "$HERE/templates" /opt/opacra-explorer/
install -m 0755 "$HERE/xmrblocks" /opt/opacra-explorer/xmrblocks
cp "$HERE/LICENSE" /opt/opacra-explorer/ 2>/dev/null || true

echo "== service"
cp "$HERE/opacra-explorer.service" /etc/systemd/system/opacra-explorer.service
systemctl daemon-reload
systemctl enable opacra-explorer >/dev/null
systemctl restart opacra-explorer
sleep 3
if ! curl -fsS -o /dev/null http://127.0.0.1:8081/; then
  echo "Explorer did not answer on 127.0.0.1:8081. Check: journalctl -u opacra-explorer -n 50" >&2
  exit 1
fi

echo "== nginx"
sed "s/explorer\.opacra\.org/$DOMAIN/g" "$HERE/nginx-explorer.conf" > /etc/nginx/sites-available/opacra-explorer
ln -sf /etc/nginx/sites-available/opacra-explorer /etc/nginx/sites-enabled/opacra-explorer
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "== firewall"
if grep -q "Status: active" <(ufw status); then
  ufw allow 80/tcp comment "HTTP (explorer, certificate renewals)" >/dev/null
  ufw allow 443/tcp comment "HTTPS (explorer)" >/dev/null
  echo "ufw: opened 80 and 443"
else
  echo "ufw is not active; make sure TCP 80 and 443 are reachable." >&2
fi

echo "== HTTPS"
MYIP="$(curl -4 -fsS https://api.ipify.org || true)"
DNSIP="$(dig +short A "$DOMAIN" | tail -1)"
if [ -n "$MYIP" ] && [ "$MYIP" = "$DNSIP" ]; then
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
  echo "Done: https://$DOMAIN"
else
  echo "DNS for $DOMAIN points at '${DNSIP:-nothing}', this server is '${MYIP:-unknown}'."
  echo "Add an A record $DOMAIN -> $MYIP, wait a few minutes, then run this script again."
  echo "Meanwhile the explorer answers on http://$MYIP/ (plain HTTP)."
fi
