# Trim (SwiftUI)

## Production architecture (v1)
- Auth: Firebase Authentication (email/password)
- API: FastAPI
- DB: Neon Postgres (server-side)

## API base URL configuration
The app reads the API URL in this order:
1) Xcode Scheme environment variable `TRIM_API_URL` (best for local dev)
2) Info.plist key `TRIM_API_URL` (best for TestFlight/App Store)
3) Default: `http://127.0.0.1:8000`

## Xcode settings (exact)
Debug / local:
1) Xcode → Product → Scheme → Edit Scheme…
2) Run → Arguments → Environment Variables
3) Add:
   - Name: `TRIM_API_URL`
   - Value: `http://127.0.0.1:8000`

Release / production:
1) Select the Trim target → Info tab
2) Add a custom key:
   - Key: `TRIM_API_URL`
   - Type: String
   - Value: `https://api.trimapp.co`

## Auth → API flow
- User signs in/up via Firebase
- For every API request the app fetches a fresh Firebase ID token and sends:
  `Authorization: Bearer <firebase_id_token>`
- If the API returns 401/403, the app refreshes the token once and retries.
  If it’s still unauthorized, the user is signed out.
