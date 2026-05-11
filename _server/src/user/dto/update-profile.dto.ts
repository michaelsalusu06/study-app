import { IsIn, IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class UpdateProfileDTO {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  full_name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  username?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @IsUrl()
  avatar_url?: string;

  @IsOptional()
  @IsIn(['STUDENT', 'TUTOR', 'student', 'tutor'])
  role?: string;
}
