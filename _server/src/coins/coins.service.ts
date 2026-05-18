import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from 'src/prisma.service';
import { COIN_PACKAGES, COIN_TO_IDR, CreatePaymentOrderDto } from './dto/create-payment-order.dto';
import { WithdrawalRequestDto } from './dto/withdrawal-request.dto';

@Injectable()
export class CoinsService {
  constructor(private prisma: PrismaService) {}

  private get midtransBaseUrl(): string {
    return process.env.MIDTRANS_IS_PRODUCTION === 'true'
      ? 'https://api.midtrans.com'
      : 'https://api.sandbox.midtrans.com';
  }

  private get midtransAuthHeader(): string {
    const key = process.env.MIDTRANS_SERVER_KEY ?? '';
    return 'Basic ' + Buffer.from(key + ':').toString('base64');
  }

  private computeMidtransSignature(
    orderId: string,
    statusCode: string,
    grossAmount: string,
  ): string {
    const serverKey = process.env.MIDTRANS_SERVER_KEY ?? '';
    const raw = orderId + statusCode + grossAmount + serverKey;
    return createHash('sha512').update(raw).digest('hex');
  }

  getPackages() {
    return COIN_PACKAGES.map((p) => ({
      ...p,
      currency: 'IDR',
      label: `${p.coins} coins — Rp ${p.fiat.toLocaleString('id-ID')}`,
    }));
  }

  async getBalance(userId: string) {
    const user = await this.prisma.profiles.findUnique({
      where: { id: userId },
      select: { coins_balance: true },
    });
    if (!user) throw new NotFoundException('User not found.');
    return { coins_balance: user.coins_balance };
  }

  async getHistory(userId: string) {
    return this.prisma.coin_transactions.findMany({
      where: { profile_id: userId },
      orderBy: { created_at: 'desc' },
      take: 50,
    });
  }

