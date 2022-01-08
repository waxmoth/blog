#!/bin/sh
set -eu

export SITE=${SITE:-"blog.example.com"}

echo "### Set the server name as: ${SITE}"
envsubst '$SITE' < /etc/nginx/conf.d/app.conf.template > /etc/nginx/conf.d/app.conf

data_path="/etc/letsencrypt"
if [ ! -e "$data_path/options-ssl-nginx.conf" ] || [ ! -e "$data_path/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path"
  wget -q https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf -O "$data_path/options-ssl-nginx.conf"
  wget -q https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem -O "$data_path/ssl-dhparams.pem"
fi

certificate_path="$data_path/live/${SITE}"
if [ ! -e "$certificate_path/privkey.pem" ] || [ ! -e "$certificate_path/fullchain.pem" ]; then
  echo "### Creating dummy certificate for ${SITE} ..."
  mkdir -p "$certificate_path"
  openssl req -x509 -nodes -newkey rsa:4096 -days 180 \
    -keyout "$certificate_path/privkey.pem" \
    -out "$certificate_path/fullchain.pem" \
    -subj "/CN=${SITE}"
fi

exec "$@"
