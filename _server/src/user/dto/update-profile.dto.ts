import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  Min,
} from 'class-validator';

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

  @IsOptional()
  @IsInt()
  @Min(1)
  book_price_coins?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  subjects?: string[];
}
