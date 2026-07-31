# Pi 5 Setup Guide — Beemaster LiteLLM Proxy

Vollständige Anleitung zur Einrichtung von LiteLLM auf Raspberry Pi 5 mit Docker, Caddy (HTTPS), MyFRITZ-DynDNS und Backup-Strategie.

## Voraussetzungen

- Raspberry Pi 5 (8GB empfohlen, 4GB minimum)
- NVMe SSD (via Pimoroni NVMe Base oder ähnlich) — SD-Karte nicht empfohlen für PostgreSQL
- Raspberry Pi OS 64-bit (Bookworm)
- Fritzbox mit MyFRITZ-DynDNS
- Supabase Projekt (URL + Service Role Key)
- DeepInfra API Key
- Portfreigabe 80 + 443 in der Fritzbox

## Schritt 1: Pi OS vorbereiten

```bash
# System aktualisieren
sudo apt update && sudo apt upgrade -y

# NVMe mounten (falls Pimoroni NVMe Base verwendet)
sudo mkdir -p /mnt/nvme
sudo mount /dev/nvme0n1p1 /mnt/nvme
# Für persistent: /etc/fstab Eintrag hinzufügen
echo '/dev/nvme0n1p1 /mnt/nvme ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

## Schritt 2: Docker installieren

```bash
# Docker installieren
curl -fsSL https://get.docker.com | sh

# Docker Compose Plugin installieren
sudo apt install docker-compose-plugin -y

# User zur docker-Gruppe hinzufügen (erneut einloggen danach)
sudo usermod -aG docker $USER

# Verifizieren
docker --version
docker compose version
```

## Schritt 3: Repo klonen

```bash
cd /home/jens/dev/git
git clone <repo-url> beemaster-litellm
cd beemaster-litellm
```

## Schritt 4: Environment konfigurieren

```bash
# .env aus Template erstellen
cp .env.example .env

# Werte ausfüllen
nano .env
```

Erforderliche Werte:
- `DEEPINFRA_API_KEY`: API Key von DeepInfra (für Nemotron LLM)
- `LITELLM_MASTER_KEY`: Generieren mit `openssl rand -hex 32`, Prefix `sk-beemaster-master-`
- `SUPABASE_URL`: Supabase Project URL (z. B. `https://adrrhbgiicbheydzxdwv.supabase.co`)
- `INTERNAL_API_KEY`: Secret Key für Supabase Edge Function Auth (gleich wie in Supabase `INTERNAL_API_KEY` Env Var)
- `POSTGRES_PASSWORD`: Generieren mit `openssl rand -hex 16`

## Schritt 5: Caddyfile anpassen

```bash
# Falls du einen anderen MyFRITZ-Namen verwendest:
nano Caddyfile
# Ersetze "beemaster.myfritz.net" durch deinen DynDNS-Namen
```

## Schritt 6: Fritzbox Portfreigabe

1. Fritzbox-WebUI öffnen (`http://fritz.box`)
2. **Internet → Freigaben → Geräte**
3. Pi 5 auswählen → **Neue Freigabe**
4. Port 80 (HTTP) freigeben — für Let's Encrypt Challenge
5. Port 443 (HTTPS) freigeben — für LiteLLM API
6. MyFRITZ-DynDNS aktivieren: **Internet → MyFRITZ-Konto**
   - Falls noch nicht aktiv: MyFRITZ-Konto erstellen
   - DynDNS-Name notieren (z. B. `beemaster.myfritz.net`)

## Schritt 7: Container starten

```bash
docker compose up -d
```

Logs prüfen:
```bash
docker compose logs -f litellm
```

## Schritt 8: Verifikation

```bash
# Health Check (lokal)
curl http://localhost:4000/health

# Health Check (via MyFRITZ — von außerhalb des Heimnetzes testen!)
curl https://beemaster.myfritz.net/health
# Erwartet: {"status": "healthy", ...}

# LLM Test (mit Supabase JWT)
curl -X POST https://beemaster.myfritz.net/v1/chat/completions \
  -H "Authorization: Bearer <dein-supabase-jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Schritt 9: Backup-Cron einrichten

```bash
# Cron-Editor öffnen
crontab -e

# Tägliches Backup um 02:00 Uhr hinzufügen:
0 2 * * * /home/jens/dev/git/beemaster-litellm/backup.sh >> /home/jens/dev/git/beemaster-litellm/backups/backup.log 2>&1
```

## Schritt 10: Supabase Edge Function deployen

Die `verify-litellm-key` Edge Function muss in Supabase deployed werden:

```bash
cd /home/jens/dev/git/beemaster-supabase
npx supabase functions deploy verify-litellm-key
```

Supabase Env Variables setzen (Supabase Dashboard → Edge Functions → Settings):
- `INTERNAL_API_KEY`: Gleicher Wert wie in `.env` auf Pi 5

## Wartung

### Update LiteLLM

```bash
cd /home/jens/dev/git/beemaster-litellm
docker compose pull
docker compose up -d
```

### Backup manuell erstellen

```bash
./backup.sh
```

### Restore aus Backup

```bash
./restore.sh litellm_2026-06-28.sql
```

### Logs anzeigen

```bash
docker compose logs -f litellm    # LiteLLM
docker compose logs -f caddy      # Caddy (HTTPS)
docker compose logs -f db          # PostgreSQL
```

### Container stoppen/starten

```bash
docker compose down     # Stoppen
docker compose up -d    # Starten
docker compose restart  # Neustarten
```

## Fehlersuche

### Caddy kann kein Zertifikat holen

- Port 80 muss in Fritzbox freigegeben sein (Let's Encrypt HTTP-01 Challenge)
- MyFRITZ-DynDNS muss korrekt auf deine öffentliche IP zeigen
- Prüfen: `curl http://beemaster.myfritz.net/.well-known/acme-challenge/test`

### LiteLLM startet nicht

- Logs prüfen: `docker compose logs litellm`
- Häufigste Ursache: Fehlende oder falsche `.env`-Werte
- DeepInfra API Key prüfen: `curl -H "Authorization: Bearer $DEEPINFRA_API_KEY" https://api.deepinfra.com/v1/models`

### Custom Auth schlägt fehl

- Supabase Edge Function `verify-litellm-key` muss deployed sein
- `INTERNAL_API_KEY` muss in Supabase und Pi 5 `.env` identisch sein
- `SUPABASE_URL` muss korrekt sein (mit `https://`)

### PostgreSQL nicht erreichbar

- `docker compose logs db` prüfen
- Health-Check: `docker compose ps` — `db` sollte `healthy` zeigen
- NVMe mount prüfen: `df -h` — `/var/lib/docker` sollte auf NVMe liegen

## Architektur-Referenz

Siehe: `beemaster-android/docs/04_adr/ADR-021_supabase_pi5_litellm_hybrid.md`
