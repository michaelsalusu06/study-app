import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async createReview(reviewerId: string, dto: CreateReviewDto) {
    const booking = await this.prisma.bookings.findUnique({
      where: { id: dto.booking_id },
    });

    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.student_id !== reviewerId) {
      throw new ForbiddenException('Only the student of this booking can leave a review.');
    }
    if (booking.status !== 'completed') {
      throw new BadRequestException('Can only review a completed session.');
    }

    const existing = await this.prisma.reviews.findFirst({
      where: { booking_id: dto.booking_id, reviewer_id: reviewerId },
    });
    if (existing) throw new BadRequestException('You already reviewed this session.');

    const review = await this.prisma.reviews.create({
      data: {
        booking_id: dto.booking_id,
        reviewer_id: reviewerId,
        reviewee_id: booking.tutor_id,
        rating: dto.rating,
        comment: dto.comment,
      },
      select: {
        id: true,
        rating: true,
        comment: true,
        created_at: true,
        profiles_reviews_reviewer_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true },
        },
      },
    });

    // Recalculate tutor's overall_rating
    const agg = await this.prisma.reviews.aggregate({
      where: { reviewee_id: booking.tutor_id },
      _avg: { rating: true },
      _count: { rating: true },
    });

    await this.prisma.profiles.update({
      where: { id: booking.tutor_id },
      data: {
        overall_rating: agg._avg.rating ?? 0,
        rating_count: agg._count.rating,
        updated_at: new Date(),
      },
    });

    // Notify tutor
    await this.prisma.notifications.create({
      data: {
        profile_id: booking.tutor_id,
        type: 'NEW_REVIEW',
        payload: {
          booking_id: dto.booking_id,
          rating: dto.rating,
          reviewer_id: reviewerId,
        },
      },
    });

    return review;
  }

  async getTutorReviews(tutorId: string) {
    const tutor = await this.prisma.profiles.findFirst({
      where: { id: tutorId, role: 'TUTOR' },
      select: { overall_rating: true, rating_count: true },
    });
    if (!tutor) throw new NotFoundException('Tutor not found.');

    const reviews = await this.prisma.reviews.findMany({
      where: { reviewee_id: tutorId },
      orderBy: { created_at: 'desc' },
      take: 50,
      select: {
        id: true,
        rating: true,
        comment: true,
        created_at: true,
        profiles_reviews_reviewer_idToprofiles: {
          select: { id: true, full_name: true, avatar_url: true },
        },
      },
    });

    return {
      overall_rating: tutor.overall_rating,
      rating_count: tutor.rating_count,
      reviews,
    };
  }
}
