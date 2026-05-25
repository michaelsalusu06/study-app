import {
  Controller,
  ForbiddenException,
  Get,
  Headers,
  HttpCode,
} from '@nestjs/common';
import { timingSafeEqual } from 'crypto';
import { PrismaService } from 'src/prisma.service';

@Controller('internal')
export class InternalController {
  constructor(private prisma: PrismaService) {}

  private checkSecret(secret: string) {
    const expected = process.env.INTERNAL_SECRET ?? '';
    if (!secret || secret.length !== expected.length) {
      throw new ForbiddenException('Unauthorized.');
    }
    const match = timingSafeEqual(Buffer.from(secret), Buffer.from(expected));
    if (!match) throw new ForbiddenException('Unauthorized.');
  }

  // POST /internal/notify-upcoming-sessions
  // Vercel Cron: every 10 min. Sends SESSION_REMINDER when session is 10-20 min away.
  @Get('notify-upcoming-sessions')
  @HttpCode(200)
  async notifyUpcomingSessions(@Headers('x-internal-secret') secret: string) {
    this.checkSecret(secret);

    const now = new Date();
    const windowStart = new Date(now.getTime() + 10 * 60_000);
    const windowEnd = new Date(now.getTime() + 20 * 60_000);

    const upcoming = await this.prisma.bookings.findMany({
      where: {
        status: 'confirmed',
        start_at: { gte: windowStart, lte: windowEnd },
        session_notified_at: null,
      },
      select: { id: true, student_id: true, tutor_id: true, start_at: true },
    });

    if (upcoming.length === 0) return { notified: 0 };

    const ops: any[] = [];
    for (const booking of upcoming) {
      const payload = {
        booking_id: booking.id,
        start_at: booking.start_at,
      };
      ops.push(
        this.prisma.notifications.create({
          data: { profile_id: booking.student_id, type: 'SESSION_REMINDER', payload },
        }),
        this.prisma.notifications.create({
          data: { profile_id: booking.tutor_id, type: 'SESSION_REMINDER', payload },
        }),
        this.prisma.bookings.update({
          where: { id: booking.id },
          data: { session_notified_at: now },
        }),
      );
    }

    await this.prisma.$transaction(ops);
    return { notified: upcoming.length };
  }

  // POST /internal/process-expirations
  // Vercel Cron: every 10 min.
  // 1. Auto-expire pending bookings past expires_at (1 hour) → status = expired, coins refunded
  // 2. Clear stale price proposals past price_proposal_expires_at (2 hours)
  @Get('process-expirations')
  @HttpCode(200)
  async processExpirations(@Headers('x-internal-secret') secret: string) {
    this.checkSecret(secret);

    const now = new Date();

    // ── 1. Expire pending bookings ────────────────────────────────────────────
    const expiredBookings = await this.prisma.bookings.findMany({
      where: {
        status: 'pending',
        expires_at: { lt: now },
      },
      select: { id: true, student_id: true, tutor_id: true, coins_cost: true },
    });

    const bookingOps: any[] = [];
    for (const booking of expiredBookings) {
      const coinsCost = booking.coins_cost ?? 0;

      bookingOps.push(
        this.prisma.bookings.update({
          where: { id: booking.id },
          data: { status: 'expired', updated_at: now },
        }),
      );

      if (coinsCost > 0) {
        bookingOps.push(
          this.prisma.profiles.update({
            where: { id: booking.student_id },
            data: { coins_balance: { increment: coinsCost } },
          }),
          this.prisma.coin_transactions.create({
            data: {
              profile_id: booking.student_id,
              amount: coinsCost,
              kind: 'REFUND',
              ref_id: booking.id,
              note: 'Booking expired — tutor did not respond in time, coins refunded',
            },
          }),
        );
      }

      bookingOps.push(
        this.prisma.notifications.create({
          data: {
            profile_id: booking.student_id,
            type: 'BOOKING_EXPIRED',
            payload: { booking_id: booking.id, coins_refunded: coinsCost },
          },
        }),
        this.prisma.notifications.create({
          data: {
            profile_id: booking.tutor_id,
            type: 'BOOKING_EXPIRED_TUTOR',
            payload: { booking_id: booking.id },
          },
        }),
      );
    }

    // ── 2. Clear expired price proposals ─────────────────────────────────────
    const expiredProposals = await this.prisma.bookings.findMany({
      where: {
        price_proposal_expires_at: { lt: now },
        price_proposed_coins: { not: null },
      },
      select: { id: true, student_id: true, tutor_id: true, price_proposed_coins: true },
    });

    for (const booking of expiredProposals) {
      bookingOps.push(
        this.prisma.bookings.update({
          where: { id: booking.id },
          data: {
            price_proposed_coins: null,
            price_proposal_message: null,
            price_proposal_expires_at: null,
            updated_at: now,
          },
        }),
        this.prisma.notifications.create({
          data: {
            profile_id: booking.tutor_id,
            type: 'PRICE_PROPOSAL_EXPIRED',
            payload: { booking_id: booking.id },
          },
        }),
        this.prisma.notifications.create({
          data: {
            profile_id: booking.student_id,
            type: 'PRICE_PROPOSAL_EXPIRED',
            payload: { booking_id: booking.id },
          },
        }),
      );
    }

    // ── 3. Auto-complete stale confirmed sessions ─────────────────────────────
    // Confirmed bookings that ended > 2 hours ago and tutor never marked complete
    const staleThreshold = new Date(now.getTime() - 2 * 60 * 60_000);
    const staleSessions = await this.prisma.bookings.findMany({
      where: { status: 'confirmed', end_at: { lt: staleThreshold } },
      select: { id: true, student_id: true, tutor_id: true, coins_cost: true, duration_minutes: true },
    });

    for (const session of staleSessions) {
      const coinsCost = session.coins_cost ?? 0;
      bookingOps.push(
        this.prisma.bookings.update({
          where: { id: session.id },
          data: { status: 'completed', updated_at: now },
        }),
      );
      if (coinsCost > 0) {
        bookingOps.push(
          this.prisma.profiles.update({
            where: { id: session.tutor_id },
            data: { coins_balance: { increment: coinsCost } },
          }),
          this.prisma.coin_transactions.create({
            data: {
              profile_id: session.tutor_id,
              amount: coinsCost,
              kind: 'TUTOR_EARNING',
              ref_id: session.id,
              note: `Session auto-completed — ${session.duration_minutes} min`,
            },
          }),
        );
      }
      bookingOps.push(
        this.prisma.notifications.create({
          data: {
            profile_id: session.student_id,
            type: 'SESSION_COMPLETED',
            payload: { booking_id: session.id, auto_completed: true },
          },
        }),
        this.prisma.notifications.create({
          data: {
            profile_id: session.tutor_id,
            type: 'SESSION_COMPLETED',
            payload: { booking_id: session.id, coins_earned: coinsCost, auto_completed: true },
          },
        }),
      );
    }

    if (bookingOps.length > 0) {
      await this.prisma.$transaction(bookingOps);
    }

    return {
      expired_bookings: expiredBookings.length,
      cleared_price_proposals: expiredProposals.length,
      auto_completed_sessions: staleSessions.length,
    };
  }
}
