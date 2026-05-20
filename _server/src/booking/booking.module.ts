import { Module } from '@nestjs/common';
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';
import { ReviewsModule } from 'src/reviews/reviews.module';
import { DailyModule } from 'src/daily/daily.module';

@Module({
  imports: [ReviewsModule, DailyModule],
  controllers: [BookingController],
  providers: [BookingService],
})
export class BookingModule {}
