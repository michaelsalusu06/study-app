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
import { ProposePriceDto } from './dto/propose-price.dto';
import { ReviewsService } from 'src/reviews/reviews.service';
import { CreateReviewDto } from 'src/reviews/dto/create-review.dto';

@UseGuards(AuthGuard('jwt'))
@Controller('booking')
export class BookingController {
  constructor(
    private readonly bookingService: BookingService,
    private readonly reviewsService: ReviewsService,
  ) {}

  @Post()
  createBooking(@Request() req: any, @Body() dto: CreateBookingDto) {
    const userId = req.user.userId || req.user.sub;
    if (!userId) throw new UnauthorizedException('Missing user identity.');
    return this.bookingService.createBooking(userId, dto);
  }

  @Get('student')
  getStudentBookings(@Request() req: any, @Query('status') status?: string) {
    return this.bookingService.getStudentBookings(req.user.userId || req.user.sub, status);
  }

  @Get('tutor')
  getTutorBookings(@Request() req: any, @Query('status') status?: string) {
    return this.bookingService.getTutorBookings(req.user.userId || req.user.sub, status);
  }

  @Get(':id')
  getBookingById(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.getBookingById(id, req.user.userId || req.user.sub);
  }

  // GET /booking/:id/join — returns Daily.co token + room URL
  @Get(':id/join')
  getJoinInfo(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.getJoinInfo(id, req.user.userId || req.user.sub);
  }

  @Patch(':id/cancel')
  cancelBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.cancelBooking(id, req.user.userId || req.user.sub);
  }

  @Patch(':id/confirm')
  confirmBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.confirmBooking(id, req.user.userId || req.user.sub);
  }

  @Patch(':id/complete')
  completeBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.completeBooking(id, req.user.userId || req.user.sub);
  }

  @Patch(':id/decline')
  declineBooking(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.declineBooking(id, req.user.userId || req.user.sub);
  }

  // Price negotiation
  @Patch(':id/propose-price')
  proposePrice(@Param('id') id: string, @Request() req: any, @Body() dto: ProposePriceDto) {
    return this.bookingService.proposePrice(id, req.user.userId || req.user.sub, dto);
  }

  @Patch(':id/accept-price')
  acceptPrice(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.acceptPrice(id, req.user.userId || req.user.sub);
  }

  @Patch(':id/reject-price')
  rejectPrice(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.rejectPrice(id, req.user.userId || req.user.sub);
  }

  // Reschedule
  @Patch(':id/propose-reschedule')
  proposeReschedule(@Param('id') id: string, @Request() req: any, @Body() dto: ProposeRescheduleDto) {
    return this.bookingService.proposeReschedule(id, req.user.userId || req.user.sub, dto);
  }

  @Patch(':id/accept-reschedule')
  acceptReschedule(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.acceptReschedule(id, req.user.userId || req.user.sub);
  }

  @Patch(':id/reject-reschedule')
  rejectReschedule(@Param('id') id: string, @Request() req: any) {
    return this.bookingService.rejectReschedule(id, req.user.userId || req.user.sub);
  }

  @Post(':id/review')
  createReview(@Param('id') id: string, @Request() req: any, @Body() dto: CreateReviewDto) {
    return this.reviewsService.createReview(req.user.userId || req.user.sub, dto, id);
  }
}
