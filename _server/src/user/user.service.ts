import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { UpdateProfileDTO } from './dto/update-profile.dto';
import { SubmitVerificationDto } from './dto/submit-verification.dto';
import { EncryptionService } from 'src/common/encryption/encryption.service';
import { CreateTutorOfferDto } from './dto/create-tutor-offer.dto';
import { UpdateTutorOfferDto } from './dto/update-tutor-offer.dto';
import { CreateAvailabilityDto } from './dto/create-availability.dto';

const ACTIVE_ACCOUNT = { is_active: true, is_banned: false };

function applyPenalty<T extends {
  overall_rating?: any;
  book_price_coins?: number;
  penalty_until?: Date | null;
  penalty_rating_knock?: any;
  penalty_price_pct?: number;
}>(profile: T): Omit<T, 'penalty_until' | 'penalty_rating_knock' | 'penalty_price_pct'> {
  const now = new Date();
  const penalized = profile.penalty_until && profile.penalty_until > now;

  const { penalty_until, penalty_rating_knock, penalty_price_pct, ...rest } = profile as any;

  if (!penalized) return rest;

  const knock = Number(penalty_rating_knock ?? 0);
  const pct = Number(penalty_price_pct ?? 0);

  if (rest.overall_rating !== undefined) {
    rest.overall_rating = Math.max(0, Number(rest.overall_rating) - knock);
  }
  if (rest.book_price_coins !== undefined && pct > 0) {
    rest.book_price_coins = Math.ceil(rest.book_price_coins * (1 - pct / 100));
  }

  return rest;
}

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private encryption: EncryptionService,
  ) {}

  async getAllTutorProfile() {
    const tutors = await this.prisma.profiles.findMany({
      where: { role: 'TUTOR', verification_status: 'APPROVED', ...ACTIVE_ACCOUNT },
      select: {
        id: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        book_price: true,
        book_price_coins: true,
        subjects: true,
        overall_rating: true,
        rating_count: true,
        tutor_rating: true,
        user_status: true,
        last_seen_at: true,
        penalty_until: true,
        penalty_rating_knock: true,
        penalty_price_pct: true,
      },
    });
    return tutors.map(applyPenalty);
  }

  async getAllStudentProfile() {
    return this.prisma.profiles.findMany({
      where: { role: 'STUDENT' },
      select: {
        id: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        student_rating: true,
      },
    });
  }

  async getTutorFilteredBy(
    searchQuery?: string,
    subject?: string,
    maxCoins?: number,
  ) {
    const tutors = await this.prisma.profiles.findMany({
      where: {
        role: 'TUTOR',
        verification_status: 'APPROVED',
        ...ACTIVE_ACCOUNT,
        ...(searchQuery && {
          OR: [
            { full_name: { contains: searchQuery, mode: 'insensitive' } },
            { username: { contains: searchQuery, mode: 'insensitive' } },
          ],
        }),
        ...(subject && { subjects: { has: subject } }),
        ...(maxCoins && { book_price_coins: { lte: maxCoins } }),
      },
      select: {
        id: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        book_price: true,
        book_price_coins: true,
        subjects: true,
        overall_rating: true,
        rating_count: true,
        user_status: true,
        last_seen_at: true,
        penalty_until: true,
        penalty_rating_knock: true,
        penalty_price_pct: true,
      },
      orderBy: { created_at: 'desc' },
    });
    return tutors.map(applyPenalty);
  }

  async getTutorDetailProfile(tutorID: string) {
    const tutor = await this.prisma.profiles.findFirst({
      where: { id: tutorID, role: 'TUTOR', verification_status: 'APPROVED', ...ACTIVE_ACCOUNT },
      select: {
        id: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        book_price: true,
        book_price_coins: true,
        subjects: true,
        overall_rating: true,
        rating_count: true,
        tutor_rating: true,
        user_status: true,
        last_seen_at: true,
        penalty_until: true,
        penalty_rating_knock: true,
        penalty_price_pct: true,
        tutor_offers: {
          where: { is_active: true },
          select: {
            id: true,
            title: true,
            summary: true,
            thumbnail_url: true,
            coins_per_hour: true,
            duration_minutes: true,
            subject_ids: true,
          },
        },
      },
    });
    if (!tutor) throw new NotFoundException('Tutor not found.');

    const penalized = tutor.penalty_until && tutor.penalty_until > new Date();
    const pricePct = Number(tutor.penalty_price_pct ?? 0);

    const { penalty_until, penalty_rating_knock, penalty_price_pct, ...tutorBase } = tutor as any;

    return {
      ...applyPenalty(tutor),
      tutor_offers: tutor.tutor_offers.map((o) => {
        const coinsPerHour = penalized && pricePct > 0
          ? Math.ceil(o.coins_per_hour * (1 - pricePct / 100))
          : o.coins_per_hour;
        return {
          ...o,
          coins_per_hour: coinsPerHour,
          coins_per_session: Math.ceil((coinsPerHour * o.duration_minutes) / 60),
        };
      }),
    };
  }

  // ---------- TutorAvailability CRUD ----------

  async createAvailability(tutorId: string, dto: CreateAvailabilityDto) {
    const tutor = await this.prisma.profiles.findUnique({
      where: { id: tutorId },
      select: { role: true },
    });
    if (!tutor) throw new NotFoundException('User not found.');
    if (tutor.role !== 'TUTOR') throw new ForbiddenException('Only tutors can add availability slots.');

    const from = new Date(dto.available_from);
    const to = new Date(dto.available_to);

    if (from >= to) {
      throw new BadRequestException('available_from must be before available_to.');
    }
    if (from < new Date()) {
      throw new BadRequestException('Cannot create availability slot in the past.');
    }

    // Prevent overlapping slots for same tutor
    const overlap = await this.prisma.tutor_availabilities.findFirst({
      where: {
        tutor_id: tutorId,
        available_from: { lt: to },
        available_to: { gt: from },
      },
    });
    if (overlap) {
      throw new BadRequestException(
        `Slot overlaps with existing availability from ${overlap.available_from.toISOString()} to ${overlap.available_to.toISOString()}.`,
      );
    }

    return this.prisma.tutor_availabilities.create({
      data: {
        tutor_id: tutorId,
        available_from: from,
        available_to: to,
        timezone: dto.timezone,
      },
      select: {
        id: true,
        available_from: true,
        available_to: true,
        timezone: true,
        created_at: true,
      },
    });
  }

  async getTutorAvailability(tutorId: string) {
    const now = new Date();
    // Slots that are in the future and not tied to a pending/confirmed booking
    const bookedSlotIds = await this.prisma.bookings.findMany({
      where: {
        tutor_id: tutorId,
        status: { in: ['pending', 'confirmed'] },
        tutor_availability_id: { not: null },
      },
      select: { tutor_availability_id: true },
    });
    const bookedIds = bookedSlotIds.map((b) => b.tutor_availability_id).filter(Boolean) as string[];

    return this.prisma.tutor_availabilities.findMany({
      where: {
        tutor_id: tutorId,
        available_from: { gt: now },
        ...(bookedIds.length > 0 && { id: { notIn: bookedIds } }),
      },
      select: {
        id: true,
        available_from: true,
        available_to: true,
        timezone: true,
      },
      orderBy: { available_from: 'asc' },
    });
  }

  async deleteAvailability(tutorId: string, slotId: string) {
    const slot = await this.prisma.tutor_availabilities.findFirst({
      where: { id: slotId, tutor_id: tutorId },
    });
    if (!slot) throw new NotFoundException('Availability slot not found.');

    // Block deletion if a booking references this slot
    const linked = await this.prisma.bookings.findFirst({
      where: {
        tutor_availability_id: slotId,
        status: { in: ['pending', 'confirmed'] },
      },
    });
    if (linked) {
      throw new BadRequestException('Cannot delete slot — a pending or confirmed booking is tied to it.');
    }

    await this.prisma.tutor_availabilities.delete({ where: { id: slotId } });
    return { message: 'Availability slot removed.' };
  }

  // ---------- TutorOffer CRUD ----------

  async createOffer(tutorId: string, dto: CreateTutorOfferDto) {
    const tutor = await this.prisma.profiles.findUnique({
      where: { id: tutorId },
      select: { role: true, verification_status: true },
    });
    if (!tutor) throw new NotFoundException('User not found.');
    if (tutor.role !== 'TUTOR') throw new ForbiddenException('Only tutors can create offers.');

    const duration = dto.duration_minutes ?? 60;
    const coinsCost = Math.ceil((dto.coins_per_hour * duration) / 60);

    return this.prisma.tutor_offers.create({
      data: {
        tutor_id: tutorId,
        title: dto.title,
        summary: dto.summary,
        about: dto.about,
        coins_per_hour: dto.coins_per_hour,
        price_per_hour: 0,
        duration_minutes: duration,
        subject_ids: dto.subject_ids ?? [],
        thumbnail_url: dto.thumbnail_url,
        is_active: true,
      },
      select: {
        id: true,
        title: true,
        summary: true,
        thumbnail_url: true,
        coins_per_hour: true,
        duration_minutes: true,
        subject_ids: true,
        is_active: true,
        created_at: true,
      },
    });
  }

  async getMyOffers(tutorId: string) {
    const offers = await this.prisma.tutor_offers.findMany({
      where: { tutor_id: tutorId, is_active: true },
      select: {
        id: true,
        title: true,
        summary: true,
        about: true,
        thumbnail_url: true,
        coins_per_hour: true,
        duration_minutes: true,
        subject_ids: true,
        is_active: true,
        created_at: true,
        updated_at: true,
      },
      orderBy: { created_at: 'desc' },
    });

    return offers.map((o) => ({
      ...o,
      coins_per_session: Math.ceil((o.coins_per_hour * o.duration_minutes) / 60),
    }));
  }

  async updateOffer(tutorId: string, offerId: string, dto: UpdateTutorOfferDto) {
    const offer = await this.prisma.tutor_offers.findFirst({
      where: { id: offerId, tutor_id: tutorId },
    });
    if (!offer) throw new NotFoundException('Offer not found.');

    return this.prisma.tutor_offers.update({
      where: { id: offerId },
      data: {
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.summary !== undefined && { summary: dto.summary }),
        ...(dto.about !== undefined && { about: dto.about }),
        ...(dto.coins_per_hour !== undefined && { coins_per_hour: dto.coins_per_hour }),
        ...(dto.duration_minutes !== undefined && { duration_minutes: dto.duration_minutes }),
        ...(dto.subject_ids !== undefined && { subject_ids: dto.subject_ids }),
        ...(dto.is_active !== undefined && { is_active: dto.is_active }),
        ...(dto.thumbnail_url !== undefined && { thumbnail_url: dto.thumbnail_url }),
        updated_at: new Date(),
      },
      select: {
        id: true,
        title: true,
        summary: true,
        thumbnail_url: true,
        coins_per_hour: true,
        duration_minutes: true,
        subject_ids: true,
        is_active: true,
        updated_at: true,
      },
    });
  }

  async deleteOffer(tutorId: string, offerId: string) {
    const offer = await this.prisma.tutor_offers.findFirst({
      where: { id: offerId, tutor_id: tutorId },
    });
    if (!offer) throw new NotFoundException('Offer not found.');

    await this.prisma.tutor_offers.update({
      where: { id: offerId },
      data: { is_active: false, updated_at: new Date() },
    });

    return { message: 'Offer deleted.' };
  }

  // ---------- Profile + Verification ----------

  async submitVerification(userId: string, data: SubmitVerificationDto) {
    const user = await this.prisma.profiles.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found.');
    if (user.role !== 'TUTOR') throw new ForbiddenException('Only tutors can submit verification.');

    const certUrlsEncrypted = data.certificate_urls?.length
      ? this.encryption.encrypt(JSON.stringify(data.certificate_urls))
      : undefined;

    await this.prisma.tutor_verifications.upsert({
      where: { tutor_id: userId },
      update: {
        phone_enc: this.encryption.encryptIfPresent(data.phone),
        address_enc: this.encryption.encryptIfPresent(data.address),
        id_document_enc: this.encryption.encryptIfPresent(data.id_document_url),
        cert_urls_enc: certUrlsEncrypted,
        submitted_at: new Date(),
      },
      create: {
        tutor_id: userId,
        phone_enc: this.encryption.encryptIfPresent(data.phone),
        address_enc: this.encryption.encryptIfPresent(data.address),
        id_document_enc: this.encryption.encryptIfPresent(data.id_document_url),
        cert_urls_enc: certUrlsEncrypted,
      },
    });

    return { message: 'Verification info submitted. Pending admin review.' };
  }

  async updateStatus(userId: string, status: 'ONLINE' | 'OFFLINE' | 'BUSY') {
    return this.prisma.profiles.update({
      where: { id: userId },
      data: { user_status: status, last_seen_at: new Date() },
      select: { id: true, user_status: true, last_seen_at: true },
    });
  }

  async updateProfile(userId: string, data: UpdateProfileDTO) {
    if (!userId) throw new BadRequestException('User ID is required.');

    const user = await this.prisma.profiles.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found.');

    const updated = await this.prisma.profiles.update({
      where: { id: userId },
      data: {
        ...(data.full_name !== undefined && { full_name: data.full_name }),
        ...(data.username !== undefined && { username: data.username }),
        ...(data.bio !== undefined && { bio: data.bio }),
        ...(data.avatar_url !== undefined && { avatar_url: data.avatar_url }),
        ...(data.role && { role: data.role.toUpperCase() }),
        ...(data.book_price_coins !== undefined && { book_price_coins: data.book_price_coins }),
        ...(data.subjects !== undefined && { subjects: data.subjects }),
        updated_at: new Date(),
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        username: true,
        bio: true,
        avatar_url: true,
        role: true,
        book_price_coins: true,
        subjects: true,
      },
    });

    return { message: 'Profile updated successfully!', user: updated };
  }
}
