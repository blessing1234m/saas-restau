import { Body, Controller, Get, Header, Param, Post } from '@nestjs/common';
import { ServeurService } from './serveur.service';
import { CreatePublicCommandeDto } from './dto/public-commande.dto';

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

  @Post('sous-restaurants/:sousRestaurantId/commandes')
  async creerCommandePublic(
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Body() dto: CreatePublicCommandeDto,
  ) {
    return this.serveurService.creerCommandePublic(sousRestaurantId, dto);
  }
}
