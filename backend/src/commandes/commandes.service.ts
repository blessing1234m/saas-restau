import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCommandeDto } from './dto/create-commande.dto';
import { UpdateCommandeStatusDto, UpdateCommandeDto } from './dto/update-commande.dto';
import { CreateItemCommandeItemDto } from './dto/item-commande.dto';

@Injectable()
export class CommandesService {
  constructor(private prisma: PrismaService) {}

  // Vérifier que le serveur a accès à ce sous-restaurant
  private async verifierAccessServeur(
    serveurId: string,
    sousRestaurantId: string,
  ): Promise<{ etablissementId: string; serveur: any }> {
    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
      include: { etablissement: true },
    });

    if (!serveur) {
      throw new ForbiddenException('Serveur non trouvé');
    }

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== serveur.etablissementId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à ce sous-restaurant',
      );
    }

    return { etablissementId: serveur.etablissementId, serveur };
  }

  // ========== COMMANDES ==========

  async creerCommande(
    serveurId: string,
    createCommandeDto: CreateCommandeDto,
  ) {
    await this.verifierAccessServeur(serveurId, createCommandeDto.sousRestaurantId);

    // Vérifier que la table existe et appartient au bon sous-restaurant
    const table = await this.prisma.table.findUnique({
      where: { id: createCommandeDto.tableId },
    });

    if (!table || table.sousRestaurantId !== createCommandeDto.sousRestaurantId) {
      throw new NotFoundException('Table non trouvée');
    }

    // Vérifier que les plats existent et récupérer leurs prix
    const plats = await this.prisma.plat.findMany({
      where: {
        id: { in: createCommandeDto.items.map((item) => item.platId) },
      },
      include: { categorie: true },
    });

    if (plats.length !== createCommandeDto.items.length) {
      throw new NotFoundException('Un ou plusieurs plats n\'existent pas');
    }

    // Vérifier que tous les plats appartiennent au bon sous-restaurant
    for (const plat of plats) {
      if (plat.categorie.sousRestaurantId !== createCommandeDto.sousRestaurantId) {
        throw new ForbiddenException(
          `Le plat ${plat.nom} n'appartient pas à ce sous-restaurant`,
        );
      }
    }

    // Calculer le total de la commande
    let totalCommande = 0;
    const itemsData = createCommandeDto.items.map((item) => {
      const plat = plats.find((p) => p.id === item.platId);
      const sousTotal = plat!.prix * item.quantite;
      totalCommande += sousTotal;

      return {
        platId: item.platId,
        quantite: item.quantite,
        prixUnitaire: plat!.prix,
        sousTotal,
      };
    });

    // Créer la commande avec ses items
    const commande = await this.prisma.commande.create({
      data: {
        tableId: createCommandeDto.tableId,
        sousRestaurantId: createCommandeDto.sousRestaurantId,
        serveurId,
        totalCommande,
        notes: createCommandeDto.notes,
        items: {
          create: itemsData,
        },
      },
      include: {
        items: {
          include: {
            plat: true,
          },
        },
        table: true,
        serveur: {
          include: {
            utilisateur: {
              select: {
                codeAgent: true,
              },
            },
          },
        },
      },
    });

    return commande;
  }

  async obtenirCommandesParServeur(
    serveurId: string,
    sousRestaurantId?: string,
    statut?: 'EN_ATTENTE' | 'EN_PREPARATION' | 'SERVIE',
  ) {
    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
    });

    if (!serveur) {
      throw new ForbiddenException('Serveur non trouvé');
    }

    const whereClause: any = {
      serveurId,
    };

    if (sousRestaurantId) {
      // Vérifier l'accès
      await this.verifierAccessServeur(serveurId, sousRestaurantId);
      whereClause.sousRestaurantId = sousRestaurantId;
    }

    if (statut) {
      whereClause.statut = statut;
    }

    return this.prisma.commande.findMany({
      where: whereClause,
      include: {
        items: {
          include: {
            plat: {
              include: {
                categorie: true,
              },
            },
          },
        },
        table: true,
        sousRestaurant: true,
        serveur: {
          include: {
            utilisateur: {
              select: {
                codeAgent: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async obtenirCommande(serveurId: string, commandeId: string) {
    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
      include: {
        items: {
          include: {
            plat: {
              include: {
                categorie: true,
              },
            },
          },
        },
        table: true,
        sousRestaurant: true,
        serveur: {
          include: {
            utilisateur: {
              select: {
                codeAgent: true,
              },
            },
          },
        },
      },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    return commande;
  }

  async mettreAJourStatutCommande(
    serveurId: string,
    commandeId: string,
    updateStatusDto: UpdateCommandeStatusDto,
  ) {
    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    return this.prisma.commande.update({
      where: { id: commandeId },
      data: { statut: updateStatusDto.statut },
      include: {
        items: {
          include: {
            plat: true,
          },
        },
        table: true,
        sousRestaurant: true,
      },
    });
  }

  async mettreAJourCommande(
    serveurId: string,
    commandeId: string,
    updateDto: UpdateCommandeDto,
  ) {
    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    return this.prisma.commande.update({
      where: { id: commandeId },
      data: updateDto,
      include: {
        items: {
          include: {
            plat: true,
          },
        },
      },
    });
  }

  async supprimerCommande(serveurId: string, commandeId: string) {
    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    // Empêcher la suppression si la commande est en préparation ou servie
    if (commande.statut !== 'EN_ATTENTE') {
      throw new BadRequestException(
        'Vous ne pouvez supprimer que les commandes en attente',
      );
    }

    await this.prisma.commande.delete({
      where: { id: commandeId },
    });

    return { message: 'Commande supprimée avec succès' };
  }

  // ========== ITEMS DE COMMANDE ==========

  async ajouterItemCommande(
    serveurId: string,
    commandeId: string,
    createItemDto: CreateItemCommandeItemDto,
  ) {
    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
      include: { items: true },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    // Empêcher l'ajout d'items si la commande est en préparation ou servie
    if (commande.statut !== 'EN_ATTENTE') {
      throw new BadRequestException(
        'Vous ne pouvez ajouter des items que pour les commandes en attente',
      );
    }

    // Vérifier que le plat existe et récupérer son prix
    const plat = await this.prisma.plat.findUnique({
      where: { id: createItemDto.platId },
      include: { categorie: true },
    });

    if (!plat) {
      throw new NotFoundException('Plat non trouvé');
    }

    if (plat.categorie.sousRestaurantId !== commande.sousRestaurantId) {
      throw new ForbiddenException(
        'Ce plat n\'appartient pas au même sous-restaurant',
      );
    }

    // Vérifier si l'item existe déjà
    const existantItem = commande.items.find((item) => item.platId === createItemDto.platId);

    if (existantItem) {
      // Mettre à jour la quantité
      const nouvelleSousTotal = plat.prix * (existantItem.quantite + createItemDto.quantite);
      const totalAjoute = plat.prix * createItemDto.quantite;

      await this.prisma.itemCommande.update({
        where: { id: existantItem.id },
        data: {
          quantite: existantItem.quantite + createItemDto.quantite,
          sousTotal: nouvelleSousTotal,
        },
      });

      // Mettre à jour le total de la commande
      await this.prisma.commande.update({
        where: { id: commandeId },
        data: {
          totalCommande: commande.totalCommande + totalAjoute,
        },
      });
    } else {
      // Créer un nouvel item
      const sousTotal = plat.prix * createItemDto.quantite;

      await this.prisma.itemCommande.create({
        data: {
          commandeId,
          platId: createItemDto.platId,
          quantite: createItemDto.quantite,
          prixUnitaire: plat.prix,
          sousTotal,
        },
      });

      // Mettre à jour le total de la commande
      await this.prisma.commande.update({
        where: { id: commandeId },
        data: {
          totalCommande: commande.totalCommande + sousTotal,
        },
      });
    }

    return this.obtenirCommande(serveurId, commandeId);
  }

  async mettreAJourQuantiteItem(
    serveurId: string,
    commandeId: string,
    itemId: string,
    nouvelleQuantite: number,
  ) {
    if (nouvelleQuantite < 1) {
      throw new BadRequestException('La quantité doit être au minimum 1');
    }

    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
      include: { items: true },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    // Empêcher la modification si la commande est en préparation ou servie
    if (commande.statut !== 'EN_ATTENTE') {
      throw new BadRequestException(
        'Vous ne pouvez modifier les items que pour les commandes en attente',
      );
    }

    const item = await this.prisma.itemCommande.findUnique({
      where: { id: itemId },
    });

    if (!item || item.commandeId !== commandeId) {
      throw new NotFoundException('Item non trouvé');
    }

    const ancienneSousTotal = item.sousTotal;
    const nouvelleSousTotal = item.prixUnitaire * nouvelleQuantite;
    const difference = nouvelleSousTotal - ancienneSousTotal;

    await this.prisma.itemCommande.update({
      where: { id: itemId },
      data: {
        quantite: nouvelleQuantite,
        sousTotal: nouvelleSousTotal,
      },
    });

    // Mettre à jour le total de la commande
    await this.prisma.commande.update({
      where: { id: commandeId },
      data: {
        totalCommande: commande.totalCommande + difference,
      },
    });

    return this.obtenirCommande(serveurId, commandeId);
  }

  async supprimerItemCommande(
    serveurId: string,
    commandeId: string,
    itemId: string,
  ) {
    const commande = await this.prisma.commande.findUnique({
      where: { id: commandeId },
      include: { items: true },
    });

    if (!commande) {
      throw new NotFoundException('Commande non trouvée');
    }

    if (commande.serveurId !== serveurId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cette commande',
      );
    }

    // Empêcher la suppression si la commande est en préparation ou servie
    if (commande.statut !== 'EN_ATTENTE') {
      throw new BadRequestException(
        'Vous ne pouvez supprimer les items que pour les commandes en attente',
      );
    }

    const item = await this.prisma.itemCommande.findUnique({
      where: { id: itemId },
    });

    if (!item || item.commandeId !== commandeId) {
      throw new NotFoundException('Item non trouvé');
    }

    // Supprimer l'item
    await this.prisma.itemCommande.delete({
      where: { id: itemId },
    });

    // Mettre à jour le total de la commande
    const totalAjuste = commande.totalCommande - item.sousTotal;

    if (totalAjuste < 0) {
      throw new BadRequestException('Le total de la commande serait négatif');
    }

    await this.prisma.commande.update({
      where: { id: commandeId },
      data: {
        totalCommande: totalAjuste,
      },
    });

    return this.obtenirCommande(serveurId, commandeId);
  }
}
