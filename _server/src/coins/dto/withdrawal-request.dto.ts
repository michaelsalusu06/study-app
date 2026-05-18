import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class WithdrawalRequestDto {
  @IsInt()
  @Min(10)
  coins_amount: number;

  @IsString()
  account_name: string;

  @IsString()
  account_number: string;

  @IsOptional()
  @IsIn(['QRIS', 'BANK_TRANSFER', 'GOPAY', 'OVO', 'DANA'])
  payment_method?: string;

  @IsOptional()
  @IsString()
  bank_name?: string;
}
