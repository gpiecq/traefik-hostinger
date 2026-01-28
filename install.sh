#!/bin/bash
set -e

echo "Installation de Traefik..."

# Créer le fichier acme.json avec les bonnes permissions
if [ ! -f traefik/acme.json ]; then
    touch traefik/acme.json
    chmod 600 traefik/acme.json
    echo "✓ traefik/acme.json créé"
else
    echo "✓ traefik/acme.json existe déjà"
fi

# Créer le réseau traefik-public s'il n'existe pas
if ! docker network inspect traefik-public >/dev/null 2>&1; then
    docker network create traefik-public
    echo "✓ Réseau traefik-public créé"
else
    echo "✓ Réseau traefik-public existe déjà"
fi

echo ""
echo "Installation terminée. Démarrer avec:"
echo "  docker compose up -d"
