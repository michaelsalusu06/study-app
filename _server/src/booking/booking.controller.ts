import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@UseGuards(AuthGuard('jwt'))
@Controller('booking')
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  // POST /booking — student creates a booking
  @Post()
  createBooking(@Request() req: any, @Body() dto: CreateBookingDto) {
    const userId = req.user.userId || req.user.sub;
    if (!userId) throw new UnauthorizedException('Missing user identity.');
    return this.bookingService.createBooking(userId, dto);
  }

  // GET /booking/student — my bookings as a student
  @Get('student')
  getStudentBookings(@Request() req: any) {
    const userId = req.user.userId || req.user.sub;
    return this.bookingService.getStudentBookings(userId);
  }

  // GET /booking/tutor — my bookings as a tutor
  @Get('tutor')
  getTutorBookings(@Request() req: any) {
    const userId = req.user.userId || req.user.sub;
    return this.bookingService.getTutorBookings(userId);
  }

  // PATCH /booking/:id/cancel
  @Patch(':id/cancel')
  cancelBooking(@Param('id') id: string, @Request() req: any) {
    const userId = req.user.userId || req.user.sub;
    return this.bookingService.cancelBooking(id, userId);
  }

  // PATCH /booking/:id/confirm — tutor confirms
  @Patch(':id/confirm')
  confirmBooking(@Param('id') id: string, @Request() req: any) {
    const userId = req.user.userId || req.user.sub;
    return this.bookingService.confirmBooking(id, userId);
  }
}
