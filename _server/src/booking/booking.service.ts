import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { PrismaService } from 'src/prisma.service';
import { DailyService } from 'src/daily/daily.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { ProposeRescheduleDto } from './dto/propose-reschedule.dto';
import { ProposePriceDto } from './dto/propose-price.dto';

const BOOKING_EXPIRY_MS = 60 * 60_000;        // 1 hour — tutor auto-decline
const PRICE_PROPOSAL_EXPIRY_MS = 2 * 60 * 60_000; // 2 hours — student must respond

@Injectable()
export class BookingService {
  constructor(
    private prisma: PrismaService,
    private daily: DailyService,
  ) {}

  // ─── helpers ────────────────────────────────────────────────────────────────

  private inCallWindow(start_at: Date, end_at: Date): boolean {
    const now = Date.now();
    return (
      now >= start_at.getTime() - 15 * 60_000 &&
      now <= end_at.getTime() + 30 * 60_000
    );
  }

  private nextActionHint(status: string, start_at: Date, role: 'student' | 'tutor'): string {
    const now = new Date();
    switch (status) {
      case 'pending':
        return role === 'student'
          ? 'Waiting for tutor to confirm your booking.'
          : 'Review and confirm or decline this booking request.';
      case 'confirmed': {
        const mins = Math.round((start_at.getTime() - now.getTime()) / 60_000);
        if (mins > 0) return `Session starts in ${mins} minute(s).`;
        return 'Session is active — join the call.';
      }
      case 'rescheduling':
        return role === 'student'
          ? 'Tutor proposed a reschedule. Accept or reject below.'
          : 'Waiting for student to accept your reschedule proposal.';
      case 'completed':
        return role === 'student'
          ? 'Session completed. You can now leave a review.'
          : 'Session completed. Coins have been credited to your balance.';
      case 'cancelled':
        return 'Booking was cancelled. Coins have been refunded.';
      case 'declined':
        return 'Booking was declined by the tutor. Coins have been refunded.';
      case 'expired':
        return 'Booking request expired — tutor did not respond in time. Coins have been refunded.';
      default:
        return '';
    }
  }

  private tutorActions(status: string, hasPriceProposal: boolean): string[] {
    if (hasPriceProposal) return []; // waiting on student response — tutor can't act
    switch (status) {
      case 'pending':   return ['confirm', 'decline', 'propose-reschedule', 'propose-price'];
      case 'confirmed': return ['complete', 'propose-reschedule'];
      default:          return [];
    }
  }

  // ─── create ─────────────────────────────────────────────────────────────────