  async createPaymentOrder(userId: string, dto: CreatePaymentOrderDto) {
    const pkg = COIN_PACKAGES.find((p) => p.coins === dto.coins_amount);
    if (!pkg) {
      throw new BadRequestException(
        `Invalid coins_amount. Valid: ${COIN_PACKAGES.map((p) => p.coins).join(', ')}`,
      );
    }

    const order = await this.prisma.payment_orders.create({
      data: {
        profile_id: userId,
        coins_amount: pkg.coins,
        fiat_amount: pkg.fiat,
        currency: 'IDR',
        provider: 'midtrans',
        status: 'PENDING',
      },
    });

    // Create QRIS via Midtrans Core API
    const midtransRes = await fetch(`${this.midtransBaseUrl}/v2/charge`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        Authorization: this.midtransAuthHeader,
      },
      body: JSON.stringify({
        payment_type: 'qris',
        transaction_details: {
          order_id: order.id,
          gross_amount: pkg.fiat,
        },
        custom_expiry: {
          expiry_duration: 30,
          unit: 'minute',
        },
      }),
    });

    const midtransData = await midtransRes.json() as any;

    if (!midtransRes.ok || !['200', '201'].includes(midtransData.status_code)) {
      await this.prisma.payment_orders.update({
        where: { id: order.id },
        data: { status: 'FAILED', provider_payload: midtransData },
      });
      throw new BadRequestException(
        midtransData.status_message ?? 'Failed to create QRIS payment.',
      );
    }

    const qrAction = (midtransData.actions as any[])?.find(
      (a: any) => a.name === 'generate-qr-code',
    );

    await this.prisma.payment_orders.update({
      where: { id: order.id },
      data: {
        qris_ref: midtransData.transaction_id,
        provider_session_id: midtransData.transaction_id,
        provider_payload: midtransData,
      },
    });

    return {
      order_id: order.id,
      coins_amount: pkg.coins,
      idr_amount: pkg.fiat,
      currency: 'IDR',
      qr_string: midtransData.qr_string ?? null,
      qr_code_url: qrAction?.url ?? null,
      expires_in_minutes: 30,
      status: 'PENDING',
    };
  }

  async handleMidtransWebhook(payload: any) {
    const { order_id, transaction_status, status_code, gross_amount, signature_key } = payload;

    if (!order_id || !transaction_status) {
      throw new BadRequestException('Invalid webhook payload.');
    }

    // Verify signature
    const expected = this.computeMidtransSignature(order_id, status_code, gross_amount);
    if (signature_key !== expected) {
      throw new UnauthorizedException('Invalid Midtrans signature.');
    }

    if (transaction_status === 'settlement' || transaction_status === 'capture') {
      return this.fulfillOrder(order_id);
    }

    if (transaction_status === 'expire' || transaction_status === 'cancel' || transaction_status === 'deny') {
      await this.prisma.payment_orders.updateMany({
        where: { id: order_id, status: 'PENDING' },
        data: { status: 'FAILED', updated_at: new Date() },
      });
      return { message: `Order marked FAILED (${transaction_status}).` };
    }

    return { message: `Webhook received, status: ${transaction_status}.` };
  }

  async fulfillOrder(orderId: string) {
    const order = await this.prisma.payment_orders.findUnique({
      where: { id: orderId },
    });

    if (!order) throw new NotFoundException('Payment order not found.');
    if (order.status === 'COMPLETED') {
      return { message: 'Order already fulfilled.' };
    }

    await this.prisma.$transaction([
      this.prisma.payment_orders.update({
        where: { id: orderId },
        data: { status: 'COMPLETED', updated_at: new Date() },
      }),
      this.prisma.profiles.update({
        where: { id: order.profile_id },
        data: { coins_balance: { increment: order.coins_amount } },
      }),
      this.prisma.coin_transactions.create({
        data: {
          profile_id: order.profile_id,
          amount: order.coins_amount,
          kind: 'PURCHASE',
          ref_id: orderId,
          note: `Purchased via QRIS (Rp ${Number(order.fiat_amount).toLocaleString('id-ID')})`,
        },
      }),
    ]);

    return { message: 'Order fulfilled.', coins_added: order.coins_amount };
  }

  // ---------- Tutor Withdrawal ----------

  async requestWithdrawal(tutorId: string, dto: WithdrawalRequestDto) {
    const profile = await this.prisma.profiles.findUnique({
      where: { id: tutorId },
      select: { coins_balance: true, role: true },
    });

    if (!profile) throw new NotFoundException('User not found.');
    if (profile.role !== 'TUTOR') {
      throw new BadRequestException('Only tutors can request withdrawals.');
    }
    if (profile.coins_balance < dto.coins_amount) {
      throw new BadRequestException(
        `Insufficient balance. Have ${profile.coins_balance} coins, need ${dto.coins_amount}.`,
      );
    }

    const idrAmount = dto.coins_amount * COIN_TO_IDR;

    const [withdrawal] = await this.prisma.$transaction([
      this.prisma.withdrawal_requests.create({
        data: {
          tutor_id: tutorId,
          coins_amount: dto.coins_amount,
          idr_amount: idrAmount,
          status: 'PENDING',
          account_name: dto.account_name,
          account_number: dto.account_number,
          payment_method: dto.payment_method ?? 'QRIS',
          bank_name: dto.bank_name,
        },
      }),
      this.prisma.profiles.update({
        where: { id: tutorId },
        data: { coins_balance: { decrement: dto.coins_amount } },
      }),
      this.prisma.coin_transactions.create({
        data: {
          profile_id: tutorId,
          amount: -dto.coins_amount,
          kind: 'WITHDRAWAL',
          note: `Withdrawal request submitted — Rp ${idrAmount.toLocaleString('id-ID')}`,
        },
      }),
    ]);

    return {
      withdrawal_id: withdrawal.id,
      coins_amount: dto.coins_amount,
      idr_amount: idrAmount,
      status: 'PENDING',
      message: 'Withdrawal request submitted. Admin will process within 1-3 business days.',
    };
  }

  async getWithdrawals(tutorId: string) {
    return this.prisma.withdrawal_requests.findMany({
      where: { tutor_id: tutorId },
      orderBy: { created_at: 'desc' },
      take: 50,
    });
  }
}
