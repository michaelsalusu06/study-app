import { Controller, Get, Param, Query } from '@nestjs/common';
import { OffersService } from './offers.service';

@Controller('offers')
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  // GET /offers?search=math&subject=uuid&maxCoins=20&minRating=4&page=1&limit=20
  @Get()
  browseOffers(
    @Query('search') search?: string,
    @Query('subject') subject?: string,
    @Query('maxCoins') maxCoins?: string,
    @Query('minRating') minRating?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.offersService.browseOffers({
      search,
      subject,
      maxCoins: maxCoins ? parseInt(maxCoins, 10) : undefined,
      minRating: minRating ? parseFloat(minRating) : undefined,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    });
  }

  // GET /offers/:id — full detail + tutor profile + recent reviews
  @Get(':id')
  getOfferDetail(@Param('id') id: string) {
    return this.offersService.getOfferDetail(id);
  }
}
