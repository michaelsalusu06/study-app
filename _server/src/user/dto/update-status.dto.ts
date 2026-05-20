import { IsIn } from 'class-validator';

export class UpdateStatusDto {
  @IsIn(['ONLINE', 'OFFLINE', 'BUSY'])
  status: 'ONLINE' | 'OFFLINE' | 'BUSY';
}
