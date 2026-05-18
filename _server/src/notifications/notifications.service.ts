import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async getMyNotifications(userId: string) {
    return this.prisma.notifications.findMany({
      where: { profile_id: userId },
      orderBy: { created_at: 'desc' },
      take: 50,
    });
  }

  async markSeen(userId: string, notifId: string) {
    const notif = await this.prisma.notifications.findFirst({
      where: { id: notifId, profile_id: userId },
    });
    if (!notif) throw new NotFoundException('Notification not found.');

    await this.prisma.notifications.update({
      where: { id: notifId },
      data: { seen: true },
    });

    return { message: 'Marked as seen.' };
  }

  async markAllSeen(userId: string) {
    const { count } = await this.prisma.notifications.updateMany({
      where: { profile_id: userId, seen: false },
      data: { seen: true },
    });

    return { message: `${count} notification(s) marked as seen.` };
  }

  async getUnseenCount(userId: string) {
    const count = await this.prisma.notifications.count({
      where: { profile_id: userId, seen: false },
    });
    return { unseen_count: count };
  }
}
