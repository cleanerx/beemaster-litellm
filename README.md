# Beemaster LiteLLM Proxy

LiteLLM proxy service for Beemaster app. Routes LLM requests to DeepInfra and tracks credit usage.

> **Architecture:** Supabase + Pi 5 LiteLLM Hybrid (ADR-021)
> See: `beemaster-android/docs/04_adr/ADR-021_supabase_pi5_litellm_hybrid.md`

```
Android App (Supabase JWT)
    │
    ▼
┌─────────────────────────────────────────┐
│ Caddy (HTTPS, Let's Encrypt)            │
│ beemaster.myfritz.net                   │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ LiteLLM Proxy (Pi 5, Docker)            │
│  - Custom Auth → Supabase verify-key    │
│  - Routes to DeepInfra Nemotron         │
│  - Callback: Supabase consume-credit    │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Supabase (Source of Truth)              │
│  - Auth (JWT)                           │
│  - Credits (PostgreSQL)                 │
│  - Subscriptions                        │
└─────────────────────────────────────────┘
```

## Pi 5 Setup

Siehe: [`docs/PI5_SETUP.md`](docs/PI5_SETUP.md) — Vollständige Schritt-für-Schritt-Anleitung.

### Quick Start

```bash
# .env konfigurieren
cp .env.example .env
nano .env

# Container starten
docker compose up -d

# Verifikation
curl https://beemaster.myfritz.net/health
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DEEPINFRA_API_KEY` | DeepInfra API key for Nemotron model |
| `LITELLM_MASTER_KEY` | LiteLLM admin key (generate with `openssl rand -hex 32`) |
| `SUPABASE_URL` | Supabase project URL |
| `INTERNAL_API_KEY` | Secret for Supabase Edge Function auth |
| `POSTGRES_PASSWORD` | Password for LiteLLM PostgreSQL (spend logs) |

## Backup & Restore

```bash
# Backup erstellen
./backup.sh

# Restore aus Backup
./restore.sh litellm_2026-06-28.sql
```

Siehe: [`docs/PI5_SETUP.md`](docs/PI5_SETUP.md) für Cron-Setup und Wartung.

## Files

| File | Purpose |
|------|---------|
| `config.yaml` | LiteLLM configuration (model routing, custom auth, callback) |
| `Dockerfile` | Docker build for LiteLLM (ARM64 compatible) |
| `docker-compose.yml` | 3 Services: Caddy, LiteLLM, PostgreSQL |
| `Caddyfile` | HTTPS-Terminierung mit Let's Encrypt |
| `callbacks/custom_auth.py` | Custom Auth: validates Supabase JWT via Edge Function |
| `callbacks/beemaster_callback.py` | Credit deduction callback via Supabase |
| `backup.sh` | PostgreSQL dump script |
| `restore.sh` | Restore from SQL dump |
| `.env.example` | Environment variables template |
| `docs/PI5_SETUP.md` | Full Pi 5 setup guide |

## Related

- **ADR-021:** `beemaster-android/docs/04_adr/ADR-021_supabase_pi5_litellm_hybrid.md`
- **Supabase Edge Function:** `beemaster-supabase/supabase/functions/verify-litellm-key/`
- **Android App:** `beemaster-android/` (AgentService, CreditRepository)
