import { Body, Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CoinsService } from './coins.service';
import { CreatePaymentOrderDto } from './dto/create-payment-order.dto';

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

  // Webhook endpoint — provider calls this after payment confirmation
  // In prod: verify provider signature before fulfilling
  @Post('webhook/fulfill')
  webhookFulfill(@Body() body: { order_id: string }) {
    return this.coinsService.fulfillOrder(body.order_id);
  }
}