  async createBooking(studentId: string, dto: CreateBookingDto) {
    if (!dto.tutorOfferId && !dto.tutorId) {
      throw new BadRequestException('Provide either tutorOfferId or tutorId.');
    }

    let tutorId = dto.tutorId!;
    let durationMinutes = dto.durationMinutes ?? 60;
    let coinRatePerHour: number;
    let endAt: Date;

    if (dto.tutorOfferId) {
      const offer = await this.prisma.tutor_offers.findFirst({
        where: { id: dto.tutorOfferId, is_active: true },
        include: { profiles: true },
      });
      if (!offer) throw new NotFoundException('Offer not found or no longer active.');

      tutorId = offer.tutor_id;
      durationMinutes = offer.duration_minutes;
      coinRatePerHour = offer.coins_per_hour;
      endAt = new Date(new Date(dto.startAt).getTime() + durationMinutes * 60_000);
    } else {
      const tutor = await this.prisma.profiles.findFirst({
        where: { id: tutorId, role: 'TUTOR' },
      });
      if (!tutor) throw new NotFoundException('Tutor not found.');
      if (!dto.durationMinutes) {
        throw new BadRequestException('durationMinutes is required for manual bookings.');
      }

      coinRatePerHour = tutor.book_price_coins;
      durationMinutes = dto.durationMinutes;
      endAt = dto.endAt
        ? new Date(dto.endAt)
        : new Date(new Date(dto.startAt).getTime() + durationMinutes * 60_000);
    }

    if (tutorId === studentId) throw new BadRequestException('Cannot book yourself.');

    let availabilityId: string | undefined;
    if (dto.availabilityId) {
      const slot = await this.prisma.tutor_availabilities.findFirst({
        where: { id: dto.availabilityId, tutor_id: tutorId },
      });
      if (!slot) {
        throw new BadRequestException(
          'Availability slot not found or does not belong to this tutor.',
        );
      }
      availabilityId = dto.availabilityId;
    }

    const newStart = new Date(dto.startAt);
    const conflict = await this.prisma.bookings.findFirst({
      where: {
        tutor_id: tutorId,
        status: { in: ['pending', 'confirmed'] },
        start_at: { lt: endAt },
        end_at: { gt: newStart },
      },
    });
    if (conflict) {
      throw new BadRequestException(
        `Tutor is already booked from ${conflict.start_at.toISOString()} to ${conflict.end_at.toISOString()}.`,
      );
    }

    const coinsCost = Math.ceil((coinRatePerHour * durationMinutes) / 60);

    const student = await this.prisma.profiles.findUnique({
      where: { id: studentId },
      select: { coins_balance: true },
    });
    if (!student) throw new NotFoundException('Student not found.');
    if (student.coins_balance < coinsCost) {
      throw new BadRequestException(
        `Insufficient coins. Need ${coinsCost}, have ${student.coins_balance}. Please top up first.`,
      );
    }

    const expiresAt = new Date(Date.now() + BOOKING_EXPIRY_MS);

    const [booking] = await this.prisma.$transaction([
      this.prisma.bookings.create({
        data: {
          student_id: studentId,
          tutor_id: tutorId,
          tutor_offer_id: dto.tutorOfferId,
          tutor_availability_id: availabilityId,
          start_at: new Date(dto.startAt),
          end_at: endAt,
          duration_minutes: durationMinutes,
          price: 0,
          coins_cost: coinsCost,
          status: 'pending',
          description: dto.description,
          expires_at: expiresAt,
        },
        select: {
          id: true,
          tutor_id: true,
          student_id: true,
          start_at: true,
          end_at: true,
          duration_minutes: true,
          coins_cost: true,
          status: true,
          description: true,
          expires_at: true,
          created_at: true,
        },
      }),
      this.prisma.profiles.update({
        where: { id: studentId },
        data: { coins_balance: { decrement: coinsCost } },
      }),
      this.prisma.coin_transactions.create({
        data: {
          profile_id: studentId,
          amount: -coinsCost,
          kind: 'BOOKING_PAYMENT',
          note: `Booking with tutor — ${durationMinutes} min`,
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: tutorId,
          type: 'NEW_BOOKING',
          payload: {
            student_id: studentId,
            duration_minutes: durationMinutes,
            coins_cost: coinsCost,
            description: dto.description ?? null,
          },
        },
      }),
    ]);

    return booking;
  }

  // ─── read ────────────────────────────────────────────────────────────────────

