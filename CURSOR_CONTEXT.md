# Filmila iOS — Cursor Build Context

## What this is
A SwiftUI iOS app (viewer-only) for the Filmila short film platform.
The backend already exists. This app is a client — it does NOT create any new backend.

## Key rules — read before every task
- iOS 16+ minimum target
- SwiftUI only — no UIKit except where required (AVPlayerViewController, ASWebAuthenticationSession)
- MVVM architecture — zero business logic in Views
- All dependencies injected via AppContainer protocol — no .shared singletons in ViewModels
- Swift Concurrency everywhere — async/await, Task, AsyncStream — no Combine, no callbacks
- Dark mode only — preferredColorScheme(.dark) forced at root
- Arabic + English localisation — all user-facing strings in Localizable.strings
- Never hardcode colors — always use FilmilaColors enum
- Never hardcode fonts — always use Font extensions from FilmilaTypography

## Backend
- Supabase: auth, database (Postgres + RLS), realtime
- Vercel /api/* endpoints for: IAP recording, signed S3 URLs, ticket email
- AWS S3: video + thumbnail storage (accessed via signed URLs only)
- Apple IAP (StoreKit 2): primary iOS payment — NOT Geidea

## Payment rule — critical
iOS app uses Apple IAP (StoreKit 2) only.
Geidea is website-only. Never reference Geidea in iOS code.

## Access rule (from backend)
A viewer can watch a film if:
  film.price == 0 (free)
  OR film_payments table has row where film_id matches, viewer_id matches, status = 'completed'

## film_id type
Always Int — not UUID. This matches the backend runtime assumption.
