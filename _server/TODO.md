# Backend TODO

> Work in order. Top = highest priority.

---

## ✅ Done

- [x] Auth — signup, login, Google OAuth, JWT
- [x] User module — getAllTutors, filterTutors, getTutorDetail, updateProfile
- [x] Booking — create, list (student/tutor), cancel, confirm, **complete** (coins released)
- [x] GET /booking/:id — single booking detail, auth-gated to student/tutor only
- [x] Conflict detection on createBooking — 409 if tutor slot overlaps pending/confirmed
- [x] Admin — stats, user list, tutor verify, payment orders, refunds, withdrawal management
- [x] Coin system — balance, purchase order, history, QRIS stub, withdrawal request
- [x] DB schema — coins_cost, book_price_coins, coins_per_hour, withdrawal_requests
- [x] DB migrated to Supabase (db push ✅)
- [x] TutorOffer CRUD — create, list mine, update, soft-delete (with coins_per_hour)
- [x] UpdateProfile — book_price_coins + subjects fields added
- [x] Reviews — POST /reviews, GET /reviews/tutor/:id, auto-recalculates overall_rating
- [x] Notifications module — GET /notifications, PATCH seen/:id, PATCH seen-all, unseen-count
- [x] Booking events → notifications wired (NEW_BOOKING, BOOKING_CONFIRMED, BOOKING_CANCELLED, SESSION_COMPLETED)

---

## 🟡 Important — needed for full flow

- [ ] **1. Filter bookings by status**
  - `GET /booking/student?status=pending` and `GET /booking/tutor?status=confirmed`
  - Optional `?status=` query param on both list endpoints

- [ ] **2. TutorAvailability**
  - `POST /user/tutor/availability` — add slot (tutor only)
  - `GET /user/tutor/:id/availability` — get available slots (public)
  - `DELETE /user/tutor/availability/:id` — remove slot (tutor only)

---

## 🟢 Nice to have

- [ ] **3. Filter tutors by coin price** — `GET /user/tutors?maxCoins=20`
  - Replace `maxPrice` (fiat) filter in `getTutorFilteredBy` with `maxCoins` (coin-based)

- [ ] **4. Subjects endpoint** — `GET /subjects` (public)
  - Seed the subjects table, expose as dropdown data

- [ ] **5. Messages / Chat**
  - `GET /messages/:userId` — conversation (paginated)
  - `POST /messages` — send message
  - `PATCH /messages/:userId/read` — mark read

- [ ] **6. Pagination** on `GET /booking/student`, `GET /booking/tutor`, `GET /user/tutors`

- [ ] **7. Refresh token system**

---

## ⚠️ Before any demo or deploy

- [ ] **DELETE `devToken()`** from `auth.controller.ts` and `auth.service.ts` (lines marked `// ⚠️ TEMP`)
