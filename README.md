# Beemaster LiteLLM Proxy

LiteLLM proxy service for Beemaster app. Routes LLM requests to DeepInfra and tracks credit usage.

## Architecture

```
Android App (Virtual Key)
    │
    ▼
┌─────────────────────────────────────────┐
│ LiteLLM Proxy (Railway)                 │
│  - Virtual Key Authentication            │
│  - Routes to DeepInfra Nemotron         │
│  - Callback: Credit Deduction           │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Beemaster Backend (Cloudflare Workers)  │
│  - /api/v1/credits/consume              │
│  - Deducts credits from user            │
└─────────────────────────────────────────┘
```

## Railway Deployment

### 1. Create PostgreSQL Database

Railway Dashboard → New Service → Database → PostgreSQL

### 2. Deploy this Repo

Railway Dashboard → New Service → GitHub Repo → `beemaster-litellm`

### 3. Set Environment Variables

```bash
DEEPINFRA_API_KEY=your-deepinfra-key
LITELLM_MASTER_KEY=your-master-key
BEEMASTER_BACKEND_URL=https://beemaster-backend.cleanerx.workers.dev
INTERNAL_API_KEY=your-internal-secret-key
DATABASE_URL=${{Postgres.DATABASE_URL}}  # Reference Railway PostgreSQL
```

### 4. Generate Master Key

```bash
# Generate a secure key
openssl rand -hex 32
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DEEPINFRA_API_KEY` | DeepInfra API key for Nemotron model |
| `LITELLM_MASTER_KEY` | LiteLLM admin key (generate with openssl) |
| `BEEMASTER_BACKEND_URL` | Beemaster Backend URL |
| `INTERNAL_API_KEY` | Secret key for backend authentication |
| `DATABASE_URL` | PostgreSQL connection (auto from Railway) |

## API Endpoints

### Health Check

```bash
curl https://your-litellm.railway.app/health
```

### Chat Completion

```bash
curl -X POST https://your-litellm.railway.app/v1/chat/completions \
  -H "Authorization: Bearer sk-beemaster-xxx" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Credit Calculation

| Tokens | Credits |
|--------|---------|
| 1-999 | 1 |
| 1000-1999 | 1 |
| 2000-2999 | 2 |
| ... | ... |

Formula: `credits = max(1, total_tokens // 1000)`

## Testing

```bash
# Local build
docker build -t beemaster-litellm .
docker run -p 4000:4000 \
  -e DEEPINFRA_API_KEY=your-key \
  -e LITELLM_MASTER_KEY=your-master \
  -e BEEMASTER_BACKEND_URL=http://localhost:8787 \
  -e INTERNAL_API_KEY=your-secret \
  beemaster-litellm

# Test health
curl http://localhost:4000/health
```

## License

MIT

---

*Part of Beemaster Project*