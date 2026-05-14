# Trim API (FastAPI)

## What this backend does
- Auth: verifies Firebase ID tokens on protected routes
- DB: stores user records in Postgres (Neon) via SQLAlchemy
- Hosting: deployable to Render with `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

## Environment variables
Required in production (Render):
- `ENV=production`
- `DATABASE_URL` (Neon pooled connection string)
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (use `\n` escapes in Render UI; backend converts them)
- `ENCRYPTION_KEY` (Fernet key, stable)

Optional:
- `CORS_ORIGINS` (comma-separated, e.g. `https://trimapp.co,https://admin.trimapp.co`)
- Plaid: `PLAID_CLIENT_ID`, `PLAID_SECRET`, `PLAID_ENV`

Local dev alternatives (instead of `DATABASE_URL`):
- `POSTGRES_SERVER`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`

## Local setup (Mac)
1) Create a virtualenv and install dependencies:
```bash
cd "/Users/macbook/Trim Mobile App/backend"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2) Create `.env` from `.env.example`:
```bash
cd "/Users/macbook/Trim Mobile App/backend"
cp .env.example .env
```

3) Run DB migrations:
```bash
cd "/Users/macbook/Trim Mobile App/backend"
alembic upgrade head
```

4) Start the API:
```bash
cd "/Users/macbook/Trim Mobile App/backend"
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Endpoints (starter)
- `GET /health`
- `POST /api/v1/auth/sync-user` (protected)
- `GET /api/v1/me` (protected)
- `PATCH /api/v1/me` (protected)
- Existing profile endpoints remain under `GET/PATCH /api/v1/profile/me`

