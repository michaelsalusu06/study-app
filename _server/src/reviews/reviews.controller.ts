import { Body, Controller, Get, Param, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  // POST /reviews — student submits review after completed booking
  @UseGuards(AuthGuard('jwt'))
  @Post()
  createReview(@Request() req: any, @Body() dto: CreateReviewDto) {
    return this.reviewsService.createReview(req.user.userId || req.user.sub, dto);
  }

  // GET /reviews/tutor/:id — public, list reviews for a tutor
  @Get('tutor/:id')
  getTutorReviews(@Param('id') id: string) {
    return this.reviewsService.getTutorReviews(id);
  }
}
