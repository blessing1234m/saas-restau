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
  Query,
  BadRequestException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CommandesService } from './commandes.service';
import { PrismaService } from '../prisma/prisma.service';
import { RoleGuard } from '../auth/guards/role.guard';
import { EtablissementActifGuard } from '../auth/guards/etablissement-actif.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UtilisateurActuel } from '../auth/decorators/utilisateur-actuel.decorator';
import { CreateCommandeDto } from './dto/create-commande.dto';
import { UpdateCommandeStatusDto, UpdateCommandeDto } from './dto/update-commande.dto';
import { CreateItemCommandeItemDto } from './dto/item-commande.dto';

@Controller('commandes')
@UseGuards(AuthGuard('jwt'), RoleGuard, EtablissementActifGuard)
@Roles('SERVEUR')
export class CommandesController {
  constructor(
    private commandesService: CommandesService,
    private prisma: PrismaService,
  ) {}

  private async getServeurId(utilisateurId: string): Promise<string> {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
    });

    if (!serveur) {
      throw new BadRequestException('Serveur non trouvé');
    }

    return serveur.id;
  }

  // ========== TEST/HEALTH ==========

  @Get('health')
  async healthCheck(
    @UtilisateurActuel() user,
  ) {
    try {
      const serveur = await this.prisma.serveur.findUnique({
        where: { utilisateurId: user.utilisateurId },
        include: {
          utilisateur: true,
          etablissement: true,
        },
      });

      return {
        status: 'ok',
        serveur: {
          id: serveur?.id,
          codeAgent: serveur?.utilisateur.codeAgent,
          etablissement: serveur?.etablissement.nom,
          estActif: serveur?.utilisateur.estActif,
        },
      };
    } catch (error) {
      throw new Error('Erreur lors de la vérification du serveur');
    }
  }

  // ========== COMMANDES ==========

  @Post()
  async creerCommande(
    @UtilisateurActuel() user,
    @Body() createCommandeDto: CreateCommandeDto,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.creerCommande(serveurId, createCommandeDto);
  }

  @Get()
  async obtenirCommandes(
    @UtilisateurActuel() user,
    @Query('sousRestaurantId') sousRestaurantId?: string,
    @Query('statut') statut?: 'EN_ATTENTE' | 'EN_PREPARATION' | 'SERVIE',
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.obtenirCommandesParServeur(
      serveurId,
      sousRestaurantId,
      statut,
    );
  }

  @Get(':commandeId')
  async obtenirCommande(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.obtenirCommande(serveurId, commandeId);
  }

  @Patch(':commandeId/statut')
  async mettreAJourStatutCommande(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
    @Body() updateStatusDto: UpdateCommandeStatusDto,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.mettreAJourStatutCommande(
      serveurId,
      commandeId,
      updateStatusDto,
    );
  }

  @Put(':commandeId')
  async mettreAJourCommande(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
    @Body() updateDto: UpdateCommandeDto,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.mettreAJourCommande(serveurId, commandeId, updateDto);
  }

  @Delete(':commandeId')
  async supprimerCommande(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.supprimerCommande(serveurId, commandeId);
  }

  // ========== ITEMS DE COMMANDE ==========

  @Post(':commandeId/items')
  async ajouterItemCommande(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
    @Body() createItemDto: CreateItemCommandeItemDto,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.ajouterItemCommande(serveurId, commandeId, createItemDto);
  }

  @Put(':commandeId/items/:itemId/quantite')
  async mettreAJourQuantiteItem(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
    @Param('itemId') itemId: string,
    @Body('quantite') quantite: number,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.mettreAJourQuantiteItem(
      serveurId,
      commandeId,
      itemId,
      quantite,
    );
  }

  @Delete(':commandeId/items/:itemId')
  async supprimerItemCommande(
    @UtilisateurActuel() user,
    @Param('commandeId') commandeId: string,
    @Param('itemId') itemId: string,
  ) {
    const serveurId = await this.getServeurId(user.utilisateurId);
    return this.commandesService.supprimerItemCommande(serveurId, commandeId, itemId);
  }
}
