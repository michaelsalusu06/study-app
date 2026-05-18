import { IsString, MinLength, IsOptional } from 'class-validator';

export class CreateAdminDto {
  @IsString()
  @MinLength(3)
  full_name: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  bootstrap_secret?: string;
}
