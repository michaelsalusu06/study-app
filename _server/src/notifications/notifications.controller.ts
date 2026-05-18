import { Controller, Get, Param, Patch, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { NotificationsService } from './notifications.service';

@UseGuards(AuthGuard('jwt'))
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  // GET /notifications
  @Get()
  getMyNotifications(@Request() req: any) {
    return this.notificationsService.getMyNotifications(req.user.userId || req.user.sub);
  }

  // GET /notifications/unseen-count
  @Get('unseen-count')
  getUnseenCount(@Request() req: any) {
    return this.notificationsService.getUnseenCount(req.user.userId || req.user.sub);
  }

  // PATCH /notifications/seen-all
  @Patch('seen-all')
  markAllSeen(@Request() req: any) {
    return this.notificationsService.markAllSeen(req.user.userId || req.user.sub);
  }

  // PATCH /notifications/:id/seen
  @Patch(':id/seen')
  markSeen(@Request() req: any, @Param('id') id: string) {
    return this.notificationsService.markSeen(req.user.userId || req.user.sub, id);
  }
}
