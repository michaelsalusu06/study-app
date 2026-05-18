import { IsEmail, IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class SignUpDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsIn(['STUDENT', 'TUTOR', 'student', 'tutor'])
  role?: string; // ADMIN accounts must be created directly in DB
}
