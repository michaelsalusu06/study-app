import { IsISO8601, IsInt, IsOptional, IsUUID, Min } from 'class-validator';

export class CreateBookingDto {
  @IsUUID()
  tutorId: string;

  @IsOptional()
  @IsUUID()
  tutorOfferId?: string;

  @IsISO8601()
  startAt: string;

  @IsISO8601()
  endAt: string;

  @IsInt()
  @Min(15)
  durationMinutes: number;
}
