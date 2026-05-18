import { IsString, Length, MinLength } from 'class-validator';

export class AdminLoginDto {
  @IsString()
  @Length(10, 10)
  admin_id: string;

  @IsString()
  @MinLength(8)
  password: string;
}
