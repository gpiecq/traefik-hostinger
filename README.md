# Traefik Reverse Proxy - Hostinger KVM

Configuration Traefik v3 pour héberger plusieurs applications Docker avec SSL automatique via Let's Encrypt.

## Prérequis

- Docker et Docker Compose installés
- Ports 80 et 443 disponibles
- Domaines pointant vers l'IP du serveur

## Installation

### Première installation sur le serveur

```bash
git clone git@github.com:gpiecq/traefik-hostinger.git ~/traefik
cd ~/traefik
./install.sh
docker compose up -d
```

### Déploiement automatique

Le déploiement se fait automatiquement via GitHub Actions sur push vers `main`.

Secrets à configurer dans GitHub :
- `SSH_HOST` : IP du serveur Hostinger
- `SSH_USER` : Utilisateur SSH
- `SSH_PRIVATE_KEY` : Clé privée SSH

## Ajouter une nouvelle application

Chaque application (projet séparé) doit :
1. Rejoindre le réseau `traefik-public`
2. Avoir les labels Traefik appropriés
3. Ne PAS exposer les ports 80/443 (Traefik s'en charge)

### Exemple avec FrankenPHP/Symfony

```yaml
services:
  app:
    image: mon-image:latest
    restart: unless-stopped
    environment:
      SERVER_NAME: ":80"  # FrankenPHP écoute en HTTP interne
      TRUSTED_PROXIES: "REMOTE_ADDR"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"
    networks:
      - traefik-public

networks:
  traefik-public:
    external: true
```

### Points importants

- **SERVER_NAME: ":80"** : FrankenPHP doit écouter en HTTP, Traefik gère le SSL
- **TRUSTED_PROXIES: "REMOTE_ADDR"** : Permet à Symfony de recevoir les vraies IPs clients
- **Pas de ports exposés** : Seul Traefik expose 80/443
- **Nom unique du router** : Remplacer `myapp` par un nom unique pour chaque app

## Dashboard Traefik

Le dashboard est accessible à l'adresse configurée dans `TRAEFIK_DASHBOARD_HOST`.

Pour générer un nouveau mot de passe :

```bash
# Installer htpasswd si nécessaire
apt-get install apache2-utils

# Générer le hash (doubler les $ dans le .env)
htpasswd -nb admin votremotdepasse
```

## Structure sur le serveur

```
/home/user/
├── traefik/                    # Ce projet
│   ├── docker-compose.yml
│   ├── traefik/
│   │   ├── traefik.yml
│   │   └── acme.json
│   └── .env
├── apex-logs-classic/          # Projet séparé
│   ├── docker-compose.yml
│   └── .env
└── autre-app/                  # Autre projet séparé
    ├── docker-compose.yml
    └── .env
```

## Commandes utiles

```bash
# Voir les logs
docker compose logs -f traefik

# Redémarrer Traefik
docker compose restart traefik

# Voir les routes actives (via API)
curl -s http://localhost:8080/api/http/routers | jq

# Vérifier le certificat d'un domaine
echo | openssl s_client -servername example.com -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
```

## Dépannage

### Certificat non généré

1. Vérifier que le domaine pointe vers le serveur
2. Vérifier les logs : `docker compose logs traefik | grep -i acme`
3. Vérifier que le port 443 est accessible depuis l'extérieur

### Application non accessible

1. Vérifier que l'app est sur le réseau `traefik-public`
2. Vérifier les labels Traefik
3. Vérifier que `traefik.enable=true` est présent

### Erreur 502 Bad Gateway

1. L'application n'écoute peut-être pas sur le bon port
2. Vérifier `loadbalancer.server.port` dans les labels
