import { IsIn, IsOptional, IsString, IsUUID } from 'class-validator';

export class ProcessRefundDto {
  @IsUUID()
  order_id: string;

  @IsIn(['APPROVED', 'REJECTED'])
  decision: 'APPROVED' | 'REJECTED';

  @IsOptional()
  @IsString()
  reason?: string;
}
