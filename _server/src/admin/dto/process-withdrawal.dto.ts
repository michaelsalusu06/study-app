import { IsIn, IsOptional, IsString } from 'class-validator';

export class ProcessWithdrawalDto {
  @IsIn(['APPROVED', 'REJECTED', 'PAID'])
  decision: 'APPROVED' | 'REJECTED' | 'PAID';

  @IsOptional()
  @IsString()
  admin_notes?: string;
}