  async getBookingById(bookingId: string, userId: string) {
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
      include: {
        profiles_bookings_tutor_idToprofiles: {
          select: {
            id: true,
            full_name: true,
            username: true,
            avatar_url: true,
            bio: true,
            overall_rating: true,
            rating_count: true,
            subjects: true,
            user_status: true,
            last_seen_at: true,
          },
        },
        profiles_bookings_student_idToprofiles: {
          select: {
            id: true,
            full_name: true,
            username: true,
            avatar_url: true,
            user_status: true,
            last_seen_at: true,
          },
        },
        tutor_offers: {
          select: {
            id: true,
            title: true,
            summary: true,
            coins_per_hour: true,
            duration_minutes: true,
          },
        },
        reviews: {
          where: { reviewer_id: userId },
          select: { id: true, rating: true, comment: true, created_at: true },
        },
      },
    });

    if (!booking) throw new NotFoundException('Booking not found.');

    const isStudent = booking.student_id === userId;
    const isTutor = booking.tutor_id === userId;
    if (!isStudent && !isTutor) throw new ForbiddenException('Not your booking.');

    const status = booking.status as string;

    const rescheduleProposal =
      status === 'rescheduling'
        ? {
            proposed_start: booking.reschedule_proposed_start,
            proposed_end: booking.reschedule_proposed_end,
            notes: booking.reschedule_notes,
            requested_by: booking.reschedule_requested_by,
          }
        : null;

    const priceProposal = booking.price_proposed_coins
      ? {
          proposed_coins: booking.price_proposed_coins,
          message: booking.price_proposal_message,
          expires_at: booking.price_proposal_expires_at,
          original_coins: booking.coins_cost,
          difference: booking.price_proposed_coins - (booking.coins_cost ?? 0),
        }
      : null;

    const base = {
      id: booking.id,
      status: booking.status,
      start_at: booking.start_at,
      end_at: booking.end_at,
      duration_minutes: booking.duration_minutes,
      coins_cost: booking.coins_cost,
      description: booking.description,
      expires_at: booking.expires_at,
      created_at: booking.created_at,
      updated_at: booking.updated_at,
      offer: booking.tutor_offers,
      reschedule_proposal: rescheduleProposal,
      price_proposal: priceProposal,
      next_action: this.nextActionHint(status, booking.start_at, isStudent ? 'student' : 'tutor'),
    };

    if (isStudent) {
      return {
        ...base,
        tutor: booking.profiles_bookings_tutor_idToprofiles,
        review: booking.reviews[0] ?? null,
        refund_eligible: ['pending', 'confirmed', 'rescheduling'].includes(status),
      };
    }

    return {
      ...base,
      student: booking.profiles_bookings_student_idToprofiles,
      coins_to_earn: booking.coins_cost,
      available_actions: this.tutorActions(status, !!booking.price_proposed_coins),
    };
  }

  async getStudentBookings(studentId: string, status?: string) {
    return this.prisma.bookings.findMany({
      where: {
        student_id: studentId,
        ...(status ? { status: status as any } : {}),
      },
      select: {
        id: true,
        start_at: true,
        end_at: true,
        duration_minutes: true,
        coins_cost: true,
        status: true,
        description: true,
        expires_at: true,
        price_proposed_coins: true,
        price_proposal_expires_at: true,
        reschedule_proposed_start: true,
        reschedule_proposed_end: true,
        created_at: true,
        profiles_bookings_tutor_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true, username: true, user_status: true },
        },
        tutor_offers: { select: { title: true } },
      },
      orderBy: { start_at: 'desc' },
    });
  }

  async getTutorBookings(tutorId: string, status?: string) {
    return this.prisma.bookings.findMany({
      where: {
        tutor_id: tutorId,
        ...(status ? { status: status as any } : {}),
      },
      select: {
        id: true,
        start_at: true,
        end_at: true,
        duration_minutes: true,
        coins_cost: true,
        status: true,
        description: true,
        expires_at: true,
        price_proposed_coins: true,
        price_proposal_message: true,
        price_proposal_expires_at: true,
        reschedule_proposed_start: true,
        reschedule_proposed_end: true,
        created_at: true,
        profiles_bookings_student_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true, username: true, user_status: true },
        },
        tutor_offers: { select: { title: true } },
      },
      orderBy: { start_at: 'desc' },
    });
  }

  // ─── join call ──────────────────────────────────────────────────────────────
  // Primary: Jitsi (always works, no API key needed)
  // Upgrade: Daily.co when DAILY_API_KEY + DAILY_DOMAIN are set in env

  private jitsiJoin(bookingId: string) {
    const hash = crypto
      .createHash('sha256')
      .update(bookingId + (process.env.JWT_SECRET ?? 'secret'))
      .digest('hex');
    return {
      provider: 'jitsi' as const,
      meeting_url: `https://meet.jit.si/studyapp-${bookingId}`,
      room_password: hash.slice(0, 8),
      token: null,
      room_name: `studyapp-${bookingId}`,
    };
  }

  async getJoinInfo(bookingId: string, userId: string) {
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
      select: {
        id: true,
        student_id: true,
        tutor_id: true,
        status: true,
        start_at: true,
        end_at: true,
        room_name: true,
        profiles_bookings_student_idToprofiles: { select: { full_name: true } },
        profiles_bookings_tutor_idToprofiles: { select: { full_name: true } },
      },
    });

    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.student_id !== userId && booking.tutor_id !== userId) {
      throw new ForbiddenException('Not your booking.');
    }
    if (booking.status !== 'confirmed') {
      throw new BadRequestException('Booking must be confirmed to join the call.');
    }

    const now = Date.now();
    const windowStart = booking.start_at.getTime() - 15 * 60_000;
    const windowEnd = booking.end_at.getTime() + 30 * 60_000;

    if (now < windowStart) {
      const mins = Math.round((windowStart - now) / 60_000);
      throw new BadRequestException(`Call opens ${mins} minute(s) before the session starts.`);
    }
    if (now > windowEnd) {
      throw new BadRequestException('Session window has ended.');
    }

    const base = {
      start_at: booking.start_at,
      end_at: booking.end_at,
      student_name: booking.profiles_bookings_student_idToprofiles.full_name,
      tutor_name: booking.profiles_bookings_tutor_idToprofiles.full_name,
    };

    // Use Daily.co only when fully configured AND room was created
    const useDailyco =
      booking.room_name &&
      process.env.DAILY_API_KEY &&
      process.env.DAILY_DOMAIN;

    if (useDailyco) {
      const { token, room_url } = await this.daily.createToken(
        booking.room_name!,
        userId,
        booking.end_at,
        false,
      );
      return { ...base, provider: 'daily' as const, token, meeting_url: room_url, room_name: booking.room_name, room_password: null };
    }

    // Default: Jitsi — no API key needed, open in new tab
    return { ...base, ...this.jitsiJoin(bookingId) };
  }

  // ─── price negotiation ───────────────────────────────────────────────────────

  async proposePrice(bookingId: string, tutorId: string, dto: ProposePriceDto) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId) {
      throw new ForbiddenException('Only the tutor can propose a price change.');
    }
    if (booking.status !== 'pending') {
      throw new BadRequestException('Price can only be proposed on pending bookings.');
    }
    if (dto.proposed_coins <= (booking.coins_cost ?? 0)) {
      throw new BadRequestException('Proposed price must be higher than current price.');
    }
    if (booking.price_proposed_coins) {
      throw new BadRequestException('A price proposal is already pending.');
    }

    const expiresAt = new Date(Date.now() + PRICE_PROPOSAL_EXPIRY_MS);

    const [updated] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: {
          price_proposed_coins: dto.proposed_coins,
          price_proposal_message: dto.message,
          price_proposal_expires_at: expiresAt,
          updated_at: new Date(),
        },
        select: {
          id: true,
          coins_cost: true,
          price_proposed_coins: true,
          price_proposal_message: true,
          price_proposal_expires_at: true,
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: booking.student_id,
          type: 'PRICE_PROPOSED',
          payload: {
            booking_id: bookingId,
            original_coins: booking.coins_cost,
            proposed_coins: dto.proposed_coins,
            message: dto.message ?? null,
            expires_at: expiresAt,
          },
        },
      }),
    ]);

    return updated;
  }

  async acceptPrice(bookingId: string, studentId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.student_id !== studentId) {
      throw new ForbiddenException('Only the student can accept a price proposal.');
    }
    if (!booking.price_proposed_coins) {
      throw new BadRequestException('No price proposal on this booking.');
    }
    if (booking.price_proposal_expires_at && booking.price_proposal_expires_at < new Date()) {
      throw new BadRequestException('Price proposal has expired.');
    }

    const diff = booking.price_proposed_coins - (booking.coins_cost ?? 0);

    const student = await this.prisma.profiles.findUnique({
      where: { id: studentId },
      select: { coins_balance: true },
    });
    if (!student) throw new NotFoundException('Student not found.');
    if (student.coins_balance < diff) {
      throw new BadRequestException(
        `Insufficient coins for price difference. Need ${diff} more coins.`,
      );
    }

    const ops: any[] = [
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: {
          coins_cost: booking.price_proposed_coins,
          price_proposed_coins: null,
          price_proposal_message: null,
          price_proposal_expires_at: null,
          updated_at: new Date(),
        },
        select: { id: true, coins_cost: true, status: true },
      }),
    ];

    if (diff > 0) {
      ops.push(
        this.prisma.profiles.update({
          where: { id: studentId },
          data: { coins_balance: { decrement: diff } },
        }),
        this.prisma.coin_transactions.create({
          data: {
            profile_id: studentId,
            amount: -diff,
            kind: 'BOOKING_PAYMENT',
            ref_id: bookingId,
            note: 'Price proposal accepted — additional coins deducted',
          },
        }),
      );
    }

    ops.push(
      this.prisma.notifications.create({
        data: {
          profile_id: booking.tutor_id,
          type: 'PRICE_ACCEPTED',
          payload: { booking_id: bookingId, new_coins_cost: booking.price_proposed_coins },
        },
      }),
    );

    const [result] = await this.prisma.$transaction(ops);
    return result;
  }

  async rejectPrice(bookingId: string, studentId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.student_id !== studentId) {
      throw new ForbiddenException('Only the student can reject a price proposal.');
    }
    if (!booking.price_proposed_coins) {
      throw new BadRequestException('No price proposal on this booking.');
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: {
          price_proposed_coins: null,
          price_proposal_message: null,
          price_proposal_expires_at: null,
          updated_at: new Date(),
        },
        select: { id: true, coins_cost: true, status: true },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: booking.tutor_id,
          type: 'PRICE_REJECTED',
          payload: { booking_id: bookingId, student_id: studentId },
        },
      }),
    ]);

    return updated;
  }

  // ─── reschedule ──────────────────────────────────────────────────────────────

  async proposeReschedule(bookingId: string, tutorId: string, dto: ProposeRescheduleDto) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId) {
      throw new ForbiddenException('Only the tutor can propose a reschedule.');
    }
    if (!['pending', 'confirmed'].includes(booking.status as string)) {
      throw new BadRequestException('Can only reschedule pending or confirmed bookings.');
    }

    const newStart = new Date(dto.new_start_at);
    const newEnd = new Date(dto.new_end_at);
    if (newStart >= newEnd) throw new BadRequestException('new_start_at must be before new_end_at.');
    if (newStart < new Date()) throw new BadRequestException('Proposed time must be in the future.');

    const conflict = await this.prisma.bookings.findFirst({
      where: {
        tutor_id: tutorId,
        id: { not: bookingId },
        status: { in: ['pending', 'confirmed'] },
        start_at: { lt: newEnd },
        end_at: { gt: newStart },
      },
    });
    if (conflict) throw new BadRequestException('Proposed time conflicts with another booking.');

    const [updated] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: {
          status: 'rescheduling',
          reschedule_proposed_start: newStart,
          reschedule_proposed_end: newEnd,
          reschedule_notes: dto.reason,
          reschedule_requested_by: tutorId,
          updated_at: new Date(),
        },
        select: {
          id: true,
          status: true,
          reschedule_proposed_start: true,
          reschedule_proposed_end: true,
          reschedule_notes: true,
        },
      }),
      this.prisma.messages.create({
        data: {
          from_id: tutorId,
          to_id: booking.student_id,
          booking_id: bookingId,
          content: dto.reason ?? 'I would like to reschedule our session.',
          metadata: {
            type: 'RESCHEDULE_REQUEST',
            new_start_at: dto.new_start_at,
            new_end_at: dto.new_end_at,
          },
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: booking.student_id,
          type: 'RESCHEDULE_PROPOSED',
          payload: {
            booking_id: bookingId,
            tutor_id: tutorId,
            new_start_at: dto.new_start_at,
            new_end_at: dto.new_end_at,
          },
        },
      }),
    ]);

    return updated;
  }

  async acceptReschedule(bookingId: string, studentId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.student_id !== studentId) {
      throw new ForbiddenException('Only the student can accept a reschedule.');
    }
    if (booking.status !== 'rescheduling') {
      throw new BadRequestException('No pending reschedule proposal on this booking.');
    }
    if (!booking.reschedule_proposed_start || !booking.reschedule_proposed_end) {
      throw new BadRequestException('Reschedule proposal data is incomplete.');
    }

    const newDuration = Math.round(
      (booking.reschedule_proposed_end.getTime() - booking.reschedule_proposed_start.getTime()) / 60_000,
    );

    const [updated] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: {
          start_at: booking.reschedule_proposed_start,
          end_at: booking.reschedule_proposed_end,
          duration_minutes: newDuration,
          status: 'confirmed',
          reschedule_proposed_start: null,
          reschedule_proposed_end: null,
          reschedule_notes: null,
          reschedule_requested_by: null,
          updated_at: new Date(),
        },
        select: { id: true, status: true, start_at: true, end_at: true, duration_minutes: true },
      }),
      this.prisma.messages.create({
        data: {
          from_id: studentId,
          to_id: booking.tutor_id,
          booking_id: bookingId,
          content: 'I accept the reschedule.',
          metadata: { type: 'RESCHEDULE_ACCEPTED' },
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: booking.tutor_id,
          type: 'RESCHEDULE_ACCEPTED',
          payload: { booking_id: bookingId, student_id: studentId },
        },
      }),
    ]);

    return updated;
  }

  async rejectReschedule(bookingId: string, studentId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.student_id !== studentId) {
      throw new ForbiddenException('Only the student can reject a reschedule.');
    }
    if (booking.status !== 'rescheduling') {
      throw new BadRequestException('No pending reschedule proposal on this booking.');
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: {
          status: 'confirmed',
          reschedule_proposed_start: null,
          reschedule_proposed_end: null,
          reschedule_notes: null,
          reschedule_requested_by: null,
          updated_at: new Date(),
        },
        select: { id: true, status: true },
      }),
      this.prisma.messages.create({
        data: {
          from_id: studentId,
          to_id: booking.tutor_id,
          booking_id: bookingId,
          content: 'I prefer to keep the original schedule.',
          metadata: { type: 'RESCHEDULE_REJECTED' },
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: booking.tutor_id,
          type: 'RESCHEDULE_REJECTED',
          payload: { booking_id: bookingId, student_id: studentId },
        },
      }),
    ]);

    return updated;
  }

  // ─── status transitions ──────────────────────────────────────────────────────

  async cancelBooking(bookingId: string, userId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');

    const isOwner = booking.student_id === userId || booking.tutor_id === userId;
    if (!isOwner) throw new ForbiddenException('Not your booking.');
    if (['completed', 'cancelled', 'expired'].includes(booking.status as string)) {
      throw new ForbiddenException(`Cannot cancel a ${booking.status} booking.`);
    }

    const coinsCost = booking.coins_cost ?? 0;
    const ops: any[] = [
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: { status: 'cancelled', updated_at: new Date() },
        select: { id: true, status: true, coins_cost: true },
      }),
    ];

    if (coinsCost > 0) {
      ops.push(
        this.prisma.profiles.update({
          where: { id: booking.student_id },
          data: { coins_balance: { increment: coinsCost } },
        }),
        this.prisma.coin_transactions.create({
          data: {
            profile_id: booking.student_id,
            amount: coinsCost,
            kind: 'REFUND',
            ref_id: bookingId,
            note: 'Booking cancelled — coins refunded',
          },
        }),
      );
    }

    const notifyId = userId === booking.student_id ? booking.tutor_id : booking.student_id;
    ops.push(
      this.prisma.notifications.create({
        data: {
          profile_id: notifyId,
          type: 'BOOKING_CANCELLED',
          payload: { booking_id: bookingId, cancelled_by: userId, coins_refunded: coinsCost },
        },
      }),
    );

    const [result] = await this.prisma.$transaction(ops);
    return { ...result, coins_refunded: coinsCost };
  }

  async confirmBooking(bookingId: string, tutorId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId) {
      throw new ForbiddenException('Only the tutor can confirm this booking.');
    }
    if (booking.status !== 'pending') {
      throw new ForbiddenException('Only pending bookings can be confirmed.');
    }
    if (booking.price_proposed_coins) {
      throw new BadRequestException('Resolve the pending price proposal before confirming.');
    }

    // Create Daily.co room before transaction
    const roomName = await this.daily.createRoom(bookingId, booking.end_at);

    const [result] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: { status: 'confirmed', room_name: roomName, updated_at: new Date() },
        select: { id: true, status: true, room_name: true },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: booking.student_id,
          type: 'BOOKING_CONFIRMED',
          payload: { booking_id: bookingId, tutor_id: tutorId },
        },
      }),
    ]);

    return result;
  }

  async completeBooking(bookingId: string, tutorId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId) {
      throw new ForbiddenException('Only the tutor can complete this booking.');
    }
    if (booking.status !== 'confirmed') {
      throw new ForbiddenException('Only confirmed bookings can be completed.');
    }

    const coinsCost = booking.coins_cost ?? 0;
    const ops: any[] = [
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: { status: 'completed', updated_at: new Date() },
        select: { id: true, status: true, coins_cost: true },
      }),
    ];

    if (coinsCost > 0) {
      ops.push(
        this.prisma.profiles.update({
          where: { id: tutorId },
          data: { coins_balance: { increment: coinsCost } },
        }),
        this.prisma.coin_transactions.create({
          data: {
            profile_id: tutorId,
            amount: coinsCost,
            kind: 'TUTOR_EARNING',
            ref_id: bookingId,
            note: `Session completed — ${booking.duration_minutes} min`,
          },
        }),
      );
    }

    ops.push(
      this.prisma.notifications.create({
        data: {
          profile_id: booking.student_id,
          type: 'SESSION_COMPLETED',
          payload: { booking_id: bookingId, coins_earned: coinsCost },
        },
      }),
    );

    const [result] = await this.prisma.$transaction(ops);
    return { ...result, coins_earned: coinsCost };
  }

  async declineBooking(bookingId: string, tutorId: string) {
    const booking = await this.prisma.bookings.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId) {
      throw new ForbiddenException('Only the tutor can decline this booking.');
    }
    if (booking.status !== 'pending') {
      throw new ForbiddenException('Only pending bookings can be declined.');
    }

    const coinsCost = booking.coins_cost ?? 0;
    const ops: any[] = [
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: { status: 'declined', updated_at: new Date() },
        select: { id: true, status: true, coins_cost: true },
      }),
    ];

    if (coinsCost > 0) {
      ops.push(
        this.prisma.profiles.update({
          where: { id: booking.student_id },
          data: { coins_balance: { increment: coinsCost } },
        }),
        this.prisma.coin_transactions.create({
          data: {
            profile_id: booking.student_id,
            amount: coinsCost,
            kind: 'REFUND',
            ref_id: bookingId,
            note: 'Tutor declined booking — coins refunded',
          },
        }),
      );
    }

    ops.push(
      this.prisma.notifications.create({
        data: {
          profile_id: booking.student_id,
          type: 'BOOKING_DECLINED',
          payload: { booking_id: bookingId, tutor_id: tutorId, coins_refunded: coinsCost },
        },
      }),
    );

    const [result] = await this.prisma.$transaction(ops);
    return { ...result, coins_refunded: coinsCost };
  }
}
