# Render deployment (Trim API)

## Create the service
1) Render → New → Web Service
2) Connect your repo
3) Root directory: `backend`
4) Runtime: Python
5) Build command:
```bash
pip install -r requirements.txt
```
6) Start command:
```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## Database (Neon)
1) In Neon, copy your pooled connection string (recommended for serverless/Render).
2) In Render → Environment → add:
- `DATABASE_URL` = your Neon connection string

## Migrations (required)
Option A (recommended): Render “Deploy Hook” / “Release Command”:
```bash
alembic upgrade head
```

If you don’t have Release Commands on your Render plan, run migrations manually once using Render Shell:
```bash
cd /opt/render/project/src/backend
alembic upgrade head
```

## Firebase Admin (required)
Add these environment variables in Render:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

For `FIREBASE_PRIVATE_KEY`, paste the full key and keep the `\n` escapes. Example shape:
`-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n`

## Other required env vars
- `ENV=production`
- `ENCRYPTION_KEY` (Fernet key)

## CORS (optional)
Native iOS requests do not use CORS. If you have a web client, set:
- `CORS_ORIGINS=https://trimapp.co`

## Health check
After deploy:
- `GET https://api.trimapp.co/health`

