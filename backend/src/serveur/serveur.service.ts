import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ServeurService {
  constructor(private prisma: PrismaService) {}

  // Convert image data to base64 data URI
  private convertImageToBase64(imageBuffer: Buffer, mimeType: string): string {
    if (!imageBuffer) return '';
    const base64 = imageBuffer.toString('base64');
    return `data:${mimeType || 'image/jpeg'};base64,${base64}`;
  }

  // Transform category to include base64 image
  private transformCategorie(categorie: any): any {
    if (!categorie) return categorie;
    return {
      ...categorie,
      photoAffichage: categorie.photoAffichage
        ? this.convertImageToBase64(
            categorie.photoAffichage,
            categorie.photoTypeContenu || 'image/jpeg',
          )
        : null,
    };
  }

  // Transform plat images to base64
  private transformPlat(plat: any): any {
    if (!plat) return plat;
    return {
      ...plat,
      images: (plat.images || []).map((img) => ({
        ...img,
        donnees: img.donnees
          ? this.convertImageToBase64(img.donnees, img.typeContenu || 'image/jpeg')
          : null,
      })),
    };
  }

  // Transform menu data
  private transformMenu(menu: any): any {
    if (!menu) return menu;
    return {
      ...menu,
      categories: (menu.categories || []).map((cat) => ({
        ...this.transformCategorie(cat),
        plats: (cat.plats || []).map((plat) => this.transformPlat(plat)),
      })),
    };
  }

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

    return this.transformMenu(sousRestaurant);
  }

  async obtenirCategories(utilisateurId: string, sousRestaurantId: string) {
    const serveur = await this.obtenirServeur(utilisateurId);

    // Vérifier que le sousRestaurantId correspond au sous-restaurant assigné
    if (!serveur.sousRestaurant || serveur.sousRestaurant.id !== sousRestaurantId) {
      throw new ForbiddenException('Vous n\'avez accès qu\'à votre sous-restaurant assigné');
    }

    const categories = await this.prisma.categorie.findMany({
      where: {
        sousRestaurantId,
        estActive: true,
      },
      orderBy: { ordre: 'asc' },
    });

    return categories.map((cat) => this.transformCategorie(cat));
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

    const plats = await this.prisma.plat.findMany({
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

    return plats.map((plat) => this.transformPlat(plat));
  }
}
