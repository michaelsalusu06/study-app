import { IsOptional, IsString, IsUrl, IsArray } from 'class-validator';

export class SubmitVerificationDto {
  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsUrl()
  id_document_url?: string;

  @IsOptional()
  @IsArray()
  @IsUrl({}, { each: true })
  certificate_urls?: string[];
}
