import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Injectable()
export class BookingService {
  constructor(private prisma: PrismaService) {}

  async createBooking(studentId: string, dto: CreateBookingDto) {
    if (!dto.tutorOfferId && !dto.tutorId) {
      throw new BadRequestException('Provide either tutorOfferId or tutorId.');
    }

    let tutorId = dto.tutorId!;
    let durationMinutes = dto.durationMinutes ?? 60;
    let coinRatePerHour: number;
    let endAt: Date;

    if (dto.tutorOfferId) {
      // Offer-based booking: derive everything from the offer
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
      // Manual booking: tutor + duration provided explicitly
      const tutor = await this.prisma.profiles.findFirst({
        where: { id: tutorId, role: 'TUTOR' },
      });
      if (!tutor) throw new NotFoundException('Tutor not found.');
      if (!dto.durationMinutes) throw new BadRequestException('durationMinutes is required for manual bookings.');

      coinRatePerHour = tutor.book_price_coins;
      durationMinutes = dto.durationMinutes;
      endAt = dto.endAt ? new Date(dto.endAt) : new Date(new Date(dto.startAt).getTime() + durationMinutes * 60_000);
    }

    if (tutorId === studentId) throw new BadRequestException('Cannot book yourself.');

    // Conflict check: reject if tutor has a pending/confirmed booking that overlaps
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
    const price = 0;

    // Check student balance
    const student = await this.prisma.profiles.findUnique({
      where: { id: studentId },
      select: { coins_balance: true },
    });
    if (!student) throw new NotFoundException('Student not found.');
    if (student.coins_balance < coinsCost) {
      throw new BadRequestException(
        `Insufficient coins. Need ${coinsCost} coins, have ${student.coins_balance}. Please top up first.`,
      );
    }

    const [booking] = await this.prisma.$transaction([
      this.prisma.bookings.create({
        data: {
          student_id: studentId,
          tutor_id: tutorId,
          tutor_offer_id: dto.tutorOfferId,
          start_at: new Date(dto.startAt),
          end_at: endAt,
          duration_minutes: durationMinutes,
          price,
          coins_cost: coinsCost,
          status: 'pending',
        },
        select: {
          id: true,
          tutor_id: true,
          student_id: true,
          start_at: true,
          end_at: true,
          duration_minutes: true,
          price: true,
          coins_cost: true,
          status: true,
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
          payload: { student_id: studentId, duration_minutes: durationMinutes, coins_cost: coinsCost },
        },
      }),
    ]);

    return booking;
  }

  async getBookingById(bookingId: string, userId: string) {
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
      select: {
        id: true,
        start_at: true,
        end_at: true,
        duration_minutes: true,
        price: true,
        coins_cost: true,
        status: true,
        created_at: true,
        updated_at: true,
        profiles_bookings_tutor_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true, username: true },
        },
        profiles_bookings_student_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true, username: true },
        },
        tutor_offers: {
          select: { id: true, title: true, duration_minutes: true },
        },
      },
    });

    if (!booking) throw new NotFoundException('Booking not found.');

    const isParticipant =
      booking.profiles_bookings_student_idToprofiles.id === userId ||
      booking.profiles_bookings_tutor_idToprofiles.id === userId;
    if (!isParticipant) throw new ForbiddenException('Not your booking.');

    return booking;
  }

  async getStudentBookings(studentId: string) {
    return this.prisma.bookings.findMany({
      where: { student_id: studentId },
      select: {
        id: true,
        start_at: true,
        end_at: true,
        duration_minutes: true,
        price: true,
        coins_cost: true,
        status: true,
        created_at: true,
        profiles_bookings_tutor_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true, username: true },
        },
        tutor_offers: {
          select: { title: true },
        },
      },
      orderBy: { start_at: 'desc' },
    });
  }

  async getTutorBookings(tutorId: string) {
    return this.prisma.bookings.findMany({
      where: { tutor_id: tutorId },
      select: {
        id: true,
        start_at: true,
        end_at: true,
        duration_minutes: true,
        price: true,
        coins_cost: true,
        status: true,
        created_at: true,
        profiles_bookings_student_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true, username: true },
        },
        tutor_offers: {
          select: { title: true },
        },
      },
      orderBy: { start_at: 'desc' },
    });
  }

  async cancelBooking(bookingId: string, userId: string) {
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found.');

    const isOwner = booking.student_id === userId || booking.tutor_id === userId;
    if (!isOwner) throw new ForbiddenException('Not your booking.');

    if (booking.status === 'completed' || booking.status === 'cancelled') {
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

    // Refund student coins if any were deducted
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

    // Notify the other party
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
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId) {
      throw new ForbiddenException('Only the tutor can confirm this booking.');
    }
    if (booking.status !== 'pending') {
      throw new ForbiddenException('Only pending bookings can be confirmed.');
    }

    const [result] = await this.prisma.$transaction([
      this.prisma.bookings.update({
        where: { id: bookingId },
        data: { status: 'confirmed', updated_at: new Date() },
        select: { id: true, status: true },
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
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
    });

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
}
