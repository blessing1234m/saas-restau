import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AdminEtablissementService } from './admin-etablissement.service';
import { RoleGuard } from '../auth/guards/role.guard';
import { EtablissementActifGuard } from '../auth/guards/etablissement-actif.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UtilisateurActuel } from '../auth/decorators/utilisateur-actuel.decorator';
import { CreateSousRestaurantDto, UpdateSousRestaurantDto } from './dto/sous-restaurant.dto';
import { CreateTableDto, UpdateTableDto } from './dto/table.dto';
import { CreateCategorieDto, UpdateCategorieDto } from './dto/categorie.dto';
import { CreatePlatDto, UpdatePlatDto } from './dto/plat.dto';
import { CreateServeurDto } from './dto/serveur.dto';

@Controller('admin-etablissements')
@UseGuards(AuthGuard('jwt'), RoleGuard, EtablissementActifGuard)
@Roles('ADMIN_ETABLISSEMENT')
export class AdminEtablissementController {
  constructor(private adminService: AdminEtablissementService) {}

  // SOUS-RESTAURANTS 

  @Post('sous-restaurants')
  async creerSousRestaurant(
    @UtilisateurActuel() user,
    @Body() dto: CreateSousRestaurantDto,
  ) {
    return this.adminService.creerSousRestaurant(user.utilisateurId, dto);
  }

  @Get('sous-restaurants')
  async obtenirSousRestaurants(
    @UtilisateurActuel() user,
  ) {
    return this.adminService.obtenirSousRestaurants(user.utilisateurId);
  }

  @Get('sous-restaurants/:sousRestaurantId')
  async obtenirSousRestaurant(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.adminService.obtenirSousRestaurant(
      user.utilisateurId,
      sousRestaurantId,
    );
  }

  @Put('sous-restaurants/:sousRestaurantId')
  async mettreAJourSousRestaurant(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Body() dto: UpdateSousRestaurantDto,
  ) {
    return this.adminService.mettreAJourSousRestaurant(
      user.utilisateurId,
      sousRestaurantId,
      dto,
    );
  }

  @Delete('sous-restaurants/:sousRestaurantId')
  async supprimerSousRestaurant(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.adminService.supprimerSousRestaurant(
      user.utilisateurId,
      sousRestaurantId,
    );
  }

  // TABLES 

  @Post('sous-restaurants/:sousRestaurantId/tables')
  async creerTable(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Body() dto: CreateTableDto,
  ) {
    return this.adminService.creerTable(
      user.utilisateurId,
      sousRestaurantId,
      dto,
    );
  }

  @Get('sous-restaurants/:sousRestaurantId/tables')
  async obtenirTables(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.adminService.obtenirTables(user.utilisateurId, sousRestaurantId);
  }

  @Put('sous-restaurants/:sousRestaurantId/tables/:tableId')
  async mettreAJourTable(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('tableId') tableId: string,
    @Body() dto: UpdateTableDto,
  ) {
    return this.adminService.mettreAJourTable(
      user.utilisateurId,
      sousRestaurantId,
      tableId,
      dto,
    );
  }

  @Delete('sous-restaurants/:sousRestaurantId/tables/:tableId')
  async supprimerTable(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('tableId') tableId: string,
  ) {
    return this.adminService.supprimerTable(
      user.utilisateurId,
      sousRestaurantId,
      tableId,
    );
  }

  // CATÉGORIES 

  @Post('sous-restaurants/:sousRestaurantId/categories')
  async creerCategorie(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Body() dto: CreateCategorieDto,
  ) {
    return this.adminService.creerCategorie(
      user.utilisateurId,
      sousRestaurantId,
      dto,
    );
  }

  @Get('sous-restaurants/:sousRestaurantId/categories')
  async obtenirCategories(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
  ) {
    return this.adminService.obtenirCategories(
      user.utilisateurId,
      sousRestaurantId,
    );
  }

  @Put('sous-restaurants/:sousRestaurantId/categories/:categorieId')
  async mettreAJourCategorie(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
    @Body() dto: UpdateCategorieDto,
  ) {
    return this.adminService.mettreAJourCategorie(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
      dto,
    );
  }

  @Delete('sous-restaurants/:sousRestaurantId/categories/:categorieId')
  async supprimerCategorie(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
  ) {
    return this.adminService.supprimerCategorie(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
    );
  }

  // PLATS 

  @Post('sous-restaurants/:sousRestaurantId/categories/:categorieId/plats')
  async creerPlat(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
    @Body() dto: CreatePlatDto,
  ) {
    return this.adminService.creerPlat(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
      dto,
    );
  }

  @Get('sous-restaurants/:sousRestaurantId/categories/:categorieId/plats')
  async obtenirPlats(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
  ) {
    return this.adminService.obtenirPlats(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
    );
  }

  @Get('sous-restaurants/:sousRestaurantId/categories/:categorieId/plats/:platId')
  async obtenirPlat(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
    @Param('platId') platId: string,
  ) {
    return this.adminService.obtenirPlat(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
      platId,
    );
  }

  @Put('sous-restaurants/:sousRestaurantId/categories/:categorieId/plats/:platId')
  async mettreAJourPlat(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
    @Param('platId') platId: string,
    @Body() dto: UpdatePlatDto,
  ) {
    return this.adminService.mettreAJourPlat(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
      platId,
      dto,
    );
  }

  @Delete('sous-restaurants/:sousRestaurantId/categories/:categorieId/plats/:platId')
  async supprimerPlat(
    @UtilisateurActuel() user,
    @Param('sousRestaurantId') sousRestaurantId: string,
    @Param('categorieId') categorieId: string,
    @Param('platId') platId: string,
  ) {
    return this.adminService.supprimerPlat(
      user.utilisateurId,
      sousRestaurantId,
      categorieId,
      platId,
    );
  }

  // ========== SERVEURS ==========

  @Post('serveurs')
  async creerServeur(
    @UtilisateurActuel() user,
    @Body() dto: CreateServeurDto,
  ) {
    return this.adminService.creerServeur(user.utilisateurId, dto);
  }

  @Get('serveurs')
  async obtenirServeurs(
    @UtilisateurActuel() user,
  ) {
    return this.adminService.obtenirServeurs(user.utilisateurId);
  }

  @Patch('serveurs/:serveurId/changer-etat')
  async basculerEtatServeur(
    @UtilisateurActuel() user,
    @Param('serveurId') serveurId: string,
  ) {
    return this.adminService.basculerEtatServeur(
      user.utilisateurId,
      serveurId,
    );
  }

  @Delete('serveurs/:serveurId')
  async supprimerServeur(
    @UtilisateurActuel() user,
    @Param('serveurId') serveurId: string,
  ) {
    return this.adminService.supprimerServeur(user.utilisateurId, serveurId);
  }
}
