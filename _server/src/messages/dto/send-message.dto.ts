import { IsObject, IsOptional, IsString, IsUUID } from 'class-validator';

export class SendMessageDto {
  @IsUUID()
  to_id: string;

  @IsString()
  content: string;

  @IsOptional()
  @IsUUID()
  booking_id?: string;

  @IsOptional()
  @IsObject()
  metadata?: Record<string, any>;
}
