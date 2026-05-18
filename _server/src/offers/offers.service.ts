import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';

const TUTOR_SELECT = {
  id: true,
  full_name: true,
  username: true,
  avatar_url: true,
  overall_rating: true,
  rating_count: true,
  verification_status: true,
};

@Injectable()
export class OffersService {
  constructor(private prisma: PrismaService) {}

  async browseOffers(opts: {
    search?: string;
    subject?: string;
    maxCoins?: number;
    minRating?: number;
    page?: number;
    limit?: number;
  }) {
    const { search, subject, maxCoins, minRating, page = 1, limit = 20 } = opts;
    const skip = (page - 1) * limit;

    const where: any = {
      is_active: true,
      profiles: { verification_status: 'APPROVED' },
      ...(search && {
        OR: [
          { title: { contains: search, mode: 'insensitive' } },
          { summary: { contains: search, mode: 'insensitive' } },
        ],
      }),
      ...(maxCoins && { coins_per_hour: { lte: maxCoins } }),
      ...(minRating && { profiles: { overall_rating: { gte: minRating } } }),
    };

    // subject filter: offer must include subject in subject_ids array
    // Done post-query since Prisma array contains is field-level
    const [raw, total] = await Promise.all([
      this.prisma.tutor_offers.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        select: {
          id: true,
          title: true,
          summary: true,
          thumbnail_url: true,
          coins_per_hour: true,
          duration_minutes: true,
          subject_ids: true,
          created_at: true,
          profiles: { select: TUTOR_SELECT },
        },
      }),
      this.prisma.tutor_offers.count({ where }),
    ]);

    let offers = raw.map((o) => ({
      ...o,
      coins_per_session: Math.ceil((o.coins_per_hour * o.duration_minutes) / 60),
    }));

    if (subject) {
      offers = offers.filter((o) => o.subject_ids.includes(subject));
    }

    return { data: offers, total, page, limit };
  }

  async getOfferDetail(offerId: string) {
    const offer = await this.prisma.tutor_offers.findFirst({
      where: { id: offerId, is_active: true },
      select: {
        id: true,
        title: true,
        summary: true,
        about: true,
        thumbnail_url: true,
        coins_per_hour: true,
        duration_minutes: true,
        subject_ids: true,
        created_at: true,
        updated_at: true,
        profiles: {
          select: {
            ...TUTOR_SELECT,
            bio: true,
            subjects: true,
            book_price_coins: true,
          },
        },
      },
    });

    if (!offer) throw new NotFoundException('Offer not found.');

    // Recent reviews for this tutor
    const reviews = await this.prisma.reviews.findMany({
      where: { reviewee_id: offer.profiles.id },
      orderBy: { created_at: 'desc' },
      take: 5,
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
      ...offer,
      coins_per_session: Math.ceil((offer.coins_per_hour * offer.duration_minutes) / 60),
      tutor_reviews: reviews,
    };
  }
}
