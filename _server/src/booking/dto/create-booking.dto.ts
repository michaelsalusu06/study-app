import { IsISO8601, IsInt, IsOptional, IsString, IsUUID, Min } from 'class-validator';

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

  // Optional — link booking to a specific tutor availability slot
  @IsOptional()
  @IsUUID()
  availabilityId?: string;

  // Optional — student explains why they need the session (shown to tutor before confirm)
  @IsOptional()
  @IsString()
  description?: string;
}
