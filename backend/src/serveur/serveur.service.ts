import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ServeurService {
  constructor(private prisma: PrismaService) {}

  private async obtenirEtablissementId(utilisateurId: string): Promise<string> {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
    });

    if (!serveur) {
      throw new ForbiddenException('Serveur non trouvé');
    }

    return serveur.etablissementId;
  }

  private async obtenirServeur(utilisateurId: string) {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
      include: {
        sousRestaurant: true,
      },
    });

    if (!serveur) {
      throw new ForbiddenException('Serveur non trouvé');
    }

    if (!serveur.sousRestaurant) {
      throw new ForbiddenException('Aucun sous-restaurant assigné à ce serveur');
    }

    return serveur;
  }

  async obtenirEtablissementDuServeur(utilisateurId: string) {
    const serveur = await this.prisma.serveur.findUnique({
      where: { utilisateurId },
      include: {
        etablissement: true,
      },
    });

    if (!serveur) {
      throw new NotFoundException('Serveur non trouvé');
    }

    return serveur.etablissement;
  }

  async obtenirSousRestaurantDuServeur(utilisateurId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);
    return serveur.sousRestaurant;
  }

  async obtenirSousRestaurants(utilisateurId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Le serveur ne voit que son sous-restaurant assigné
    return [serveur.sousRestaurant];
  }

  async obtenirMenu(utilisateurId: string, sousRestaurantId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
      include: {
        categories: {
          where: { estActive: true },
          include: {
            plats: {
              where: { estActif: true },
              include: {
                images: {
                  orderBy: { ordre: 'asc' },
                },
              },
            },
          },
          orderBy: { ordre: 'asc' },
        },
      },
    });

    if (!sousRestaurant) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    return sousRestaurant;
  }

  async obtenirCategories(utilisateurId: string, sousRestaurantId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    return this.prisma.categorie.findMany({
      where: {
        sousRestaurantId,
        estActive: true,
      },
      orderBy: { ordre: 'asc' },
    });
  }

  async obtenirPlatsDuCategorie(
    utilisateurId: string,
    sousRestaurantId: string,
    categorieId: string,
  ) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    return this.prisma.plat.findMany({
      where: {
        categorieId,
        estActif: true,
      },
      include: {
        images: {
          orderBy: { ordre: 'asc' },
        },
      },
      orderBy: { nom: 'asc' },
    });
  }
}
