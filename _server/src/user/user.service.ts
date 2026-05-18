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

@Injectable()
export class UserService {
  constructor(
    private prisma: PrismaService,
    private encryption: EncryptionService,
  ) {}

  async getAllTutorProfile() {
    return this.prisma.profiles.findMany({
      where: { role: 'TUTOR', verification_status: 'APPROVED' },
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
      },
    });
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
    return this.prisma.profiles.findMany({
      where: {
        role: 'TUTOR',
        verification_status: 'APPROVED',
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
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async getTutorDetailProfile(tutorID: string) {
    const tutor = await this.prisma.profiles.findFirst({
      where: { id: tutorID, role: 'TUTOR', verification_status: 'APPROVED' },
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

    return {
      ...tutor,
      tutor_offers: tutor.tutor_offers.map((o) => ({
        ...o,
        coins_per_session: Math.ceil((o.coins_per_hour * o.duration_minutes) / 60),
      })),
    };
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
