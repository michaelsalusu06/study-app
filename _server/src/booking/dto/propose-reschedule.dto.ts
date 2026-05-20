import { IsDateString, IsOptional, IsString } from 'class-validator';

export class ProposeRescheduleDto {
  @IsDateString()
  new_start_at: string;

  @IsDateString()
  new_end_at: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
