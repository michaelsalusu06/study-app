import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdateTutorOfferDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  summary?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  about?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  coins_per_hour?: number;

  @IsOptional()
  @IsInt()
  @Min(15)
  duration_minutes?: number;

  @IsOptional()
  @IsArray()
  @IsUUID('all', { each: true })
  subject_ids?: string[];

  @IsOptional()
  @IsBoolean()
  is_active?: boolean;

  @IsOptional()
  @IsUrl()
  thumbnail_url?: string;
}
