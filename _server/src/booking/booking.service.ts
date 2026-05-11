import {
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
    const tutor = await this.prisma.profiles.findFirst({
      where: { id: dto.tutorId, role: 'TUTOR' },
    });
    if (!tutor) throw new NotFoundException('Tutor not found.');

    let pricePerHour = parseFloat(tutor.book_price.toString());

    if (dto.tutorOfferId) {
      const offer = await this.prisma.tutor_offers.findFirst({
        where: { id: dto.tutorOfferId, tutor_id: dto.tutorId, is_active: true },
      });
      if (!offer) throw new NotFoundException('Tutor offer not found.');
      pricePerHour = parseFloat(offer.price_per_hour.toString());
    }

    const price = (pricePerHour * dto.durationMinutes) / 60;

    return this.prisma.bookings.create({
      data: {
        student_id: studentId,
        tutor_id: dto.tutorId,
        tutor_offer_id: dto.tutorOfferId,
        start_at: new Date(dto.startAt),
        end_at: new Date(dto.endAt),
        duration_minutes: dto.durationMinutes,
        price,
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
        status: true,
        created_at: true,
      },
    });
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

    const isOwner =
      booking.student_id === userId || booking.tutor_id === userId;
    if (!isOwner) throw new ForbiddenException('Not your booking.');

    if (booking.status === 'completed' || booking.status === 'cancelled') {
      throw new ForbiddenException(
        `Cannot cancel a ${booking.status} booking.`,
      );
    }

    return this.prisma.bookings.update({
      where: { id: bookingId },
      data: { status: 'cancelled' },
      select: { id: true, status: true },
    });
  }

  async confirmBooking(bookingId: string, tutorId: string) {
    const booking = await this.prisma.bookings.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.tutor_id !== tutorId)
      throw new ForbiddenException('Only the tutor can confirm this booking.');
    if (booking.status !== 'pending')
      throw new ForbiddenException('Only pending bookings can be confirmed.');

    return this.prisma.bookings.update({
      where: { id: bookingId },
      data: { status: 'confirmed' },
      select: { id: true, status: true },
    });
  }
}
