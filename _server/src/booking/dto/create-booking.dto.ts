import { IsISO8601, IsInt, IsOptional, IsUUID, Min } from 'class-validator';

export class CreateBookingDto {
  // Required only when NOT booking via an offer
  @IsOptional()
  @IsUUID()
  tutorId?: string;

  // If provided, tutorId / durationMinutes / endAt are all derived from the offer
  @IsOptional()
  @IsUUID()
  tutorOfferId?: string;

  @IsISO8601()
  startAt: string;

  // Optional — auto-computed from offer duration when tutorOfferId is given
  @IsOptional()
  @IsISO8601()
  endAt?: string;

  // Optional when tutorOfferId given
  @IsOptional()
  @IsInt()
  @Min(15)
  durationMinutes?: number;
}
