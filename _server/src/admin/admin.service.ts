import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { EncryptionService } from 'src/common/encryption/encryption.service';
import { VerifyTutorDto } from './dto/verify-tutor.dto';
import { ProcessRefundDto } from './dto/process-refund.dto';
import { ProcessWithdrawalDto } from './dto/process-withdrawal.dto';
import { CreateAdminDto } from './dto/create-admin.dto';
import { hash } from 'argon2';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private encryption: EncryptionService,
  ) {}

  private generateAdminId(): string {
    // 10-digit numeric, first digit never 0
    const first = Math.floor(Math.random() * 9) + 1;
    const rest = Math.floor(Math.random() * 1_000_000_000).toString().padStart(9, '0');
    return `${first}${rest}`;
  }

  async createAdmin(callerRole: string | undefined, dto: CreateAdminDto) {
    const bootstrapSecret = process.env.ADMIN_BOOTSTRAP_SECRET;
    const usingBootstrap = dto.bootstrap_secret && bootstrapSecret && dto.bootstrap_secret === bootstrapSecret;

    if (!usingBootstrap && callerRole !== 'ADMIN') {
      throw new ForbiddenException('Provide bootstrap_secret or authenticate as ADMIN.');
    }

    // generate unique 10-digit ID
    let adminId: string;
    let attempts = 0;
    do {
      adminId = this.generateAdminId();
      const existing = await this.prisma.profiles.findUnique({ where: { admin_id: adminId } });
      if (!existing) break;
      attempts++;
    } while (attempts < 10);

    const hashedPassword = await hash(dto.password);

    const admin = await this.prisma.profiles.create({
      data: {
        admin_id: adminId,
        full_name: dto.full_name,
        role: 'ADMIN',
        password: hashedPassword,
        book_price: 0,
      },
      select: {
        id: true,
        admin_id: true,
        full_name: true,
        role: true,
        created_at: true,
      },
    });

    return {
      message: 'Admin account created.',
      admin,
    };
  }

  async getStats() {
    const [
      totalUsers,
      pendingVerifications,
      approvedTutors,
      totalBookings,
      pendingRefunds,
      totalRevenue,
    ] = await Promise.all([
      this.prisma.profiles.count(),
      this.prisma.profiles.count({ where: { role: 'TUTOR', verification_status: 'PENDING' } }),
      this.prisma.profiles.count({ where: { role: 'TUTOR', verification_status: 'APPROVED' } }),
      this.prisma.bookings.count(),
      this.prisma.payment_orders.count({ where: { status: 'COMPLETED', refunded_at: null } }),
      this.prisma.payment_orders.aggregate({
        _sum: { fiat_amount: true },
        where: { status: 'COMPLETED' },
      }),
    ]);

    return {
      totalUsers,
      pendingVerifications,
      approvedTutors,
      totalBookings,
      pendingRefunds,
      totalRevenue: totalRevenue._sum.fiat_amount ?? 0,
    };
  }

  async getAllUsers(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [users, total] = await Promise.all([
      this.prisma.profiles.findMany({
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        select: {
          id: true,
          email: true,
          full_name: true,
          username: true,
          role: true,
          verification_status: true,
          is_email_verified: true,
          created_at: true,
          overall_rating: true,
          rating_count: true,
        },
      }),
      this.prisma.profiles.count(),
    ]);

    return { data: users, total, page, limit };
  }

  async getPendingTutors() {
    return this.prisma.profiles.findMany({
      where: { role: 'TUTOR', verification_status: 'PENDING' },
      orderBy: { created_at: 'asc' },
      select: {
        id: true,
        email: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        subjects: true,
        verification_status: true,
        created_at: true,
        tutor_verifications: {
          select: {
            id: true,
            submitted_at: true,
            admin_notes: true,
          },
        },
      },
    });
  }

  async getTutorDetail(tutorId: string) {
    const tutor = await this.prisma.profiles.findFirst({
      where: { id: tutorId, role: 'TUTOR' },
      select: {
        id: true,
        email: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        subjects: true,
        book_price: true,
        verification_status: true,
        is_email_verified: true,
        overall_rating: true,
        created_at: true,
        tutor_verifications: true,
        tutor_offers: {
          select: { id: true, title: true, price_per_hour: true, is_active: true },
        },
      },
    });

    if (!tutor) throw new NotFoundException('Tutor not found.');

    const verification = tutor.tutor_verifications
      ? {
          id: tutor.tutor_verifications.id,
          submitted_at: tutor.tutor_verifications.submitted_at,
          reviewed_at: tutor.tutor_verifications.reviewed_at,
          reviewed_by: tutor.tutor_verifications.reviewed_by,
          admin_notes: tutor.tutor_verifications.admin_notes,
          phone: this.encryption.decryptIfPresent(tutor.tutor_verifications.phone_enc),
          address: this.encryption.decryptIfPresent(tutor.tutor_verifications.address_enc),
          id_document_url: this.encryption.decryptIfPresent(tutor.tutor_verifications.id_document_enc),
          certificate_urls: tutor.tutor_verifications.cert_urls_enc
            ? JSON.parse(this.encryption.decrypt(tutor.tutor_verifications.cert_urls_enc))
            : [],
        }
      : null;

    return { ...tutor, tutor_verifications: verification };
  }

  async verifyTutor(tutorId: string, adminId: string, dto: VerifyTutorDto) {
    const tutor = await this.prisma.profiles.findFirst({
      where: { id: tutorId, role: 'TUTOR' },
    });

    if (!tutor) throw new NotFoundException('Tutor not found.');

    await this.prisma.$transaction([
      this.prisma.profiles.update({
        where: { id: tutorId },
        data: { verification_status: dto.status, updated_at: new Date() },
      }),
      this.prisma.tutor_verifications.upsert({
        where: { tutor_id: tutorId },
        update: {
          reviewed_at: new Date(),
          reviewed_by: adminId,
          admin_notes: dto.admin_notes,
        },
        create: {
          tutor_id: tutorId,
          reviewed_at: new Date(),
          reviewed_by: adminId,
          admin_notes: dto.admin_notes,
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: tutorId,
          type: 'VERIFICATION_UPDATE',
          payload: {
            status: dto.status,
            message:
              dto.status === 'APPROVED'
                ? 'Your tutor account has been approved.'
                : `Your tutor application was rejected. ${dto.admin_notes ?? ''}`.trim(),
          },
        },
      }),
    ]);

    return { message: `Tutor ${dto.status.toLowerCase()} successfully.` };
  }

  async getUserById(userId: string) {
    const user = await this.prisma.profiles.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        full_name: true,
        username: true,
        avatar_url: true,
        bio: true,
        role: true,
        verification_status: true,
        is_email_verified: true,
        overall_rating: true,
        rating_count: true,
        created_at: true,
        updated_at: true,
      },
    });

    if (!user) throw new NotFoundException('User not found.');
    return user;
  }

  async getPaymentOrders(page = 1, limit = 20, status?: string) {
    const skip = (page - 1) * limit;
    const where = status ? { status } : {};
    const [orders, total] = await Promise.all([
      this.prisma.payment_orders.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          profiles: { select: { id: true, email: true, full_name: true } },
        },
      }),
      this.prisma.payment_orders.count({ where }),
    ]);
    return { data: orders, total, page, limit };
  }

  async processRefund(adminId: string, dto: ProcessRefundDto) {
    const order = await this.prisma.payment_orders.findUnique({
      where: { id: dto.order_id },
    });

    if (!order) throw new NotFoundException('Payment order not found.');
    if (order.status !== 'COMPLETED') {
      throw new BadRequestException('Only COMPLETED orders can be refunded.');
    }

    if (dto.decision === 'REJECTED') {
      await this.prisma.payment_orders.update({
        where: { id: dto.order_id },
        data: {
          refund_reason: dto.reason,
          updated_at: new Date(),
        },
      });

      await this.prisma.notifications.create({
        data: {
          profile_id: order.profile_id,
          type: 'REFUND_REJECTED',
          payload: { order_id: order.id, reason: dto.reason },
        },
      });

      return { message: 'Refund request rejected.' };
    }

    // APPROVED — deduct coins and mark refunded
    await this.prisma.$transaction([
      this.prisma.payment_orders.update({
        where: { id: dto.order_id },
        data: {
          status: 'REFUNDED',
          refunded_at: new Date(),
          refunded_by: adminId,
          refund_reason: dto.reason,
          updated_at: new Date(),
        },
      }),
      this.prisma.profiles.update({
        where: { id: order.profile_id },
        data: { coins_balance: { decrement: order.coins_amount } },
      }),
      this.prisma.coin_transactions.create({
        data: {
          profile_id: order.profile_id,
          amount: -order.coins_amount,
          kind: 'REFUND',
          ref_id: order.id,
          note: `Refund approved by admin. ${dto.reason ?? ''}`.trim(),
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: order.profile_id,
          type: 'REFUND_APPROVED',
          payload: {
            order_id: order.id,
            coins_refunded: order.coins_amount,
            reason: dto.reason,
          },
        },
      }),
    ]);

    // TODO: trigger actual fiat refund via payment provider SDK
    return { message: 'Refund approved. Coins deducted.', coins_refunded: order.coins_amount };
  }

  async getWithdrawalRequests(page = 1, limit = 20, status?: string) {
    const skip = (page - 1) * limit;
    const where = status ? { status } : {};
    const [requests, total] = await Promise.all([
      this.prisma.withdrawal_requests.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          profiles: { select: { id: true, email: true, full_name: true } },
        },
      }),
      this.prisma.withdrawal_requests.count({ where }),
    ]);
    return { data: requests, total, page, limit };
  }

  async processWithdrawal(adminId: string, withdrawalId: string, dto: ProcessWithdrawalDto) {
    const withdrawal = await this.prisma.withdrawal_requests.findUnique({
      where: { id: withdrawalId },
    });

    if (!withdrawal) throw new NotFoundException('Withdrawal request not found.');
    if (withdrawal.status !== 'PENDING' && withdrawal.status !== 'APPROVED') {
      throw new BadRequestException(`Cannot process a ${withdrawal.status} withdrawal.`);
    }

    const ops: any[] = [
      this.prisma.withdrawal_requests.update({
        where: { id: withdrawalId },
        data: {
          status: dto.decision,
          admin_notes: dto.admin_notes,
          processed_by: adminId,
          updated_at: new Date(),
        },
      }),
      this.prisma.notifications.create({
        data: {
          profile_id: withdrawal.tutor_id,
          type: 'WITHDRAWAL_UPDATE',
          payload: {
            withdrawal_id: withdrawalId,
            status: dto.decision,
            coins_amount: withdrawal.coins_amount,
            idr_amount: withdrawal.idr_amount,
            admin_notes: dto.admin_notes,
          },
        },
      }),
    ];

    // If rejected, refund coins back to tutor
    if (dto.decision === 'REJECTED') {
      ops.push(
        this.prisma.profiles.update({
          where: { id: withdrawal.tutor_id },
          data: { coins_balance: { increment: withdrawal.coins_amount } },
        }),
        this.prisma.coin_transactions.create({
          data: {
            profile_id: withdrawal.tutor_id,
            amount: withdrawal.coins_amount,
            kind: 'ADJUSTMENT',
            ref_id: withdrawalId,
            note: `Withdrawal rejected — coins returned. ${dto.admin_notes ?? ''}`.trim(),
          },
        }),
      );
    }

    await this.prisma.$transaction(ops);

    return {
      message: `Withdrawal ${dto.decision.toLowerCase()} successfully.`,
      withdrawal_id: withdrawalId,
      refunded_coins: dto.decision === 'REJECTED' ? withdrawal.coins_amount : 0,
    };
  }

  async getBookings(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [bookings, total] = await Promise.all([
      this.prisma.bookings.findMany({
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        select: {
          id: true,
          status: true,
          price: true,
          duration_minutes: true,
          start_at: true,
          end_at: true,
          created_at: true,
          profiles_bookings_student_idToprofiles: {
            select: { id: true, full_name: true, email: true },
          },
          profiles_bookings_tutor_idToprofiles: {
            select: { id: true, full_name: true, email: true },
          },
        },
      }),
      this.prisma.bookings.count(),
    ]);

    return { data: bookings, total, page, limit };
  }
}
