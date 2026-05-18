import { IsIn, IsInt, Min } from 'class-validator';

export const COIN_TO_IDR = 1000; // 1 coin = Rp 1,000

export const COIN_PACKAGES = [
  { coins: 50,  fiat: 50_000 },
  { coins: 120, fiat: 110_000 },
  { coins: 260, fiat: 225_000 },
  { coins: 550, fiat: 450_000 },
];

export class CreatePaymentOrderDto {
  @IsInt()
  @Min(1)
  @IsIn(COIN_PACKAGES.map((p) => p.coins), {
    message: `coins_amount must be one of: ${COIN_PACKAGES.map((p) => p.coins).join(', ')}`,
  })
  coins_amount: number;
}
