#!/bin/sh
# Generate a self-signed certificate for the HTTP/2 example server.
# Certificates are not committed — they are local development artifacts.
set -e

cd "$(dirname "$0")"

if [ -f key.pem ] && [ -f cert.pem ]; then
    echo "key.pem and cert.pem already exist — nothing to do."
    exit 0
fi

openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout key.pem -out cert.pem -days 3650 \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "Generated key.pem and cert.pem for localhost."
