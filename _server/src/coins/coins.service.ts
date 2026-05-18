import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { CreatePaymentOrderDto, COIN_PACKAGES } from './dto/create-payment-order.dto';

@Injectable()
export class CoinsService {
  constructor(private prisma: PrismaService) {}

  getPackages() {
    return COIN_PACKAGES;
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
        `Invalid coins_amount. Valid values: ${COIN_PACKAGES.map((p) => p.coins).join(', ')}`,
      );
    }

    const order = await this.prisma.payment_orders.create({
      data: {
        profile_id: userId,
        coins_amount: pkg.coins,
        fiat_amount: pkg.fiat,
        currency: 'USD',
        provider: dto.provider ?? 'stripe',
        status: 'PENDING',
      },
    });

    // TODO: call payment provider SDK here to create session/payment link
    // e.g. for Stripe: const session = await stripe.checkout.sessions.create(...)
    // return { order_id: order.id, checkout_url: session.url }

    return {
      order_id: order.id,
      coins_amount: pkg.coins,
      fiat_amount: pkg.fiat,
      currency: 'USD',
      provider: order.provider,
      status: 'PENDING',
      message: 'Payment order created. Integrate provider SDK to generate checkout URL.',
    };
  }

  // Called by webhook after provider confirms payment
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
          note: `Purchased via ${order.provider}`,
        },
      }),
    ]);

    return { message: 'Order fulfilled.', coins_added: order.coins_amount };
  }
}
