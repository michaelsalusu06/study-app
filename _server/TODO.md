# Backend TODO

> Work in order. Top = highest priority.

---

## ✅ Done

- [x] Auth — signup, login, Google OAuth, JWT
- [x] User module — getAllTutors, filterTutors, getTutorDetail, updateProfile
- [x] Booking — create, list (student/tutor), cancel, confirm, complete (coins released)
- [x] GET /booking/:id — single booking detail, auth-gated to student/tutor only
- [x] Conflict detection on createBooking — 409 if tutor slot overlaps pending/confirmed
- [x] Admin — stats, user list, tutor verify, payment orders, refunds, withdrawal management
- [x] Coin system — balance, purchase order, history, QRIS stub, withdrawal request
- [x] DB schema — coins_cost, book_price_coins, coins_per_hour, withdrawal_requests
- [x] DB migrated to Supabase + schema pushed (is*active, is_banned, penalty*\*, tutor_availability_id, declined status)
- [x] TutorOffer CRUD — create, list mine, update, soft-delete (with coins_per_hour)
- [x] UpdateProfile — book_price_coins + subjects fields added
- [x] Reviews — POST /reviews AND POST /booking/:id/review (both work), GET /reviews/tutor/:id
- [x] Duplicate review blocked per booking
- [x] Notifications — GET, unseen-count, mark seen, mark all seen
- [x] Booking events → notifications (NEW_BOOKING, CONFIRMED, CANCELLED, COMPLETED, DECLINED)
- [x] Filter bookings by status — ?status= on student/tutor list
- [x] TutorAvailability CRUD — create slot, list future slots, delete slot
- [x] Booked slot hidden from availability list (pending/confirmed blocks it)
- [x] Booking → link to availability slot (optional availabilityId)
- [x] Booking decline — tutor passes, coins refunded, student notified
- [x] Admin account control — ban/unban, activate/deactivate, warn (penalty)
- [x] Admin grant-coins ⚠️ TEMP
- [x] Auth guard — banned/inactive → 403 on every request, no bypass
- [x] Public listings filter — banned/inactive tutors hidden everywhere
- [x] Penalty system — rating knocked, price discounted during penalty window

---

## 🔴 Should have (important, not blocking but users will notice)

- [ ] **GET /booking/tutor/pending** — dedicated "incoming requests" list for tutor dashboard
  - Tutors need a fast way to see only pending bookings without filtering manually

- [ ] **POST /booking/:id/review by tutor** — currently only student can review
  - Tutors should rate students too (student_rating field already in schema)

- [ ] **Rate limiting** — brute-force protection on /auth/login and /auth/admin/login
  - No throttle now; someone can try infinite passwords

- [ ] **Input sanitization on free-text fields** — bio, comment, offer title/summary
  - class-validator strips types but doesn't sanitize XSS in string fields

- [ ] **GET /user/me/offers** alias — tutor needs their own offer list without knowing their ID
  - Already exists as GET /user/tutor/offer/mine — just needs documenting / confirming frontend uses it

---

## 🟢 Nice to have (quality of life, ship later)

- [ ] **Messages / Chat**
  - `GET /messages/:userId` — conversation thread (paginated)
  - `POST /messages` — send message
  - `PATCH /messages/:userId/read` — mark read
  - Schema already has `messages` table — just needs controller + service

- [ ] **Pagination** on GET /booking/student, GET /booking/tutor, GET /user/tutors
  - Currently returns all rows; fine for testing, will hurt at scale

- [ ] **Refresh token system** — current JWT expires and user gets logged out with no recovery

- [ ] **Subjects endpoint** — `GET /subjects` (public, seed subjects table, use as dropdown data)

- [ ] **Tutor search by availability date** — `GET /user/tutors?date=2026-06-01`
  - Students want to find tutors free on a specific day

- [ ] **Booking history summary** — `GET /user/stats` (sessions completed, coins spent/earned, avg rating)
  - Useful for both student and tutor profile pages

- [ ] **Offer view count / popularity** — track how many times an offer was viewed
  - Simple increment on GET /offers/:id, helps tutors know what's getting clicks

- [ ] **Admin audit log** — log every admin action (ban, warn, verify) to a table
  - Right now admin actions are not traceable after the fact

- [ ] **Webhook retry / idempotency** for Midtrans — currently no retry guard on duplicate webhooks

---

## ⚠️ Before any demo or deploy

- [ ] DELETE `devToken()` from `auth.controller.ts` and `auth.service.ts`
- [ ] REMOVE or gate `POST /admin/users/:id/grant-coins` behind `NODE_ENV !== 'production'`
- [ ] REMOVE or gate `POST /coins/dev/fulfill/:orderId` behind `NODE_ENV !== 'production'`
- [ ] Set strong `JWT_SECRET` in prod env (not default/dev value)
- [ ] Verify `MIDTRANS_IS_PRODUCTION=true` and real server key before payment goes live
