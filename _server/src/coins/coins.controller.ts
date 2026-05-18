import { Body, Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CoinsService } from './coins.service';
import { CreatePaymentOrderDto } from './dto/create-payment-order.dto';
import { WithdrawalRequestDto } from './dto/withdrawal-request.dto';

@Controller('coins')
export class CoinsController {
  constructor(private readonly coinsService: CoinsService) {}

  @Get('packages')
  getPackages() {
    return this.coinsService.getPackages();
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('balance')
  getBalance(@Request() req: any) {
    return this.coinsService.getBalance(req.user.userId || req.user.sub);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('history')
  getHistory(@Request() req: any) {
    return this.coinsService.getHistory(req.user.userId || req.user.sub);
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('purchase')
  createOrder(@Request() req: any, @Body() dto: CreatePaymentOrderDto) {
    return this.coinsService.createPaymentOrder(req.user.userId || req.user.sub, dto);
  }

  // Midtrans sends notification here after payment
  @Post('webhook/midtrans')
  midtransWebhook(@Body() body: any) {
    return this.coinsService.handleMidtransWebhook(body);
  }

  // Tutor requests to cash out coins → IDR
  @UseGuards(AuthGuard('jwt'))
  @Post('withdraw')
  requestWithdrawal(@Request() req: any, @Body() dto: WithdrawalRequestDto) {
    return this.coinsService.requestWithdrawal(req.user.userId || req.user.sub, dto);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('withdrawals')
  getWithdrawals(@Request() req: any) {
    return this.coinsService.getWithdrawals(req.user.userId || req.user.sub);
  }
}
