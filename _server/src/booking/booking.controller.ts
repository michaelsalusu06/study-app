import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { ProposeRescheduleDto } from './dto/propose-reschedule.dto';
import { ReviewsService } from 'src/reviews/reviews.service';
import { CreateReviewDto } from 'src/reviews/dto/create-review.dto';

@UseGuards(AuthGuard('jwt'))
@Controller('booking')
export class BookingController {
  constructor(
    private readonly bookingService: BookingService,
    private readonly reviewsService: ReviewsService,
  ) {}

  // POST /booking — student creates a booking
  @Post()
  createBooking(@Request() req: any, @Body() dto: CreateBookingDto) {
    const userId = req.user.userId || req.user.sub;
    if (!userId) throw new UnauthorizedException('Missing user identity.');
    return this.bookingService.createBooking(userId, dto);
  }

  // GET /booking/student?status=pending
  @Get('student')
  getStudentBookings(@Request() req: any, @Query('status') status?: string) {
    return this.bookingService.getStudentBookings(req.user.userId || req.user.sub, status);
  }

  // GET /booking/tutor?status=confirmed
  @Get('tutor')
  getTutorBookings(@Request() req: any, @Query('status') status?: string) {
    return this.bookingService.getTutorBookings(req.user.userId || req.user.sub, status);
  }

  // GET /booking/:id — role-aware detail (student or tutor)
  @Get(':id')
  getBookingById(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.getBookingById(id, req.user.userId || req.user.sub);
  }

  // GET /booking/:id/join — returns Jitsi meeting URL + password (within time window only)
  @Get(':id/join')
  getJoinInfo(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.getJoinInfo(id, req.user.userId || req.user.sub);
  }

  // PATCH /booking/:id/cancel
  @Patch(':id/cancel')
  cancelBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.cancelBooking(id, req.user.userId || req.user.sub);
  }

  // PATCH /booking/:id/confirm — tutor confirms
  @Patch(':id/confirm')
  confirmBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.confirmBooking(id, req.user.userId || req.user.sub);
  }

  // PATCH /booking/:id/complete — tutor marks session done, releases coins
  @Patch(':id/complete')
  completeBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.completeBooking(id, req.user.userId || req.user.sub);
  }

  // PATCH /booking/:id/decline — tutor declines, refunds student
  @Patch(':id/decline')
  declineBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.declineBooking(id, req.user.userId || req.user.sub);
  }

  // PATCH /booking/:id/propose-reschedule — tutor proposes a new time
  @Patch(':id/propose-reschedule')
  proposeReschedule(
    @Param('id') id: string,
    @Request() req: any,
    @Body() dto: ProposeRescheduleDto,
  ) {
    return this.bookingService.proposeReschedule(id, req.user.userId || req.user.sub, dto);
  }

  // PATCH /booking/:id/accept-reschedule — student accepts tutor's proposal
  @Patch(':id/accept-reschedule')
  acceptReschedule(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.acceptReschedule(id, req.user.userId || req.user.sub);
  }

  // PATCH /booking/:id/reject-reschedule — student rejects, keeps original time
  @Patch(':id/reject-reschedule')
  rejectReschedule(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.rejectReschedule(id, req.user.userId || req.user.sub);
  }

  // POST /booking/:id/review — student submits review for completed booking
  @Post(':id/review')
  createReview(
    @Param('id') id: string,
    @Request() req: any,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviewsService.createReview(req.user.userId || req.user.sub, dto, id);
  }
}
