import {
  Controller,
  ForbiddenException,
  Headers,
  HttpCode,
  Post,
} from '@nestjs/common';
import { PrismaService } from 'src/prisma.service';

@Controller('internal')
export class InternalController {
  constructor(private prisma: PrismaService) {}

  // POST /internal/notify-upcoming-sessions
  // Called by Vercel Cron every 10 minutes. Secured by x-internal-secret header.
  @Post('notify-upcoming-sessions')
  @HttpCode(200)
  async notifyUpcomingSessions(@Headers('x-internal-secret') secret: string) {
    if (secret !== process.env.INTERNAL_SECRET) {
      throw new ForbiddenException('Unauthorized.');
    }

    const now = new Date();
    const windowStart = new Date(now.getTime() + 10 * 60_000);
    const windowEnd = new Date(now.getTime() + 20 * 60_000);

    const upcoming = await this.prisma.bookings.findMany({
      where: {
        status: 'confirmed',
        start_at: { gte: windowStart, lte: windowEnd },
        session_notified_at: null,
      },
      select: {
        id: true,
        student_id: true,
        tutor_id: true,
        start_at: true,
      },
    });

    if (upcoming.length === 0) return { notified: 0 };

    const ops: any[] = [];
    for (const booking of upcoming) {
      const meetingUrl = `https://meet.jit.si/studyapp-${booking.id}`;
      const payload = {
        booking_id: booking.id,
        start_at: booking.start_at,
        meeting_url: meetingUrl,
      };

      ops.push(
        this.prisma.notifications.create({
          data: { profile_id: booking.student_id, type: 'SESSION_REMINDER', payload },
        }),
        this.prisma.notifications.create({
          data: { profile_id: booking.tutor_id, type: 'SESSION_REMINDER', payload },
        }),
        this.prisma.bookings.update({
          where: { id: booking.id },
          data: { session_notified_at: now },
        }),
      );
    }

    await this.prisma.$transaction(ops);
    return { notified: upcoming.length };
  }
}
