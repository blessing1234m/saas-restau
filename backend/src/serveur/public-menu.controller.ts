import { Controller, Get, Header, Param } from '@nestjs/common';
import { ServeurService } from './serveur.service';

@Controller('public')
export class PublicMenuController {
  constructor(private readonly serveurService: ServeurService) {}

  @Get('sous-restaurants/:sousRestaurantId/menu-data')
  async obtenirMenuPublic(
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.serveurService.obtenirMenuPublic(sousRestaurantId);
  }

  @Get('sous-restaurants/:sousRestaurantId/menu')
  @Header('Content-Type', 'text/html; charset=utf-8')
  async obtenirMenuPublicHtml(
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.serveurService.genererMenuPublicHtml(sousRestaurantId);
  }
}
