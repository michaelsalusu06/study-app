---
title: Documentation
description: Full developer reference — architecture, API, testing, and how-to guides
permalink: /docs
---

# StudyApp — Developer Documentation

> Single source of truth for how StudyApp is built, how every piece works, and how to extend it. If you're an external dev building a web-app or Flutter client on top of this API, start at Section 0.

---

## Table of Contents

0. [Start Here (External Developers)](#0-start-here-external-developers)
1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Environment Setup](#3-environment-setup)
4. [Environment Variables Reference](#4-environment-variables-reference)
5. [Database Schema](#5-database-schema)
6. [Backend — NestJS](#6-backend--nestjs)
7. [API Reference](#7-api-reference)
8. [Frontend — Flutter](#8-frontend--flutter)
9. [Feature Modules](#9-feature-modules)
10. [Data Models](#10-data-models)
11. [Testing](#11-testing)
12. [Common How-To Guide](#12-common-how-to-guide)
13. [Troubleshooting](#13-troubleshooting)
- [Appendix A — Booking State Machine & Coin Flow](#appendix-a--booking-state-machine--coin-flow)
- [Appendix B — Coin System Explained](#appendix-b--coin-system-explained)
- [Appendix C — Vibe Coding Prompts](#appendix-c--vibe-coding-prompts)

---

## 0. Start Here (External Developers)

You're building a web-app or Flutter client that talks to the StudyApp API. You don't need to read the NestJS internals or Flutter sections — just read this section and Section 7.

### What is this API?

StudyApp is a peer-to-peer tutoring marketplace REST API. Students book sessions with tutors. Payment is handled via an in-app coin system (1 coin = Rp 1,000). Video calls use Jitsi (no extra integration needed — the API returns a room name and password).

### Base URL

```
Development:  http://localhost:3000
Production:   https://your-deployed-api.com   (update AppConfig.API_URL / your env)
```

### Auth pattern

All protected endpoints require:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

Get a token by calling `POST /auth/login` or `POST /auth/signup`. The token is a JWT that expires in **7 days**. Store it in `localStorage` (web) or `SharedPreferences` (Flutter).

### 3-step quickstart

**Step 1 — Get a token:**
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"yourpassword"}'
```
Response gives you `access_token`.

**Step 2 — Hit a protected endpoint:**
```bash
curl http://localhost:3000/auth/me \
  -H "Authorization: Bearer <access_token>"
```

**Step 3 — Handle errors:**
```json
{ "statusCode": 401, "message": "Unauthorized", "error": "Unauthorized" }
{ "statusCode": 403, "message": "Your account has been banned.", "error": "Forbidden" }
{ "statusCode": 404, "message": "User not found", "error": "Not Found" }
{ "statusCode": 400, "message": ["email must be an email"], "error": "Bad Request" }
```

### Common error status codes

| Status | Meaning |
|--------|---------|
| `400` | Bad request — validation failed (check `message` array) |
| `401` | Missing or invalid JWT token |
| `403` | Banned/deactivated account, or wrong role for endpoint |
| `404` | Resource not found |
| `409` | Conflict — booking time overlap |
| `500` | Server error — check server logs |

### Dev-only endpoints (remove before prod)

| Endpoint | What it does |
|----------|-------------|
| `GET /auth/dev-token?email=...` | Get JWT for any user without password |
| `POST /coins/dev/fulfill/:orderId` | Fulfill coin purchase without real payment |
| `POST /admin/users/:id/grant-coins` | Give coins to any user |

> **Warning:** These endpoints are disabled automatically when `NODE_ENV=production` or `MIDTRANS_SERVER_KEY` is set. Never expose them in prod.

### Quick glossary

| Term | Meaning |
|------|---------|
| **coin** | In-app currency. 1 coin = Rp 1,000. Students buy coins, spend them on bookings. Tutors earn coins and withdraw to IDR. |
| **booking** | A scheduled tutoring session between one student and one tutor |
| **offer** | A tutor's service listing with title, subject, duration, and price |
| **availability** | A time slot a tutor is free to be booked |
| **verification** | Tutors submit ID/certs for admin approval before tutoring |

---

## 1. Project Overview

StudyApp is a peer-to-peer tutoring marketplace. It connects **students** who want to learn with **tutors** who want to teach. The platform is split into two independent codebases that communicate over HTTP:

- **Flutter frontend** — cross-platform mobile/web app (Android, iOS, Web)
- **NestJS backend** — REST API server backed by PostgreSQL

**How it works end-to-end:**
1. A user registers with email/password or Google OAuth
2. They pick a role: `STUDENT` or `TUTOR`
3. They fill in their profile (username, bio, avatar)
4. Students browse tutors, filter by subject/price, view offers, and book sessions
5. Tutors manage their offers, availability, and communicate with students via chat
6. Payments are tracked via in-app coins (purchased with IDR via Midtrans)
7. After a session both parties can leave reviews

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter App (Client)                   │
│  ┌──────────────┐  ┌─────────────────────────────────┐  │
│  │  UI Screens  │  │         Core Services           │  │
│  │  (features/) │  │  AuthState  │  UserApiService   │  │
│  └──────────────┘  └─────────────────────────────────┘  │
│                         │ HTTP / JSON                    │
└─────────────────────────│──────────────────────────────-┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│               NestJS Backend (API Server)               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │AuthModule│ │UserModule│ │ Booking  │ │  Coins    │  │
│  │ /auth/*  │ │ /user/*  │ │/booking/*│ │ /coins/*  │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │Messages  │ │ Reviews  │ │  Offers  │ │  Admin    │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────┘  │
│                         │ SQL (Prisma ORM)               │
└─────────────────────────│───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│             PostgreSQL (hosted on Supabase)             │
│  profiles  bookings  messages  reviews  coin_transactions│
│  tutor_offers  tutor_availabilities  subjects  ...      │
└─────────────────────────────────────────────────────────┘
```

**Key design decisions:**
- Frontend and backend are fully decoupled — they share no code
- Auth is stateless: every protected request carries a JWT Bearer token
- The Flutter app holds auth state in an in-memory singleton (`AuthState`) — no local storage persistence yet
- All database access goes through `PrismaService` — never raw SQL
- Passwords are hashed with **argon2** before storing — never stored in plaintext
- PII (tutor verification docs) encrypted with AES-256-GCM before DB storage

---

## 3. Environment Setup

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | `^3.5.0` | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| Dart | included with Flutter | — |
| Node.js | `v18+` | [nodejs.org](https://nodejs.org/) |
| npm | included with Node | — |
| Git | any | [git-scm.com](https://git-scm.com/) |
| Supabase account | — | [supabase.com](https://supabase.com/) |

### Step 1 — Clone the repo

```bash
git clone https://github.com/hiyokun-d/study-app.git
cd study-app
```

### Step 2 — Backend setup

```bash
cd _server
npm install
cp .env.example .env
```

Open `.env` and fill in values (see [Section 4](#4-environment-variables-reference)):

```env
DATABASE_URL=postgresql://...
DIRECT_URL=postgresql://...
JWT_SECRET=your-very-long-secret-32-chars-min
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-...
PORT=3000
```

```bash
npx prisma generate
npx prisma migrate deploy
npm run start:dev
```

API is now running at `http://localhost:3000`.

### Step 3 — Frontend setup

```bash
cd ..
flutter pub get
flutter run -d android     # Android emulator
flutter run -d chrome      # Web
flutter run                # First available device
```

> **Note on API URL:** Default `AppConfig.API_URL` is `http://10.0.2.2:3000` (Android emulator → host localhost). iOS simulator: `http://localhost:3000`. Real device: use your LAN IP `http://192.168.x.x:3000`. Update `lib/core/constants/app_config.dart`.

### Step 4 — Verify everything works

1. `GET http://localhost:3000/auth` → should return `"You're at the right path, continue!"`
2. Flutter: launch app, try registering a new account

### Step 5 — First admin (optional)

```bash
# Bootstrap first admin — only works when no admins exist yet
curl -X POST http://localhost:3000/admin/create \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Admin","password":"securepassword","bootstrap_secret":"<ADMIN_BOOTSTRAP_SECRET>"}'
```

---

## 4. Environment Variables Reference

All backend environment variables live in `_server/.env`. **Never commit this file.**

| Variable | Required | Prod Required | Description |
|----------|----------|---------------|-------------|
| `DATABASE_URL` | Yes | Yes | Supabase pooled connection string. `postgresql://user:pass@host:port/db?pgbouncer=true` |
| `DIRECT_URL` | Yes | Yes | Supabase direct (non-pooled) connection. Used by Prisma for migrations. |
| `JWT_SECRET` | Yes | Yes | Signs/verifies JWT tokens. Must match across all deployments. 32+ random chars. |
| `GOOGLE_CLIENT_ID` | Yes | Yes | OAuth 2.0 Client ID from Google Cloud Console. Required for `/auth/google`. |
| `GOOGLE_CLIENT_SECRET` | Yes | Yes | OAuth 2.0 Client Secret from Google Cloud Console. |
| `ADMIN_PUBLIC_KEY_B64` | Yes | Yes | Base64-encoded RSA public key. Encrypts tutor verification PII before DB storage. |
| `ADMIN_PRIVATE_KEY_B64` | Yes | Yes | Base64-encoded RSA private key. Decrypts PII when admin views verification data. |
| `ADMIN_BOOTSTRAP_SECRET` | Yes | Yes | One-time secret for creating the first admin via `POST /admin/create`. |
| `INTERNAL_SECRET` | Yes | Yes | Secret for Vercel Cron endpoints (`/internal/*`). Sent as `x-internal-secret` header. |
| `PORT` | No | No | Port the server listens on. Default: `3000`. |
| `NODE_ENV` | No | Yes | Set to `production` in prod. Disables dev-only endpoints like `/auth/dev-token`. |
| `MIDTRANS_IS_PRODUCTION` | No | Yes | `true` = use Midtrans production server. `false`/unset = sandbox. |
| `MIDTRANS_CLIENT_KEY` | No | Yes | Midtrans client key (for QRIS/frontend payment initiation). |
| `MIDTRANS_SERVER_KEY` | No | Yes | Midtrans server key. Setting this disables `POST /coins/dev/fulfill/:orderId`. |

**How to generate values:**
```bash
# JWT_SECRET
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"

# RSA key pair for ADMIN_PUBLIC_KEY_B64 / ADMIN_PRIVATE_KEY_B64
openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in private.pem -out public.pem
base64 -i private.pem | tr -d '\n'   # → ADMIN_PRIVATE_KEY_B64
base64 -i public.pem  | tr -d '\n'   # → ADMIN_PUBLIC_KEY_B64
```

---

## 5. Database Schema

Schema file: `_server/prisma/schema.prisma`. All schema changes go through Prisma migrations — never edit the DB directly.

### `profiles` — User accounts

Every user (student, tutor, or admin) has one profile row.

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK, auto-generated |
| `email` | String | Unique |
| `password` | String? | Nullable — Google-only users have none |
| `full_name` | String? | Display name |
| `username` | String? | Unique handle |
| `bio` | String? | Short description |
| `avatar_url` | String? | URL to profile image |
| `role` | String | `"STUDENT"`, `"TUTOR"`, or `"ADMIN"`. Default: `"STUDENT"` |
| `book_price` | Decimal | Tutor base price in IDR. Default: 0 |
| `book_price_coins` | Int | Session price in coins/hour. Default: 10 |
| `subjects` | String[] | Array of subject slugs |
| `overall_rating` | Decimal? | Calculated average rating |
| `tutor_rating` | Decimal? | Rating as tutor |
| `student_rating` | Decimal? | Rating as student |
| `rating_count` | Int | Total review count |
| `coins_balance` | Int | Current coin balance |
| `is_active` | Boolean | Not deactivated by admin. Default: true |
| `is_banned` | Boolean | Permanently banned. Default: false |
| `user_status` | String | `ONLINE`/`OFFLINE`/`BUSY`. Default: `OFFLINE` |
| `last_seen_at` | DateTime? | Last activity timestamp |
| `verification_status` | String? | `PENDING`/`APPROVED`/`REJECTED` (tutors only) |
| `admin_id` | String? | 10-digit numeric ID (admins only) |
| `penalty_until` | DateTime? | Penalty window end time |
| `penalty_price_pct` | Int | Price reduction % during penalty (0-100) |
| `penalty_rating_knock` | Decimal | Rating subtraction during penalty |
| `created_at` | DateTime | Registration date |
| `updated_at` | DateTime | Last profile update |

### `bookings` — Tutoring sessions

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `student_id` | UUID | FK → profiles |
| `tutor_id` | UUID | FK → profiles |
| `tutor_offer_id` | UUID? | FK → tutor_offers |
| `tutor_availability_id` | UUID? | FK → tutor_availabilities |
| `start_at` | DateTime | Session start time |
| `end_at` | DateTime | Session end time |
| `duration_minutes` | Int | Session length |
| `price` | Decimal | Session price in IDR |
| `coins_cost` | Int | Coins deducted from student |
| `status` | booking_status | See [Appendix A](#appendix-a--booking-state-machine--coin-flow) |
| `description` | String? | Student's reason for booking |
| `expires_at` | DateTime? | Auto-decline if tutor doesn't respond in 1 hour |
| `reschedule_proposed_start` | DateTime? | Tutor's proposed new start |
| `reschedule_proposed_end` | DateTime? | Tutor's proposed new end |
| `reschedule_notes` | String? | Reschedule reason |
| `price_proposed_coins` | Int? | Tutor's proposed new price in coins |
| `price_proposal_message` | String? | Reason for price increase |
| `price_proposal_expires_at` | DateTime? | Expires 2 hours after proposal |

### `tutor_offers` — Service listings

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `tutor_id` | UUID | FK → profiles |
| `title` | String | e.g. "Calculus 1-on-1" |
| `summary` | String? | Short description (max 300 chars) |
| `about` | String? | Detailed description (max 2000 chars) |
| `coins_per_hour` | Int | Price in coins |
| `duration_minutes` | Int | Session duration. Default: 60 |
| `subject_ids` | String[] | UUIDs of subjects |
| `thumbnail_url` | String? | Cover image |
| `is_active` | Boolean | Active listing. Default: true |

### `tutor_availabilities` — Schedule

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `tutor_id` | UUID | FK → profiles |
| `available_from` | DateTime | Slot start |
| `available_to` | DateTime | Slot end |
| `timezone` | String? | IANA timezone e.g. `"Asia/Jakarta"` |

### `messages` — Chat

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `from_id` | UUID | Sender FK |
| `to_id` | UUID | Recipient FK |
| `booking_id` | UUID? | Associated booking |
| `content` | String | Message text |
| `metadata` | JSON? | Extra data |
| `is_read` | Boolean | Default: false |
| `created_at` | DateTime | Sent timestamp |

### `reviews` — Ratings

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `booking_id` | UUID? | Associated booking |
| `reviewer_id` | UUID | Who wrote the review |
| `reviewee_id` | UUID | Who was reviewed |
| `rating` | Int | 1–5 stars |
| `comment` | String? | Review text |

### `notifications` — In-app

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `profile_id` | UUID | FK → profiles |
| `type` | String | Event type (see notification types below) |
| `payload` | JSON? | Event data e.g. `{"booking_id":"..."}` |
| `seen` | Boolean | Default: false |

**Notification types:** `NEW_BOOKING`, `BOOKING_CONFIRMED`, `BOOKING_DECLINED`, `BOOKING_CANCELLED`, `BOOKING_COMPLETED`, `BOOKING_EXPIRED`, `RESCHEDULE_PROPOSED`, `RESCHEDULE_ACCEPTED`, `RESCHEDULE_REJECTED`, `PRICE_PROPOSED`, `PRICE_ACCEPTED`, `PRICE_REJECTED`, `SESSION_REMINDER`, `REVIEW_RECEIVED`, `COINS_RECEIVED`, `WITHDRAWAL_PROCESSED`

### `coin_transactions` — Ledger

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `profile_id` | UUID | FK → profiles |
| `amount` | Int | Positive (credit) or negative (debit) |
| `kind` | String | `WELCOME_BONUS`/`PURCHASE`/`BOOKING_PAYMENT`/`REFUND`/`ADJUSTMENT` |
| `ref_id` | UUID? | FK to booking or payment_order |
| `note` | String? | Description |

### `payment_orders` — Coin purchases

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `profile_id` | UUID | FK → profiles |
| `coins_amount` | Int | Coins to purchase |
| `fiat_amount` | Decimal | IDR price |
| `status` | String | `PENDING`/`COMPLETED`/`FAILED`/`REFUNDED` |
| `provider` | String | `"midtrans"` |
| `qris_ref` | String? | Midtrans transaction_id |

### `withdrawal_requests` — Tutor cashouts

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `tutor_id` | UUID | FK → profiles |
| `coins_amount` | Int | Coins to withdraw |
| `idr_amount` | Decimal | IDR payout amount |
| `status` | String | `PENDING`/`APPROVED`/`REJECTED`/`PAID` |
| `account_name` | String | Bank account holder |
| `account_number` | String | Bank account number |
| `payment_method` | String | `QRIS`/`BANK_TRANSFER`/`GOPAY`/`OVO`/`DANA` |
| `bank_name` | String? | Bank name |

### `subjects` — Subject catalog

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `slug` | String | URL-safe identifier, unique |
| `name` | String | Display name |

### How to make a schema change

```bash
cd _server
npx prisma migrate dev --name describe_your_change
npx prisma generate
# Production:
npx prisma migrate deploy
```

> **Never** edit migration files manually. If you made a mistake, create a new migration to fix it.

---

## 6. Backend — NestJS

### 6.1 How the server starts

Entry point: `_server/src/main.ts`

```
NestFactory.create(AppModule)
  → CORS enabled (all origins, for dev)
  → GlobalValidationPipe (whitelist: true, transform: true)
  → Listens on PORT (default 3000)
```

`AppModule` imports: `ConfigModule`, `PrismaModule`, `AuthModule`, `UserModule`, `BookingModule`, `MessagesModule`, `ReviewsModule`, `NotificationsModule`, `CoinsModule`, `OffersModule`, `AdminModule`, `InternalModule`

### 6.2 Module system

```
src/
└── feature-name/
    ├── feature-name.module.ts
    ├── feature-name.controller.ts
    ├── feature-name.service.ts
    └── dto/
        └── some-action.dto.ts
```

**Controller** = HTTP routes, extracts params, calls service
**Service** = business logic, database calls via Prisma
**DTO** = request body shape + validation
**Module** = wires controller + service together

### 6.3 Authentication system

File: `_server/src/auth/auth.service.ts`

**Sign Up:** Check email unique → hash password with argon2 → create profile → return JWT

**Login:** Find by email → verify argon2 hash → return JWT

**Google Login:** Verify idToken with Google SDK → create/update profile → return JWT

**Token generation:**
```typescript
const payload = { sub: userId, email, role };
return {
  message: 'Authentication successful',
  access_token: this.jwtService.sign(payload),  // 7 day expiry
  user: { id: userId, email, role },
};
```

### 6.4 JWT strategy and guards

File: `_server/src/auth/jwt.strategy.ts`

**Flow:** Extract Bearer token → verify with `JWT_SECRET` → load user from DB → check banned/active → attach `{ userId, email, role }` to `req.user`

**Protect a route:**
```typescript
@UseGuards(AuthGuard('jwt'))
@Get('protected')
async myRoute(@Request() req: any) {
  const userId = req.user.userId || req.user.sub || req.user.id;
}
```

**Protect with role:**
```typescript
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('ADMIN')
@Get('admin-only')
```

### 6.5 User module

File: `_server/src/user/user.service.ts`

`getAllTutorProfile()` — all tutors, public fields, excludes banned/inactive
`getTutorFilteredBy(search?, subject?, maxCoins?)` — dynamic Prisma where
`getTutorDetailProfile(tutorID)` — single tutor + active offers
`updateProfile(userId, dto)` — patch own profile

### 6.6 Prisma service

```typescript
constructor(private prisma: PrismaService) {}

// Usage:
const user = await this.prisma.profiles.findUnique({ where: { id: userId } });
const tutors = await this.prisma.profiles.findMany({ where: { role: 'TUTOR' } });
```

### 6.7 How to add a new endpoint

**Step 1 — Service method:**
```typescript
async getMyProfile(userId: string) {
  const user = await this.prisma.profiles.findUnique({ where: { id: userId }, select: { id: true, email: true } });
  if (!user) throw new NotFoundException('User not found');
  return user;
}
```

**Step 2 — Controller route:**
```typescript
@UseGuards(AuthGuard('jwt'))
@Get('profile')
async getMyProfile(@Request() req: any) {
  const userId = req.user.userId || req.user.sub || req.user.id;
  if (!userId) throw new UnauthorizedException('Identification missing');
  return this.userService.getMyProfile(userId);
}
```

**Step 3 — Test + run.**

### 6.8 How to add a new module

```bash
mkdir -p _server/src/myfeature/dto
```

Create `myfeature.module.ts`, `myfeature.controller.ts`, `myfeature.service.ts`, then register in `app.module.ts`.

---

## 7. API Reference

**Base URL:** `http://localhost:3000` (dev)

**Auth header (protected routes):**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

Legend: 🔓 = No auth required | 🔒 = JWT required | 🛡️ = JWT + ADMIN role | ⚠️ = Dev-only endpoint

---

### AUTH

---

#### `GET /auth` 🔓
Health check.

**Response `200`:**
```
"You're at the right path, continue!"
```

---

#### `POST /auth/signup` 🔓
Register a new account.

**Request body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword",
  "role": "STUDENT"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `email` | string | Yes | Must be unique |
| `password` | string | Yes | Hashed with argon2 |
| `role` | string | No | `"STUDENT"` or `"TUTOR"`. Default: `"STUDENT"` |

**Response `201`:**
```json
{
  "message": "Authentication successful",
  "access_token": "eyJhbGci...",
  "user": {
    "id": "uuid",
    "email": "john@example.com",
    "role": "STUDENT"
  }
}
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Email already registered |
| `400` | Validation failed (e.g. invalid email format) |

---

#### `POST /auth/login` 🔓
Log in with email and password.

**Request body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword"
}
```

**Response `200`:** Same shape as signup `201`.

**Errors:**
| Status | When |
|--------|------|
| `401` | Email not found |
| `401` | Password incorrect |

---

#### `POST /auth/google` 🔓
Sign in or register via Google OAuth. Client must obtain a Google `idToken` using Google Sign-In SDK first.

**Request body:**
```json
{
  "idToken": "google-id-token-from-client",
  "role": "STUDENT"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `idToken` | string | Yes | From Google Sign-In SDK |
| `role` | string | Yes | `"STUDENT"` or `"TUTOR"` |

**Response `200`:**
```json
{
  "message": "Google Login successful!",
  "access_token": "eyJhbGci...",
  "user": {
    "id": "uuid",
    "email": "john@gmail.com",
    "role": "STUDENT",
    "full_name": "John Doe",
    "avatar_url": "https://lh3.googleusercontent.com/..."
  }
}
```

**Errors:**
| Status | When |
|--------|------|
| `401` | Invalid or expired Google token |
| `401` | Google token has no email |

---

#### `POST /auth/admin/login` 🔓
Admin login. Uses `admin_id` (10-digit numeric) not email.

**Request body:**
```json
{
  "admin_id": "1234567890",
  "password": "adminpassword"
}
```

**Response `200`:**
```json
{
  "message": "Authentication successful",
  "access_token": "eyJhbGci...",
  "user": {
    "id": "uuid",
    "role": "ADMIN"
  }
}
```

**Errors:**
| Status | When |
|--------|------|
| `401` | Admin ID not found |
| `401` | Password incorrect |

---

#### `GET /auth/me` 🔒
Get the authenticated user's full profile.

**Response `200`:**
```json
{
  "id": "uuid",
  "email": "john@example.com",
  "full_name": "John Doe",
  "username": "johndoe",
  "bio": "Math tutor",
  "avatar_url": "https://...",
  "role": "STUDENT",
  "coins_balance": 50,
  "user_status": "ONLINE",
  "overall_rating": 4.5,
  "rating_count": 12,
  "subjects": ["calculus", "algebra"],
  "verification_status": null,
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

**Errors:**
| Status | When |
|--------|------|
| `401` | Missing or invalid JWT |
| `403` | Account banned or deactivated |

---

#### `GET /auth/dev-token?email=...` 🔓 ⚠️
> **DEV ONLY — disabled when `NODE_ENV=production`.** Returns a real JWT for any existing user without requiring their password. Used to test protected endpoints quickly.

**Query params:**

| Param | Required | Notes |
|-------|----------|-------|
| `email` | Yes | Must be an existing user's email |

**Response `200`:**
```json
{
  "message": "Authentication successful",
  "access_token": "eyJhbGci...",
  "user": { "id": "uuid", "email": "...", "role": "STUDENT" }
}
```

**Errors:**
| Status | When |
|--------|------|
| `403` | `NODE_ENV=production` |
| `403` | No `?email=` param provided |
| `404` | Email not found |

---

### USER

---

#### `GET /user/tutors/all` 🔓
All active, non-banned tutor profiles with public fields.

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "full_name": "Alice Smith",
    "username": "alice",
    "avatar_url": "https://...",
    "bio": "Math tutor 5yr exp",
    "book_price_coins": 15,
    "subjects": ["calculus", "algebra"],
    "overall_rating": 4.8,
    "tutor_rating": 4.9,
    "rating_count": 24,
    "user_status": "ONLINE",
    "verification_status": "APPROVED"
  }
]
```

---

#### `GET /user/student` 🔓
All student profiles with public fields.

**Response `200`:** Array of `{ id, full_name, username, avatar_url, bio, student_rating }`

---

#### `GET /user/tutors` 🔓
Search and filter tutors.

**Query params:**

| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Case-insensitive search on `full_name` and `username` |
| `subject` | string | Filter by exact subject slug (e.g. `"calculus"`) |
| `maxCoins` | number | Maximum `book_price_coins` |

```
GET /user/tutors?search=math&subject=algebra&maxCoins=20
```

**Response `200`:** Same shape as `/user/tutors/all`.

---

#### `GET /user/tutor/:id` 🔓
Single tutor's full profile including their active offers.

**Response `200`:**
```json
{
  "id": "uuid",
  "full_name": "Alice Smith",
  "username": "alice",
  "bio": "Math tutor",
  "book_price_coins": 15,
  "subjects": ["calculus"],
  "overall_rating": 4.8,
  "tutor_rating": 4.9,
  "rating_count": 24,
  "user_status": "ONLINE",
  "verification_status": "APPROVED",
  "tutor_offers": [
    {
      "id": "offer-uuid",
      "title": "Calculus Basics — 1 Hour",
      "summary": "Intro to derivatives and integrals",
      "coins_per_hour": 15,
      "duration_minutes": 60,
      "subject_ids": ["subject-uuid"],
      "is_active": true
    }
  ]
}
```

**Errors:**
| Status | When |
|--------|------|
| `404` | Tutor ID doesn't exist or is not a TUTOR |

---

#### `GET /user/tutor/:id/availability` 🔓
Get a tutor's available time slots.

**Response `200`:**
```json
[
  {
    "id": "avail-uuid",
    "tutor_id": "uuid",
    "available_from": "2024-06-01T09:00:00.000Z",
    "available_to": "2024-06-01T12:00:00.000Z",
    "timezone": "Asia/Jakarta"
  }
]
```

---

#### `POST /user/tutor/availability` 🔒
Create a new availability slot (tutor only).

**Request body:**
```json
{
  "available_from": "2024-06-01T09:00:00.000Z",
  "available_to": "2024-06-01T12:00:00.000Z",
  "timezone": "Asia/Jakarta"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `available_from` | ISO8601 string | Yes | Slot start |
| `available_to` | ISO8601 string | Yes | Slot end |
| `timezone` | string | No | IANA timezone |

**Response `201`:**
```json
{
  "id": "avail-uuid",
  "tutor_id": "uuid",
  "available_from": "2024-06-01T09:00:00.000Z",
  "available_to": "2024-06-01T12:00:00.000Z",
  "timezone": "Asia/Jakarta"
}
```

**Errors:**
| Status | When |
|--------|------|
| `401` | Not authenticated |
| `400` | Invalid date format |

---

#### `DELETE /user/tutor/availability/:id` 🔒
Delete an availability slot. Only the owning tutor can delete.

**Response `200`:**
```json
{ "message": "Availability deleted." }
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the owner of this slot |
| `404` | Slot not found |

---

#### `POST /user/tutor/offer` 🔒
Create a tutor service offer.

**Request body:**
```json
{
  "title": "Calculus 1-on-1",
  "summary": "Master derivatives and integrals",
  "about": "Detailed explanation of the course...",
  "coins_per_hour": 15,
  "duration_minutes": 60,
  "subject_ids": ["subject-uuid-1"],
  "thumbnail_url": "https://example.com/thumb.jpg"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `title` | string | Yes | Max 100 chars |
| `summary` | string | No | Max 300 chars |
| `about` | string | No | Max 2000 chars |
| `coins_per_hour` | int | Yes | Min 1 |
| `duration_minutes` | int | No | Min 15. Default: 60 |
| `subject_ids` | string[] | No | Array of subject UUIDs |
| `thumbnail_url` | string | No | Must be valid URL |

**Response `201`:** The created offer object.

---

#### `GET /user/tutor/offer/mine` 🔒
Get all offers belonging to the authenticated tutor.

**Response `200`:** Array of offer objects.

---

#### `PATCH /user/tutor/offer/:id` 🔒
Update a tutor offer. All fields optional.

**Request body:** Same fields as `POST /user/tutor/offer`, all optional.

**Response `200`:** Updated offer object.

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the owner of this offer |
| `404` | Offer not found |

---

#### `DELETE /user/tutor/offer/:id` 🔒
Delete a tutor offer.

**Response `200`:**
```json
{ "message": "Offer deleted." }
```

---

#### `POST /user/tutor/verification` 🔒
Submit identity verification documents (tutor only). All PII is encrypted with AES-256-GCM before storage. Admin decrypts with the RSA private key.

**Request body:**
```json
{
  "phone": "+628123456789",
  "address": "Jl. Sudirman No. 1, Jakarta",
  "id_document_url": "https://storage.example.com/id.jpg",
  "certificate_urls": [
    "https://storage.example.com/cert1.jpg"
  ]
}
```

All fields are optional but at least one should be provided.

**Response `200`:**
```json
{ "message": "Verification submitted. Pending admin review." }
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Already submitted (verification record exists) |
| `403` | User is not a TUTOR |

---

#### `PATCH /user/status` 🔒
Update own presence status.

**Request body:**
```json
{ "status": "ONLINE" }
```

Valid values: `"ONLINE"`, `"OFFLINE"`, `"BUSY"`

**Response `200`:**
```json
{ "message": "Status updated.", "status": "ONLINE" }
```

---

#### `PATCH /user/update/profile` 🔒
Update the authenticated user's own profile. All fields optional.

**Request body:**
```json
{
  "full_name": "John Doe",
  "username": "john_doe",
  "bio": "Passionate math tutor.",
  "avatar_url": "https://example.com/avatar.png",
  "role": "TUTOR",
  "subjects": ["calculus", "algebra"]
}
```

**Response `200`:**
```json
{
  "message": "Profile updated successfully!",
  "user": {
    "id": "uuid",
    "email": "john@example.com",
    "full_name": "John Doe",
    "username": "john_doe",
    "bio": "Passionate math tutor.",
    "avatar_url": "https://example.com/avatar.png",
    "role": "TUTOR"
  }
}
```

**Errors:**
| Status | When |
|--------|------|
| `401` | No/invalid JWT |
| `404` | User no longer exists |

---

### BOOKING

See [Appendix A](#appendix-a--booking-state-machine--coin-flow) for full state machine and coin flow.

---

#### `POST /booking` 🔒
Create a booking request. Either `tutorOfferId` or `tutorId` must be provided. Booking starts as `pending` — coins are NOT deducted yet.

**Request body:**
```json
{
  "tutorOfferId": "offer-uuid",
  "startAt": "2024-06-15T09:00:00.000Z",
  "availabilityId": "avail-uuid",
  "description": "I need help with integration by parts."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `tutorOfferId` | UUID | Conditional | Either this or `tutorId` required |
| `tutorId` | UUID | Conditional | Either this or `tutorOfferId` required |
| `startAt` | ISO8601 | Yes | Session start time |
| `endAt` | ISO8601 | No | Auto-computed from offer duration if `tutorOfferId` given |
| `durationMinutes` | int | No | Min 15. Auto-set from offer if `tutorOfferId` given |
| `availabilityId` | UUID | No | Link to a specific tutor availability slot |
| `description` | string | No | Student's reason/context for the session |

**Response `201`:**
```json
{
  "id": "booking-uuid",
  "student_id": "uuid",
  "tutor_id": "uuid",
  "tutor_offer_id": "offer-uuid",
  "start_at": "2024-06-15T09:00:00.000Z",
  "end_at": "2024-06-15T10:00:00.000Z",
  "duration_minutes": 60,
  "coins_cost": 15,
  "status": "pending",
  "description": "I need help with integration by parts.",
  "expires_at": "2024-06-15T06:00:00.000Z",
  "created_at": "2024-06-14T20:00:00.000Z"
}
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Neither `tutorOfferId` nor `tutorId` provided |
| `400` | Student doesn't have enough coins |
| `404` | Offer not found or inactive |
| `409` | Tutor already has a booking in that time slot |

---

#### `GET /booking/student` 🔒
Get the authenticated student's bookings.

**Query params:**

| Param | Type | Notes |
|-------|------|-------|
| `status` | string | Filter by status (e.g. `pending`, `confirmed`, `completed`) |
| `from` | ISO8601 | Filter sessions starting after this date |
| `to` | ISO8601 | Filter sessions starting before this date |

**Response `200`:** Array of booking objects with tutor profile embedded.

---

#### `GET /booking/tutor` 🔒
Get the authenticated tutor's bookings. Same query params as student version.

---

#### `GET /booking/:id` 🔒
Get single booking detail. Only the student or tutor on that booking can access.

**Response `200`:**
```json
{
  "id": "booking-uuid",
  "student_id": "uuid",
  "tutor_id": "uuid",
  "start_at": "2024-06-15T09:00:00.000Z",
  "end_at": "2024-06-15T10:00:00.000Z",
  "duration_minutes": 60,
  "coins_cost": 15,
  "status": "confirmed",
  "description": "Need help with integration.",
  "expires_at": "2024-06-14T21:00:00.000Z",
  "next_action_hint": "Session starts in 120 minute(s).",
  "tutor_actions": ["complete", "propose-reschedule"],
  "student": { "id": "...", "full_name": "...", "avatar_url": "..." },
  "tutor": { "id": "...", "full_name": "...", "avatar_url": "..." }
}
```

**Errors:**
| Status | When |
|--------|------|
| `403` | You are not the student or tutor on this booking |
| `404` | Booking not found |

---

#### `GET /booking/:id/join` 🔒
Get Jitsi video call room info. Only accessible to the student and tutor on the booking.

**Response `200`:**
```json
{
  "room_name": "studyapp-booking-uuid",
  "password": "abc123",
  "join_url": "https://meet.jit.si/studyapp-booking-uuid",
  "role": "participant"
}
```

> The Jitsi room is derived from the booking ID — no external service call needed. Any Jitsi-compatible client can join using `room_name` and `password`.

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the student or tutor on this booking |
| `404` | Booking not found |

---

#### `PATCH /booking/:id/cancel` 🔒
Cancel a booking. Either student or tutor can cancel. If status is `pending`, coins are refunded to the student.

**Response `200`:**
```json
{ "message": "Booking cancelled. Coins have been refunded." }
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Booking is already completed, declined, or expired |
| `403` | Not the student or tutor on this booking |

---

#### `PATCH /booking/:id/confirm` 🔒
Tutor accepts the booking. **Coins are deducted from the student's balance at this point.**

**Response `200`:**
```json
{ "message": "Booking confirmed. Session is scheduled." }
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Student doesn't have enough coins (re-checked at confirm time) |
| `403` | You are not the tutor on this booking |
| `400` | Booking is not in `pending` status |

---

#### `PATCH /booking/:id/complete` 🔒
Mark session as completed. **Coins are released to the tutor.**

**Response `200`:**
```json
{ "message": "Session completed. Coins credited to tutor." }
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the tutor on this booking |
| `400` | Booking is not `confirmed` |

---

#### `PATCH /booking/:id/decline` 🔒
Tutor declines the booking request. Coins refunded to student.

**Response `200`:**
```json
{ "message": "Booking declined. Coins have been refunded to the student." }
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the tutor on this booking |
| `400` | Booking is not `pending` |

---

#### `PATCH /booking/:id/propose-price` 🔒
Tutor proposes a higher coin price. Student has **2 hours** to accept or reject.

**Request body:**
```json
{
  "proposed_coins": 25,
  "message": "The topic is advanced — requires extra preparation."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `proposed_coins` | int | Yes | Min 1. New total coins for the session |
| `message` | string | No | Reason for price change |

**Response `200`:**
```json
{ "message": "Price proposal sent. Student has 2 hours to respond." }
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the tutor |
| `400` | Booking not in `pending` status |

---

#### `PATCH /booking/:id/accept-price` 🔒
Student accepts the tutor's price proposal.

**Response `200`:**
```json
{ "message": "Price accepted. Booking is now pending tutor confirmation." }
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Not the student |
| `400` | No active price proposal |
| `400` | Price proposal has expired |

---

#### `PATCH /booking/:id/reject-price` 🔒
Student rejects the tutor's price proposal. Booking is cancelled, coins refunded.

**Response `200`:**
```json
{ "message": "Price rejected. Booking cancelled and coins refunded." }
```

---

#### `PATCH /booking/:id/propose-reschedule` 🔒
Tutor proposes a new time. Booking moves to `rescheduling` status.

**Request body:**
```json
{
  "new_start_at": "2024-06-16T10:00:00.000Z",
  "new_end_at": "2024-06-16T11:00:00.000Z",
  "reason": "I have a conflict at the original time."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `new_start_at` | ISO8601 | Yes | Proposed new start |
| `new_end_at` | ISO8601 | Yes | Proposed new end |
| `reason` | string | No | Explanation |

**Response `200`:**
```json
{ "message": "Reschedule proposed. Waiting for student response." }
```

---

#### `PATCH /booking/:id/accept-reschedule` 🔒
Student accepts the reschedule. Booking returns to `confirmed` with new times.

**Response `200`:**
```json
{ "message": "Reschedule accepted. Booking updated with new time." }
```

---

#### `PATCH /booking/:id/reject-reschedule` 🔒
Student rejects the reschedule. Booking returns to `confirmed` with original times.

**Response `200`:**
```json
{ "message": "Reschedule rejected. Original time kept." }
```

---

#### `POST /booking/:id/review` 🔒
Submit a review after a booking. Both student and tutor can review each other. Each party can only review once per booking.

**Request body:**
```json
{
  "rating": 5,
  "comment": "Great session, very patient and knowledgeable!"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `rating` | int | Yes | 1–5 stars |
| `comment` | string | No | Max 1000 chars |

**Response `201`:**
```json
{
  "id": "review-uuid",
  "booking_id": "booking-uuid",
  "reviewer_id": "uuid",
  "reviewee_id": "uuid",
  "rating": 5,
  "comment": "Great session!",
  "created_at": "2024-06-15T11:00:00.000Z"
}
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Already submitted a review for this booking |
| `403` | Not the student or tutor on this booking |
| `400` | Booking is not completed |

---

### MESSAGES

---

#### `POST /messages` 🔒
Send a direct message to another user.

**Request body:**
```json
{
  "to_id": "recipient-uuid",
  "content": "Hi, are you available this weekend?",
  "booking_id": "booking-uuid",
  "metadata": {}
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `to_id` | UUID | Yes | Recipient's user ID |
| `content` | string | Yes | Message text |
| `booking_id` | UUID | No | Associate message with a booking |
| `metadata` | object | No | Extra data |

**Response `201`:**
```json
{
  "id": "msg-uuid",
  "from_id": "uuid",
  "to_id": "uuid",
  "booking_id": null,
  "content": "Hi, are you available this weekend?",
  "is_read": false,
  "created_at": "2024-06-14T20:00:00.000Z"
}
```

---

#### `GET /messages/conversations` 🔒
Get all message threads (inbox). Returns one entry per conversation partner with last message and unread count.

**Response `200`:**
```json
[
  {
    "partner": {
      "id": "uuid",
      "full_name": "Alice Smith",
      "avatar_url": "https://...",
      "user_status": "ONLINE"
    },
    "last_message": {
      "content": "See you then!",
      "created_at": "2024-06-14T20:00:00.000Z",
      "from_id": "uuid"
    },
    "unread_count": 2
  }
]
```

---

#### `GET /messages/conversation/:userId` 🔒
Paginated message history with a specific user.

**Query params:**

| Param | Type | Notes |
|-------|------|-------|
| `cursor` | string | Message ID to paginate from (for infinite scroll) |
| `limit` | int | Messages per page. Default: 30 |

**Response `200`:**
```json
{
  "messages": [
    {
      "id": "msg-uuid",
      "from_id": "uuid",
      "to_id": "uuid",
      "content": "Hello!",
      "is_read": true,
      "created_at": "2024-06-14T20:00:00.000Z"
    }
  ],
  "next_cursor": "msg-uuid-oldest",
  "has_more": true
}
```

---

#### `PATCH /messages/conversation/:userId/read-all` 🔒
Mark all unread messages from a specific user as read.

**Response `200`:**
```json
{ "message": "All messages marked as read.", "updated_count": 3 }
```

---

#### `PATCH /messages/:id/read` 🔒
Mark a single message as read.

**Response `200`:**
```json
{ "message": "Message marked as read." }
```

---

### REVIEWS

---

#### `POST /reviews` 🔒
Submit a review. Alternative to `POST /booking/:id/review` when you have the booking ID in the body.

**Request body:**
```json
{
  "booking_id": "booking-uuid",
  "rating": 4,
  "comment": "Good session overall."
}
```

**Response `201`:** Review object.

---

#### `GET /reviews/tutor/:id` 🔓
Get all reviews for a tutor.

**Response `200`:**
```json
[
  {
    "id": "review-uuid",
    "booking_id": "uuid",
    "reviewer_id": "uuid",
    "rating": 5,
    "comment": "Excellent!",
    "created_at": "2024-06-15T11:00:00.000Z",
    "reviewer": {
      "full_name": "Bob Jones",
      "avatar_url": "https://..."
    }
  }
]
```

---

### NOTIFICATIONS

---

#### `GET /notifications` 🔒
Get paginated notifications for the authenticated user.

**Query params:**

| Param | Type | Default |
|-------|------|---------|
| `page` | int | 1 |
| `limit` | int | 20 |

**Response `200`:**
```json
{
  "notifications": [
    {
      "id": "notif-uuid",
      "type": "BOOKING_CONFIRMED",
      "payload": { "booking_id": "uuid" },
      "seen": false,
      "created_at": "2024-06-14T20:00:00.000Z"
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20
}
```

---

#### `GET /notifications/unseen-count` 🔒
Get count of unseen notifications (for badge indicator).

**Response `200`:**
```json
{ "count": 5 }
```

---

#### `PATCH /notifications/seen-all` 🔒
Mark all notifications as seen.

**Response `200`:**
```json
{ "message": "All notifications marked as seen." }
```

---

#### `PATCH /notifications/:id/seen` 🔒
Mark a single notification as seen.

**Response `200`:**
```json
{ "message": "Notification marked as seen." }
```

---

### COINS

See [Appendix B](#appendix-b--coin-system-explained) for full coin system explanation.

---

#### `GET /coins/packages` 🔓
List available coin packages for purchase.

**Response `200`:**
```json
[
  { "coins": 50,  "fiat": 50000,  "currency": "IDR" },
  { "coins": 120, "fiat": 110000, "currency": "IDR" },
  { "coins": 260, "fiat": 225000, "currency": "IDR" },
  { "coins": 550, "fiat": 450000, "currency": "IDR" }
]
```

> 1 coin = Rp 1,000. Bundle packages are cheaper per coin.

---

#### `GET /coins/balance` 🔒
Get the authenticated user's current coin balance.

**Response `200`:**
```json
{ "balance": 85, "currency": "coins" }
```

---

#### `GET /coins/history` 🔒
Get the user's coin transaction history.

**Response `200`:**
```json
[
  {
    "id": "tx-uuid",
    "amount": 50,
    "kind": "PURCHASE",
    "note": "Purchased 50 coin package",
    "ref_id": "order-uuid",
    "created_at": "2024-06-14T10:00:00.000Z"
  },
  {
    "id": "tx-uuid",
    "amount": -15,
    "kind": "BOOKING_PAYMENT",
    "note": "Booking payment",
    "ref_id": "booking-uuid",
    "created_at": "2024-06-14T15:00:00.000Z"
  }
]
```

---

#### `POST /coins/purchase` 🔒
Create a payment order to buy coins via Midtrans. Returns a Midtrans payment token.

**Request body:**
```json
{ "coins_amount": 120 }
```

`coins_amount` must be one of: `50`, `120`, `260`, `550`.

**Response `201`:**
```json
{
  "order_id": "order-uuid",
  "coins_amount": 120,
  "fiat_amount": 110000,
  "currency": "IDR",
  "provider": "midtrans",
  "snap_token": "midtrans-snap-token",
  "status": "PENDING"
}
```

> Use `snap_token` with the Midtrans Snap.js SDK or Flutter Midtrans plugin to show the payment UI. After payment, Midtrans calls the webhook automatically.

---

#### `POST /coins/webhook/midtrans` 🔓
Midtrans payment notification webhook. **Called by Midtrans, not your client.** Do not call this from your app.

> The server verifies the Midtrans signature. On successful payment, coins are credited to the user's balance automatically.

---

#### `POST /coins/dev/fulfill/:orderId` 🔓 ⚠️
> **DEV ONLY — disabled when `MIDTRANS_SERVER_KEY` is set in `.env`.** Manually mark a payment order as completed without real payment. Used for testing coin flows.

**Response `200`:**
```json
{ "message": "Order fulfilled. Coins credited.", "coins_added": 120 }
```

---

#### `POST /coins/withdraw` 🔒
Tutor requests to cash out coins to IDR. Minimum 10 coins. Creates a `PENDING` withdrawal request for admin to process.

**Request body:**
```json
{
  "coins_amount": 50,
  "account_name": "Alice Smith",
  "account_number": "1234567890",
  "payment_method": "BANK_TRANSFER",
  "bank_name": "BCA"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `coins_amount` | int | Yes | Min 10 |
| `account_name` | string | Yes | Bank account holder name |
| `account_number` | string | Yes | Bank account number |
| `payment_method` | string | No | `QRIS`/`BANK_TRANSFER`/`GOPAY`/`OVO`/`DANA`. Default: `QRIS` |
| `bank_name` | string | No | Required for `BANK_TRANSFER` |

**Response `201`:**
```json
{
  "id": "withdrawal-uuid",
  "coins_amount": 50,
  "idr_amount": 50000,
  "status": "PENDING",
  "payment_method": "BANK_TRANSFER"
}
```

**Errors:**
| Status | When |
|--------|------|
| `400` | Not enough coins |
| `400` | `coins_amount` below 10 |

---

#### `GET /coins/withdrawals` 🔒
Get the tutor's withdrawal request history.

**Response `200`:** Array of withdrawal objects.

---

### OFFERS

---

#### `GET /offers` 🔓
Browse all active tutor offers with filtering.

**Query params:**

| Param | Type | Notes |
|-------|------|-------|
| `search` | string | Search in offer title and tutor name |
| `subject` | string | Filter by subject UUID |
| `maxCoins` | int | Max `coins_per_hour` |
| `minRating` | float | Min tutor overall_rating |
| `page` | int | Default: 1 |
| `limit` | int | Default: 20 |

**Response `200`:**
```json
{
  "offers": [
    {
      "id": "offer-uuid",
      "title": "Calculus 1-on-1",
      "summary": "Master derivatives",
      "coins_per_hour": 15,
      "duration_minutes": 60,
      "thumbnail_url": "https://...",
      "tutor": {
        "id": "uuid",
        "full_name": "Alice Smith",
        "avatar_url": "https://...",
        "overall_rating": 4.8,
        "rating_count": 24
      }
    }
  ],
  "total": 45,
  "page": 1,
  "limit": 20
}
```

---

#### `GET /offers/:id` 🔓
Get full offer detail with tutor profile and recent reviews.

**Response `200`:**
```json
{
  "id": "offer-uuid",
  "title": "Calculus 1-on-1",
  "summary": "Master derivatives",
  "about": "Full description of the course...",
  "coins_per_hour": 15,
  "duration_minutes": 60,
  "subject_ids": ["subject-uuid"],
  "thumbnail_url": "https://...",
  "tutor": {
    "id": "uuid",
    "full_name": "Alice Smith",
    "bio": "Math tutor 5yr",
    "avatar_url": "https://...",
    "overall_rating": 4.8,
    "tutor_rating": 4.9,
    "rating_count": 24,
    "user_status": "ONLINE"
  },
  "recent_reviews": [
    {
      "rating": 5,
      "comment": "Excellent session!",
      "reviewer": { "full_name": "Bob", "avatar_url": "https://..." },
      "created_at": "2024-06-10T00:00:00.000Z"
    }
  ]
}
```

**Errors:**
| Status | When |
|--------|------|
| `404` | Offer not found or inactive |

---

### ADMIN

> All admin endpoints require JWT from `POST /auth/admin/login` with `ADMIN` role. Regular user JWTs will get `403 Forbidden`.

---

#### `POST /admin/create` 🔓 (bootstrap) / 🛡️ (afterwards)
Create an admin account. When no admins exist, `bootstrap_secret` is required instead of JWT. After at least one admin exists, requires `ADMIN` JWT.

**Request body:**
```json
{
  "full_name": "Super Admin",
  "password": "securepassword",
  "bootstrap_secret": "your-ADMIN_BOOTSTRAP_SECRET-value"
}
```

**Response `201`:**
```json
{
  "message": "Admin created.",
  "admin_id": "1234567890",
  "full_name": "Super Admin"
}
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Wrong bootstrap_secret (when no admins exist) |
| `403` | Not an admin (when admins already exist) |

---

#### `GET /admin/stats` 🛡️
Dashboard statistics.

**Response `200`:**
```json
{
  "users": { "total": 150, "students": 120, "tutors": 30 },
  "bookings": { "total": 89, "pending": 5, "confirmed": 12, "completed": 60 },
  "coins": { "total_in_circulation": 2400, "total_purchased": 5000 },
  "payments": { "total_orders": 45, "total_revenue_idr": 3500000 },
  "withdrawals": { "pending": 3, "total_paid_idr": 1200000 }
}
```

---

#### `GET /admin/users` 🛡️
List all users (paginated).

**Query params:** `page` (default 1), `limit` (default 20)

**Response `200`:**
```json
{
  "users": [
    {
      "id": "uuid",
      "email": "john@example.com",
      "full_name": "John Doe",
      "role": "STUDENT",
      "is_active": true,
      "is_banned": false,
      "coins_balance": 50,
      "created_at": "2024-01-01T00:00:00.000Z"
    }
  ],
  "total": 150,
  "page": 1,
  "limit": 20
}
```

---

#### `GET /admin/users/:id` 🛡️
Get full user detail including ban/penalty status.

---

#### `PATCH /admin/users/:id/ban` 🛡️
Permanently ban a user. Banned users get `403` on every protected endpoint.

**Request body:**
```json
{ "reason": "Repeated harassment of tutors." }
```

**Response `200`:**
```json
{ "message": "User banned." }
```

---

#### `PATCH /admin/users/:id/unban` 🛡️
Unban a user.

**Response `200`:**
```json
{ "message": "User unbanned." }
```

---

#### `PATCH /admin/users/:id/deactivate` 🛡️
Temporarily deactivate a user (reversible). Deactivated users get `403` on login.

**Response `200`:**
```json
{ "message": "User deactivated." }
```

---

#### `PATCH /admin/users/:id/activate` 🛡️
Re-activate a deactivated user.

---

#### `POST /admin/users/:id/warn` 🛡️
Issue a warning with penalty. Reduces visible rating and caps booking price for a set period.

**Request body:**
```json
{
  "penalty_days": 7,
  "rating_knock": 0.5,
  "price_pct": 20
}
```

| Field | Type | Notes |
|-------|------|-------|
| `penalty_days` | int | Min 1. Duration of penalty |
| `rating_knock` | float | 0–5. Subtracted from displayed rating |
| `price_pct` | int | 0–100. Max % price reduction enforced during penalty |

**Response `200`:**
```json
{ "message": "Warning issued. Penalty applied for 7 days." }
```

---

#### `POST /admin/users/:id/grant-coins` 🛡️ ⚠️
> **DEV/TESTING ONLY — remove before production.** Grant coins to any user without payment.

**Request body:**
```json
{ "amount": 100, "note": "Testing bonus" }
```

---

#### `GET /admin/tutors/pending` 🛡️
Get tutors with `PENDING` verification status.

**Response `200`:** Array of tutor profiles (without decrypted PII).

---

#### `GET /admin/tutors/:id` 🛡️
Get tutor detail with **decrypted** verification documents. Uses RSA private key to decrypt AES-256-GCM PII.

**Response `200`:**
```json
{
  "id": "uuid",
  "full_name": "Alice Smith",
  "verification_status": "PENDING",
  "verification": {
    "phone": "+628123456789",
    "address": "Jl. Sudirman No. 1, Jakarta",
    "id_document_url": "https://storage.example.com/id.jpg",
    "certificate_urls": ["https://storage.example.com/cert1.jpg"],
    "submitted_at": "2024-06-01T00:00:00.000Z"
  }
}
```

---

#### `PATCH /admin/tutors/:id/verify` 🛡️
Approve or reject a tutor's verification.

**Request body:**
```json
{
  "status": "APPROVED",
  "admin_notes": "Documents verified. ID matches name."
}
```

`status` must be `"APPROVED"` or `"REJECTED"`.

**Response `200`:**
```json
{ "message": "Tutor verification updated." }
```

---

#### `GET /admin/bookings` 🛡️
List all bookings (paginated). `page`, `limit` query params.

---

#### `GET /admin/bookings/:id` 🛡️
Get full booking detail including student and tutor info.

---

#### `GET /admin/bookings/:id/join` 🛡️
Get Jitsi join info for a booking. Admin joins as **moderator**.

**Response `200`:**
```json
{
  "room_name": "studyapp-booking-uuid",
  "password": "abc123",
  "join_url": "https://meet.jit.si/studyapp-booking-uuid",
  "role": "moderator"
}
```

---

#### `GET /admin/payments` 🛡️
List payment orders (paginated). Query params: `page`, `limit`, `status` (`PENDING`/`COMPLETED`/`FAILED`/`REFUNDED`).

---

#### `POST /admin/refunds` 🛡️
Process a refund on a payment order.

**Request body:**
```json
{
  "order_id": "order-uuid",
  "decision": "APPROVED",
  "reason": "Student complained of technical issues."
}
```

`decision` must be `"APPROVED"` or `"REJECTED"`.

**Response `200`:**
```json
{ "message": "Refund approved. Coins returned to student." }
```

---

#### `GET /admin/withdrawals` 🛡️
List withdrawal requests (paginated). Query params: `page`, `limit`, `status` (`PENDING`/`APPROVED`/`REJECTED`/`PAID`).

---

#### `PATCH /admin/withdrawals/:id` 🛡️
Process a withdrawal request.

**Request body:**
```json
{
  "decision": "PAID",
  "admin_notes": "Transferred via BCA on 2024-06-15."
}
```

`decision` must be `"APPROVED"`, `"REJECTED"`, or `"PAID"`.

**Response `200`:**
```json
{ "message": "Withdrawal marked as PAID." }
```

---

### INTERNAL (Cron)

> These endpoints are called by **Vercel Cron every 10 minutes**. Do not call them from a client app. They require a secret header.

**Auth:** `x-internal-secret: <INTERNAL_SECRET env var value>`

---

#### `GET /internal/notify-upcoming-sessions`
Send `SESSION_REMINDER` notifications for sessions starting in 10–20 minutes.

**Response `200`:**
```json
{ "message": "Notified 3 upcoming sessions." }
```

**Errors:**
| Status | When |
|--------|------|
| `403` | Missing or wrong `x-internal-secret` header |

---

#### `GET /internal/process-expirations`
Auto-expire pending bookings older than 1 hour, clear expired price proposals, auto-complete sessions that ended more than 1 hour ago with no manual completion.

**Response `200`:**
```json
{
  "expired_bookings": 2,
  "cleared_price_proposals": 1,
  "auto_completed": 3
}
```

---

## 8. Frontend — Flutter

### 8.1 How the app starts

Entry point: `lib/main.dart`

```dart
void main() {
  runApp(StudyApp());
}
```

`StudyApp` returns `MaterialApp.router` with theme from `AppTheme`, routes from `AppRoutes`, initial route pointing to splash.

### 8.2 Routing system

File: `lib/routes/app_routes.dart`

| Route | Screen |
|-------|--------|
| `/` | Splash screen |
| `/onboarding` | Onboarding |
| `/login` | Login |
| `/register` | Register |
| `/role-selection` | Role selection |
| `/update-profile` | Update profile |
| `/student` | Student dashboard |
| `/teacher` | Teacher dashboard |
| `/chat` | Chat detail |
| `/subscription` | Subscription plans |
| `/payment` | Payment |
| `/payment-success` | Payment success |

```dart
Navigator.of(context).pushNamed('/login');
Navigator.of(context).pushReplacementNamed('/student');
Navigator.of(context).pushNamed('/chat', arguments: { 'userId': '123' });
```

### 8.3 Theme system

- `lib/core/themes/app_theme.dart` — ThemeData
- `lib/core/themes/app_colors.dart` — color constants
- `lib/core/themes/app_typography.dart` — text styles
- `lib/core/themes/app_sizes.dart` — spacing/radii

```dart
Container(color: AppColors.primary)
Text('Hello', style: AppTypography.headline)
SizedBox(height: AppSizes.spacingMd)
```

### 8.4 Core services

Singletons in `lib/core/services/`:
- `auth_state.dart` — stores JWT + user info
- `user_api_service.dart` — all user API calls

### 8.5 How AuthState works

```dart
// After login/signup:
AuthState.instance.setFromResponse(responseBody);

// Read anywhere:
final token = AuthState.instance.accessToken;
final role = AuthState.instance.role;
final isLoggedIn = AuthState.instance.isLoggedIn;
final headers = AuthState.instance.authHeaders;
// → { 'Content-Type': 'application/json', 'Authorization': 'Bearer eyJ...' }

// Logout:
AuthState.instance.clear();
```

### 8.6 How UserApiService works

```dart
final result = await UserApiService.instance.updateProfile(
  username: 'john_doe',
  fullName: 'John Doe',
  role: 'STUDENT',
);

if (result.success) {
  print(result.user?['username']);
} else {
  print(result.errorMessage);
}
```

### 8.7 How to add a new API call

**Step 1 — Result class:**
```dart
class GetTutorsResult {
  final bool success;
  final List<Map<String, dynamic>>? tutors;
  final String? errorMessage;

  const GetTutorsResult._({required this.success, this.tutors, this.errorMessage});

  factory GetTutorsResult.success(List<Map<String, dynamic>> tutors) =>
      GetTutorsResult._(success: true, tutors: tutors);

  factory GetTutorsResult.error(String message) =>
      GetTutorsResult._(success: false, errorMessage: message);
}
```

**Step 2 — Service method:**
```dart
Future<GetTutorsResult> getTutors({String? search, String? subject}) async {
  final queryParams = <String, String>{};
  if (search != null) queryParams['search'] = search;
  if (subject != null) queryParams['subject'] = subject;

  try {
    final uri = Uri.parse('${AppConfig.API_URL}/user/tutors')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return GetTutorsResult.success((data as List).cast<Map<String, dynamic>>());
    }
    return GetTutorsResult.error('Failed to load tutors');
  } catch (e) {
    return GetTutorsResult.error('Network error: $e');
  }
}
```

**Step 3 — Use in widget:**
```dart
final result = await UserApiService.instance.getTutors(search: 'math');
if (result.success) {
  setState(() => _tutors = result.tutors!);
} else {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
}
```

**Rules:**
- Protected endpoints: pass `headers: AuthState.instance.authHeaders`
- Always wrap in `try/catch` and return `.error(...)` in catch
- Never throw from a service method

### 8.8 How to add a new screen

```dart
// lib/features/student/screens/tutor_detail_screen.dart
class TutorDetailScreen extends StatefulWidget {
  final String tutorId;
  const TutorDetailScreen({super.key, required this.tutorId});
  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  Map<String, dynamic>? _tutor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTutor();
  }

  Future<void> _loadTutor() async {
    // call API service here
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: Text(_tutor?['full_name'] ?? 'Tutor')));
  }
}
```

### 8.9 How to add a new route

```dart
// In app_routes.dart:
static const String tutorDetail = '/tutor-detail';

AppRoutes.tutorDetail: (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return TutorDetailScreen(tutorId: args['tutorId'] as String);
},

// Navigate:
Navigator.of(context).pushNamed(AppRoutes.tutorDetail, arguments: { 'tutorId': 'some-uuid' });
```

### 8.10 Shared widgets

```dart
PrimaryButton(label: 'Continue', onPressed: () {}, isLoading: _isLoading, size: ButtonSize.large)
TextInput(controller: _ctrl, label: 'Email', hint: 'Enter email', prefixIcon: Icons.email)
PasswordTextField(controller: _pwCtrl, label: 'Password')
AvatarWidget(imageUrl: user.avatarUrl, name: user.fullName, size: AvatarSize.lg)
SearchInput(onChanged: (q) => _search(q), onFilterTap: () => _openFilters())
```

---

## 9. Feature Modules

### 9.1 Auth feature

`lib/features/auth/screens/`

| Screen | Route | What it does |
|--------|-------|-------------|
| `splash_screen.dart` | `/` | Logo animation, auto-nav after 2500ms |
| `onboarding_screen.dart` | `/onboarding` | 4-page swipeable intro |
| `login_screen.dart` | `/login` | Email + Google login |
| `register_screen.dart` | `/register` | Email registration |
| `update_profile_screen.dart` | `/update-profile` | Name, username, bio, role |

### 9.2 Student feature

`lib/features/student/screens/`

| Screen | Purpose |
|--------|---------|
| `student_dashboard.dart` | 5-tab: Home, Explore, Learning, Messages, Profile |
| `course_detail_screen.dart` | Tabbed: Overview, Curriculum, Reviews |
| `live_class_screen.dart` | Pre-join screen for live sessions |

### 9.3 Teacher feature

`lib/features/teacher/screens/`

| Screen | Purpose |
|--------|---------|
| `teacher_dashboard.dart` | 5-tab: Home, Courses, Students, Earnings, Profile |

### 9.4 Chat feature

`lib/features/chat/screens/`

| Screen | Purpose |
|--------|---------|
| `chat_detail_screen.dart` | Message list, typing indicator, input |

### 9.5 Subscription feature

`lib/features/subscription/screens/`

| Screen | Purpose |
|--------|---------|
| `subscription_plans_screen.dart` | Free/Premium/Pro plans, monthly/yearly toggle |
| `payment_screen.dart` | Payment method + order summary |
| `payment_success_screen.dart` | Animated success + transaction details |

---

## 10. Data Models

Flutter-side models in `lib/models/`:

```dart
UserModel { id, name, email, avatarUrl, role: UserRole }
CourseModel { id, title, description, thumbnailUrl, teacher, price, category, level, status, sections, rating, studentsCount }
TeacherModel extends UserModel { bio, expertise, education, rating, studentsCount, coursesCount }
LiveClassModel { id, title, teacher, scheduledAt, durationMinutes, viewerCount, maxViewers, subject, meetingUrl, isLive }
```

---

## 11. Testing

### 11.1 How to run tests

```bash
cd _server && npm test
cd _server && npm run test:watch
cd _server && npm run test:cov
flutter test
```

Current: 62 tests across 5 suites, all passing.

### 11.2 How to write a new service test

```typescript
const mockPrisma = {
  myTable: { findUnique: jest.fn(), findMany: jest.fn(), create: jest.fn(), update: jest.fn() },
};

describe('MyFeatureService', () => {
  let service: MyFeatureService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [MyFeatureService, { provide: PrismaService, useValue: mockPrisma }],
    }).compile();
    service = module.get<MyFeatureService>(MyFeatureService);
  });

  it('should return data', async () => {
    mockPrisma.myTable.findUnique.mockResolvedValue({ id: '1' });
    const result = await service.doSomething('1');
    expect(result).toEqual({ id: '1' });
  });

  it('should throw NotFoundException', async () => {
    mockPrisma.myTable.findUnique.mockResolvedValue(null);
    await expect(service.doSomething('ghost')).rejects.toThrow(NotFoundException);
  });
});
```

### 11.3 How to write a new controller test

```typescript
const mockService = { doSomething: jest.fn() };
const mockAuthGuard = { canActivate: jest.fn().mockReturnValue(true) };

const module = await Test.createTestingModule({
  controllers: [MyFeatureController],
  providers: [{ provide: MyFeatureService, useValue: mockService }],
})
  .overrideGuard(AuthGuard('jwt'))
  .useValue(mockAuthGuard)
  .compile();
```

### 11.4 Test configuration explained

```json
{
  "rootDir": "src",
  "testRegex": ".*\\.spec\\.ts$",
  "transform": { "^.+\\.(t|j)s$": "ts-jest" },
  "moduleNameMapper": {
    "^src/(.*)$": "<rootDir>/$1",
    "^(\\.{1,2}/.*)\\.js$": "$1"
  },
  "testEnvironment": "node"
}
```

---

## 12. Common How-To Guide

### Check if user is logged in (Flutter)

```dart
if (AuthState.instance.isLoggedIn) {
  // proceed
} else {
  Navigator.of(context).pushReplacementNamed('/login');
}
```

### Make an authenticated HTTP request manually (Flutter)

```dart
final response = await http.get(
  Uri.parse('${AppConfig.API_URL}/some/endpoint'),
  headers: AuthState.instance.authHeaders,
);
final data = jsonDecode(response.body);
```

### Redirect after login based on role

```dart
final role = AuthState.instance.role;
Navigator.of(context).pushReplacementNamed(role == 'TUTOR' ? '/teacher' : '/student');
```

### Log out

```dart
AuthState.instance.clear();
Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
```

### Handle loading states

```dart
Future<void> _doAction() async {
  setState(() => _isLoading = true);
  final result = await UserApiService.instance.updateProfile(username: 'test');
  if (!mounted) return; // ALWAYS check after await
  setState(() => _isLoading = false);
  if (result.success) { /* handle */ }
  else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage!))); }
}
```

### Protect a NestJS route (backend)

```typescript
@UseGuards(AuthGuard('jwt'))
@Get('protected')
async myRoute(@Request() req: any) {
  const userId = req.user.userId || req.user.sub || req.user.id;
}
```

### Query the database in a service

```typescript
constructor(private prisma: PrismaService) {}

const user = await this.prisma.profiles.findUnique({ where: { id: userId } });
const tutors = await this.prisma.profiles.findMany({ where: { role: 'TUTOR' } });
const updated = await this.prisma.profiles.update({ where: { id: userId }, data: { bio: 'New bio' } });
```

### Run a database migration

```bash
cd _server
npx prisma migrate dev --name add_column_to_profiles
npx prisma generate
npx prisma migrate deploy  # production
```

### Inspect the database visually

```bash
cd _server && npx prisma studio
# Opens at http://localhost:5555
```

### Change API base URL for production

Edit `lib/core/constants/app_config.dart`:
```dart
static const String API_URL = "https://your-production-api.com";
```

---

## 13. Troubleshooting

### `Cannot find module 'src/prisma.service'`

Add to `package.json` jest config:
```json
"moduleNameMapper": { "^src/(.*)$": "<rootDir>/$1" }
```

### `Cannot find module './internal/class.js'`

Add to jest `moduleNameMapper`:
```json
"^(\\.{1,2}/.*)\\.js$": "$1"
```

### API returns `401 Unauthorized`

1. Check `Authorization: Bearer <token>` header is present
2. Check `AuthState.instance.accessToken` is not null
3. Token expires in 7 days — get a new one
4. Check `JWT_SECRET` in `.env` matches what signed the token

### Flutter app can't reach the API

| Platform | Correct API URL |
|----------|----------------|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator | `http://localhost:3000` |
| Physical device | `http://192.168.x.x:3000` (LAN IP) |
| Production | `https://your-domain.com` (HTTPS) |

### Prisma migration fails

```bash
npx prisma migrate reset   # dev only — DESTROYS ALL DATA
npx prisma migrate dev
```

### `PrismaClientInitializationError` on server start

- Check `DATABASE_URL` in `.env` is correct
- Check Supabase project is active (free tier pauses after inactivity)
- Run `npx prisma db push` to test connection

### `argon2` native module error on install

```bash
npm install --ignore-scripts
npm rebuild argon2
```

### Test fails: `TypeError: A dynamic import callback was invoked without --experimental-vm-modules`

```typescript
// Bad:
const { NotFoundException } = await import('@nestjs/common');
// Good:
import { NotFoundException } from '@nestjs/common';
```

### `403 Forbidden` — "Your account has been banned."

Admin has banned the account. Only admin can unban via `PATCH /admin/users/:id/unban`.

### `403 Forbidden` — "Account is deactivated."

Admin temporarily deactivated account. Admin can re-activate via `PATCH /admin/users/:id/activate`.

---

## Appendix A — Booking State Machine & Coin Flow

### Status transitions

```
                    ┌─────────────────────────────────────┐
                    │                                     │
             [student creates]                            │
                    │                                     │
                    ▼                                     │
              ┌──────────┐  [tutor declines]  ┌──────────┐│
              │ pending  │ ─────────────────► │ declined ││
              └──────────┘                    └──────────┘│
                 │  │  │                                   │
   [tutor        │  │  │ [tutor proposes price]            │
    confirms]    │  │  │         │                         │
        │        │  │  │         ▼                         │
        │        │  │  │  [waiting for student]            │
        │        │  │  │    student accepts ──► back to pending
        │        │  │  │    student rejects ──► cancelled  │
        │        │  │  │                                   │
        │   [either party cancels]                         │
        │        │  │                                      │
        │        ▼  ▼                                      │
        │  ┌──────────┐                                    │
        │  │cancelled │                                    │
        │  └──────────┘                                    │
        │                                                  │
        ▼                                                  │
 ┌────────────┐  [tutor proposes reschedule]  ┌────────────┐
 │ confirmed  │ ──────────────────────────►  │rescheduling│
 └────────────┘                              └────────────┘
       │  │                                   │          │
       │  │                              accepts      rejects
       │  │                                 │            │
       │  │                          ┌──────────┐        │
       │  │                          │confirmed │◄───────┘
       │  │                          └──────────┘
       │  │
  [tutor  │ [either party cancels]
completes]│
       │  │
       ▼  ▼
 ┌──────────┐  ┌──────────┐
 │completed │  │cancelled │
 └──────────┘  └──────────┘

Auto-transitions (via /internal/process-expirations cron, every 10min):
  pending (> 1hr old) ──────────────────────────────────► expired
  price_proposal_expires_at passed ──────────────────────► proposal cleared
  confirmed + end_at + 1hr passed + no completion ───────► completed (auto)
```

### Coin flow per transition

| Transition | Coins action |
|------------|-------------|
| `POST /booking` | No coin change (reservation only) |
| `PATCH /:id/confirm` | Student balance `-coins_cost`, held |
| `PATCH /:id/complete` | Tutor balance `+coins_cost` (coins released) |
| `PATCH /:id/cancel` (from pending) | No coins moved (none held) |
| `PATCH /:id/cancel` (from confirmed) | Student balance `+coins_cost` (refund) |
| `PATCH /:id/decline` | No coins moved (pending → declined) |
| `PATCH /:id/reject-price` | No coins moved (stays pending / cancelled) |
| Auto-expire | No coins moved (was pending) |
| Auto-complete | Tutor balance `+coins_cost` |

---

## Appendix B — Coin System Explained

### What are coins?

Coins are StudyApp's in-app currency. **1 coin = Rp 1,000 IDR.**

Students buy coins with real money (IDR via Midtrans QRIS). They spend coins to book tutor sessions. Tutors earn coins when sessions complete. Tutors can withdraw coins back to IDR via bank transfer/e-wallet.

### Purchase flow

```
1. GET /coins/packages         → pick a package
2. POST /coins/purchase        → create Midtrans order, get snap_token
3. [Midtrans payment UI]       → user pays
4. POST /coins/webhook/midtrans → Midtrans notifies server (automatic)
5. GET /coins/balance          → coins credited, balance updated
```

### Packages (hardcoded)

| Coins | IDR | Per-coin rate |
|-------|-----|--------------|
| 50 | Rp 50,000 | Rp 1,000/coin |
| 120 | Rp 110,000 | Rp 917/coin |
| 260 | Rp 225,000 | Rp 865/coin |
| 550 | Rp 450,000 | Rp 818/coin |

### Dev testing without real payment

```bash
# 1. Create an order
curl -X POST http://localhost:3000/coins/purchase \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"coins_amount": 50}'
# Returns: { "order_id": "uuid", ... }

# 2. Fulfill it without payment (dev only)
curl -X POST http://localhost:3000/coins/dev/fulfill/<order_id>
# Returns: { "message": "Order fulfilled. Coins credited.", "coins_added": 50 }
```

> `POST /coins/dev/fulfill/:orderId` is disabled automatically when `MIDTRANS_SERVER_KEY` is present in `.env`. Do not use in production.

### Withdrawal flow (tutor cashout)

```
1. POST /coins/withdraw         → request cashout, coins held
2. Admin reviews via GET /admin/withdrawals
3. Admin transfers money manually (bank/QRIS)
4. PATCH /admin/withdrawals/:id (decision: "PAID") → coins deducted, status updated
```

---

## Appendix C — Vibe Coding Prompts

Paste these into Cursor, Claude, or any AI coding assistant to bootstrap a client that uses the StudyApp API.

---

### Prompt 1 — Web App (React / Vue / plain JS)

```
You are building a web app that consumes the StudyApp REST API. Here is everything you need to know:

## API
Base URL: http://localhost:3000   (replace with production URL when deploying)
All responses are JSON.
All request bodies are JSON — set Content-Type: application/json.

## Authentication
Protected endpoints require:
  Authorization: Bearer <access_token>

Get a token:
  POST /auth/login   { email, password }  → { access_token, user: { id, email, role } }
  POST /auth/signup  { email, password, role: "STUDENT"|"TUTOR" }  → same shape
  POST /auth/google  { idToken, role }  → same shape

Token expires in 7 days. Store in localStorage:
  localStorage.setItem('token', data.access_token)
  localStorage.setItem('user', JSON.stringify(data.user))

Read it:
  const token = localStorage.getItem('token')
  const headers = { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }

## Roles
- STUDENT: can browse tutors, book sessions, send messages, buy coins
- TUTOR: can create offers, manage availability, confirm/complete bookings, withdraw coins
- ADMIN: admin panel access only (use POST /auth/admin/login with admin_id + password)

## Coin system
In-app currency. 1 coin = Rp 1,000. Students buy coins, spend on bookings. Tutors earn coins, withdraw to IDR.
  GET /coins/packages → available packages to buy
  POST /coins/purchase { coins_amount: 50|120|260|550 } → creates Midtrans order
  GET /coins/balance → { balance: 85 }

## Key endpoints

### Auth
GET  /auth                          → health check
POST /auth/signup                   → register
POST /auth/login                    → login
POST /auth/google                   → Google OAuth login
GET  /auth/me       [JWT]           → own profile
GET  /auth/dev-token?email=...      → DEV ONLY — get JWT without password

### Users / Tutors
GET  /user/tutors/all               → all tutors (public)
GET  /user/tutors?search=&subject=&maxCoins=  → filter tutors
GET  /user/tutor/:id                → single tutor + offers
GET  /user/tutor/:id/availability   → tutor's available slots
PATCH /user/update/profile [JWT]    → update own profile { full_name, username, bio, avatar_url, role }
PATCH /user/status [JWT]            → { status: "ONLINE"|"OFFLINE"|"BUSY" }

### Tutor offer management [JWT — tutor only]
POST   /user/tutor/offer            → create offer { title, coins_per_hour, duration_minutes, ... }
GET    /user/tutor/offer/mine       → own offers
PATCH  /user/tutor/offer/:id        → update offer
DELETE /user/tutor/offer/:id        → delete offer
POST   /user/tutor/availability     → create slot { available_from, available_to, timezone }
DELETE /user/tutor/availability/:id → delete slot

### Booking [JWT]
POST   /booking                     → create { tutorOfferId OR tutorId, startAt, description }
GET    /booking/student             → student's bookings (?status=&from=&to=)
GET    /booking/tutor               → tutor's bookings
GET    /booking/:id                 → single booking detail
GET    /booking/:id/join            → Jitsi room info { room_name, password, join_url }
PATCH  /booking/:id/confirm         → tutor confirms (coins deducted from student)
PATCH  /booking/:id/decline         → tutor declines (no coins moved)
PATCH  /booking/:id/cancel          → cancel (coins refunded if was confirmed)
PATCH  /booking/:id/complete        → tutor marks done (coins released to tutor)
PATCH  /booking/:id/propose-price   → tutor proposes new price { proposed_coins, message }
PATCH  /booking/:id/accept-price    → student accepts price
PATCH  /booking/:id/reject-price    → student rejects price (booking cancelled)
PATCH  /booking/:id/propose-reschedule → tutor reschedules { new_start_at, new_end_at, reason }
PATCH  /booking/:id/accept-reschedule  → student accepts
PATCH  /booking/:id/reject-reschedule  → student rejects (keeps original time)
POST   /booking/:id/review          → { rating: 1-5, comment }

### Messages [JWT]
POST  /messages                     → { to_id, content, booking_id? }
GET   /messages/conversations       → inbox (all threads + unread count)
GET   /messages/conversation/:userId?cursor=&limit= → paginated history
PATCH /messages/conversation/:userId/read-all → mark all read
PATCH /messages/:id/read            → mark one read

### Notifications [JWT]
GET   /notifications?page=&limit=   → paginated notifications
GET   /notifications/unseen-count   → { count: 5 }
PATCH /notifications/seen-all       → mark all seen
PATCH /notifications/:id/seen       → mark one seen

### Reviews
POST /reviews [JWT]                 → { booking_id, rating, comment }
GET  /reviews/tutor/:id             → public reviews for a tutor

### Offers (browse)
GET  /offers?search=&subject=&maxCoins=&minRating=&page=&limit= → paginated offer list
GET  /offers/:id                    → offer detail + tutor + recent reviews

### Coins [JWT]
GET  /coins/packages                → available packages (public)
GET  /coins/balance                 → current balance
GET  /coins/history                 → transaction log
POST /coins/purchase                → { coins_amount: 50|120|260|550 } → creates Midtrans order
POST /coins/dev/fulfill/:orderId    → DEV ONLY — skip payment
POST /coins/withdraw                → { coins_amount, account_name, account_number, payment_method?, bank_name? }
GET  /coins/withdrawals             → own withdrawal history

## Error handling
All errors return: { statusCode, message, error }
401 = missing/invalid JWT
403 = banned/deactivated/wrong role
404 = not found
400 = validation error (message is array of strings)
409 = booking time conflict

## Important warnings
- GET /auth/dev-token and POST /coins/dev/fulfill are DEV ONLY, disabled in production
- Coins are deducted at PATCH /booking/:id/confirm, NOT at booking creation
- Booking auto-expires (pending > 1hr) — show expiry countdown from booking.expires_at
- Price proposals expire in 2 hours (booking.price_proposal_expires_at)
- Notifications are polled — GET /notifications/unseen-count every ~30s for badge updates
```

---

### Prompt 2 — Flutter App

```
You are building a Flutter app that consumes the StudyApp REST API. Here is everything you need to know:

## Setup
Add to pubspec.yaml:
  dependencies:
    http: ^1.0.0
    shared_preferences: ^2.0.0

## API
Base URL: http://10.0.2.2:3000   (Android emulator)
          http://localhost:3000   (iOS simulator)
          http://192.168.x.x:3000 (physical device — use your machine's LAN IP)
          https://your-api.com    (production)

Define it as a constant:
  const String apiUrl = 'http://10.0.2.2:3000';

## Authentication
After login/signup, store the JWT:
  import 'package:shared_preferences/shared_preferences.dart';
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', data['access_token']);
  await prefs.setString('user_id', data['user']['id']);
  await prefs.setString('user_role', data['user']['role']);

Read it:
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

Auth headers:
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

## Example API call pattern
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> login(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    // handle error
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Login failed');
  } catch (e) {
    rethrow;
  }
}

## IMPORTANT — after every await on a widget:
  if (!mounted) return;  // widget might have been disposed

## All endpoints (grouped by feature)

### Auth
POST /auth/signup   body: { email, password, role: "STUDENT"|"TUTOR" }
POST /auth/login    body: { email, password }
POST /auth/google   body: { idToken, role }
GET  /auth/me       [JWT] → full profile
GET  /auth/dev-token?email=...   ⚠️ DEV ONLY

### User
GET  /user/tutors/all
GET  /user/tutors?search=&subject=&maxCoins=
GET  /user/tutor/:id
GET  /user/tutor/:id/availability
PATCH /user/update/profile  [JWT]  body: { full_name?, username?, bio?, avatar_url?, role? }
PATCH /user/status  [JWT]  body: { status: "ONLINE"|"OFFLINE"|"BUSY" }

### Tutor management [JWT]
POST   /user/tutor/offer   body: { title, coins_per_hour, duration_minutes?, summary?, about?, subject_ids?, thumbnail_url? }
GET    /user/tutor/offer/mine
PATCH  /user/tutor/offer/:id
DELETE /user/tutor/offer/:id
POST   /user/tutor/availability  body: { available_from, available_to, timezone? }
DELETE /user/tutor/availability/:id
POST   /user/tutor/verification  body: { phone?, address?, id_document_url?, certificate_urls? }

### Booking [JWT]
POST   /booking   body: { tutorOfferId?, tutorId?, startAt, endAt?, durationMinutes?, availabilityId?, description? }
GET    /booking/student?status=&from=&to=
GET    /booking/tutor?status=&from=&to=
GET    /booking/:id
GET    /booking/:id/join          → { room_name, password, join_url, role }
PATCH  /booking/:id/confirm
PATCH  /booking/:id/decline
PATCH  /booking/:id/cancel
PATCH  /booking/:id/complete
PATCH  /booking/:id/propose-price   body: { proposed_coins, message? }
PATCH  /booking/:id/accept-price
PATCH  /booking/:id/reject-price
PATCH  /booking/:id/propose-reschedule  body: { new_start_at, new_end_at, reason? }
PATCH  /booking/:id/accept-reschedule
PATCH  /booking/:id/reject-reschedule
POST   /booking/:id/review   body: { rating: 1-5, comment? }

### Messages [JWT]
POST  /messages   body: { to_id, content, booking_id?, metadata? }
GET   /messages/conversations
GET   /messages/conversation/:userId?cursor=&limit=
PATCH /messages/conversation/:userId/read-all
PATCH /messages/:id/read

### Notifications [JWT]
GET   /notifications?page=&limit=
GET   /notifications/unseen-count
PATCH /notifications/seen-all
PATCH /notifications/:id/seen

### Offers (public)
GET  /offers?search=&subject=&maxCoins=&minRating=&page=&limit=
GET  /offers/:id

### Reviews
POST /reviews [JWT]  body: { booking_id, rating, comment? }
GET  /reviews/tutor/:id

### Coins [JWT]
GET  /coins/packages
GET  /coins/balance
GET  /coins/history
POST /coins/purchase  body: { coins_amount: 50|120|260|550 }
POST /coins/dev/fulfill/:orderId   ⚠️ DEV ONLY
POST /coins/withdraw  body: { coins_amount, account_name, account_number, payment_method?, bank_name? }
GET  /coins/withdrawals

## Response shape for auth endpoints
{ "message": "...", "access_token": "eyJ...", "user": { "id": "uuid", "email": "...", "role": "STUDENT" } }

## Error shape
{ "statusCode": 400, "message": "Email already registered", "error": "Bad Request" }
message can be a String or List<String> for validation errors — handle both cases.

## Booking state machine
pending → confirmed (tutor confirms, coins deducted from student)
confirmed → completed (tutor marks done, coins credited to tutor)
pending/confirmed → cancelled (either party, coins refunded if confirmed)
pending → declined (tutor declines, no coins moved)
pending → expired (auto after 1hr, no coins moved)
confirmed → rescheduling (tutor proposes new time) → confirmed/cancelled

## Coin flow
Student: buy coins → spend on booking confirm → get refund on cancel/decline
Tutor: earn on booking complete → withdraw to bank

## Dev-only endpoints (disabled in production)
GET  /auth/dev-token?email=...          → JWT without password
POST /coins/dev/fulfill/:orderId        → coins without real payment
POST /admin/users/:id/grant-coins [JWT+ADMIN] → give coins to any user
```

---

*Last updated: 2026-05-22*
