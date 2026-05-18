import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';

const COIN_PACKAGES = [
  { coins: 50, fiat: 4.99 },
  { coins: 120, fiat: 9.99 },
  { coins: 260, fiat: 19.99 },
  { coins: 550, fiat: 39.99 },
];

export { COIN_PACKAGES };

export class CreatePaymentOrderDto {
  @IsInt()
  @Min(1)
  coins_amount: number;

  @IsOptional()
  @IsIn(['stripe', 'midtrans'])
  provider?: string;
}
