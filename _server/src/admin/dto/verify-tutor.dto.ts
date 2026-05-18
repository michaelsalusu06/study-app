import { IsIn, IsOptional, IsString } from 'class-validator';

export class VerifyTutorDto {
  @IsIn(['APPROVED', 'REJECTED'])
  status: 'APPROVED' | 'REJECTED';

  @IsOptional()
  @IsString()
  admin_notes?: string;
}
