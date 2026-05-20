import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class ProposePriceDto {
  @IsInt()
  @Min(1)
  proposed_coins: number;

  @IsOptional()
  @IsString()
  message?: string;
}
