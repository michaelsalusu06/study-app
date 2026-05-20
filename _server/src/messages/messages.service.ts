import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';
import { SendMessageDto } from './dto/send-message.dto';

@Injectable()
export class MessagesService {
  constructor(private prisma: PrismaService) {}

  async sendMessage(fromId: string, dto: SendMessageDto) {
    if (fromId === dto.to_id) {
      throw new BadRequestException('Cannot message yourself.');
    }

    const recipient = await this.prisma.profiles.findUnique({
      where: { id: dto.to_id },
      select: { id: true },
    });
    if (!recipient) throw new NotFoundException('Recipient not found.');

    return this.prisma.messages.create({
      data: {
        from_id: fromId,
        to_id: dto.to_id,
        booking_id: dto.booking_id ?? null,
        content: dto.content,
        metadata: dto.metadata ?? {},
      },
      select: {
        id: true,
        from_id: true,
        to_id: true,
        booking_id: true,
        content: true,
        metadata: true,
        is_read: true,
        created_at: true,
      },
    });
  }

  async getConversations(userId: string) {
    const [sent, received] = await Promise.all([
      this.prisma.messages.findMany({
        where: { from_id: userId },
        select: { to_id: true },
        distinct: ['to_id'],
      }),
      this.prisma.messages.findMany({
        where: { to_id: userId },
        select: { from_id: true },
        distinct: ['from_id'],
      }),
    ]);

    const partnerIds = Array.from(
      new Set([...sent.map((m) => m.to_id), ...received.map((m) => m.from_id)]),
    );

    if (partnerIds.length === 0) return [];

    const conversations = await Promise.all(
      partnerIds.map(async (partnerId) => {
        const [lastMessage, unreadCount, partner] = await Promise.all([
          this.prisma.messages.findFirst({
            where: {
              OR: [
                { from_id: userId, to_id: partnerId },
                { from_id: partnerId, to_id: userId },
              ],
            },
            orderBy: { created_at: 'desc' },
            select: {
              id: true,
              content: true,
              from_id: true,
              is_read: true,
              created_at: true,
              metadata: true,
            },
          }),
          this.prisma.messages.count({
            where: { from_id: partnerId, to_id: userId, is_read: false },
          }),
          this.prisma.profiles.findUnique({
            where: { id: partnerId },
            select: {
              id: true,
              full_name: true,
              username: true,
              avatar_url: true,
              user_status: true,
              role: true,
            },
          }),
        ]);

        return { partner, last_message: lastMessage, unread_count: unreadCount };
      }),
    );

    return conversations
      .filter((c) => c.last_message)
      .sort(
        (a, b) =>
          new Date(b.last_message!.created_at!).getTime() -
          new Date(a.last_message!.created_at!).getTime(),
      );
  }

  async getConversation(
    userId: string,
    partnerId: string,
    cursor?: string,
    limit = 30,
  ) {
    const partner = await this.prisma.profiles.findUnique({
      where: { id: partnerId },
      select: {
        id: true,
        full_name: true,
        username: true,
        avatar_url: true,
        user_status: true,
        last_seen_at: true,
      },
    });
    if (!partner) throw new NotFoundException('User not found.');

    const messages = await this.prisma.messages.findMany({
      where: {
        OR: [
          { from_id: userId, to_id: partnerId },
          { from_id: partnerId, to_id: userId },
        ],
        ...(cursor ? { created_at: { lt: new Date(cursor) } } : {}),
      },
      orderBy: { created_at: 'desc' },
      take: limit,
      select: {
        id: true,
        from_id: true,
        to_id: true,
        booking_id: true,
        content: true,
        metadata: true,
        is_read: true,
        created_at: true,
      },
    });

    return {
      partner,
      messages: messages.reverse(),
      next_cursor:
        messages.length === limit ? messages[0].created_at?.toISOString() : null,
    };
  }

  async markRead(userId: string, messageId: string) {
    const message = await this.prisma.messages.findUnique({
      where: { id: messageId },
    });
    if (!message) throw new NotFoundException('Message not found.');
    if (message.to_id !== userId) throw new ForbiddenException('Not your message.');

    await this.prisma.messages.update({
      where: { id: messageId },
      data: { is_read: true },
    });
    return { message: 'Marked as read.' };
  }

  async markAllRead(userId: string, partnerId: string) {
    const { count } = await this.prisma.messages.updateMany({
      where: { from_id: partnerId, to_id: userId, is_read: false },
      data: { is_read: true },
    });
    return { marked_count: count };
  }
}
