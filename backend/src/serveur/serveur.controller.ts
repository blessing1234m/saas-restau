import {
  Controller,
  Get,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ServeurService } from './serveur.service';
import { RoleGuard } from '../auth/guards/role.guard';
import { EtablissementActifGuard } from '../auth/guards/etablissement-actif.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UtilisateurActuel } from '../auth/decorators/utilisateur-actuel.decorator';

@Controller('serveurs')
@UseGuards(AuthGuard('jwt'), RoleGuard, EtablissementActifGuard)
@Roles('SERVEUR')
export class ServeurController {
  constructor(private serveurService: ServeurService) {}

  // ========== MENU ==========

  @Get('mon-etablissement')
  async obtenirMonEtablissement(
    @UtilisateurActuel() user,
  ) {
    return this.serveurService.obtenirEtablissementDuServeur(user.utilisateurId);
  }

  @Get('mon-sous-restaurant')
  async obtenirMonSousRestaurant(
    @UtilisateurActuel() user,
  ) {
    return this.serveurService.obtenirSousRestaurantDuServeur(user.utilisateurId);
  }

  @Get('sous-restaurants')
  async obtenirSousRestaurants(
    @UtilisateurActuel() user,
  ) {
    return this.serveurService.obtenirSousRestaurants(user.utilisateurId);
  }

  @Get('sous-restaurants/:sousRestaurantId/menu')
  async obtenirMenu(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.serveurService.obtenirMenu(user.utilisateurId, sousRestaurantId);
  }

  @Get('sous-restaurants/:sousRestaurantId/categories')
  async obtenirCategories(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.serveurService.obtenirCategories(user.utilisateurId, sousRestaurantId);
  }

  @Get('sous-restaurants/:sousRestaurantId/categories/:categorieId/plats')
  async obtenirPlatsDuCategorie(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
  ) {
    return this.serveurService.obtenirPlatsDuCategorie(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
    );
  }
}
