import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { CreateSousRestaurantDto, UpdateSousRestaurantDto } from './dto/sous-restaurant.dto';
import { CreateTableDto, UpdateTableDto } from './dto/table.dto';
import { CreateCategorieDto, UpdateCategorieDto } from './dto/categorie.dto';
import { CreatePlatDto, UpdatePlatDto } from './dto/plat.dto';
import { CreateServeurDto } from './dto/serveur.dto';
import { ChangePasswordDto, ChangeUserPasswordDto } from '../auth/dto/change-password.dto';
import { UpdateMonEtablissementDto } from './dto/etablissement.dto';

@Injectable()
export class AdminEtablissementService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
  ) {}

  private convertImageToBase64(imageBuffer: Buffer, mimeType?: string): string {
    if (!imageBuffer) return '';
    const base64 = imageBuffer.toString('base64');
    return `data:${mimeType || 'image/jpeg'};base64,${base64}`;
  }

  private parseBase64Image(
    image: string,
    fallbackFileName: string,
  ): { buffer: Buffer; mimeType: string; fileName: string } {
    let buffer: Buffer;
    let mimeType = 'image/jpeg';

    if (image.startsWith('data:')) {
      const [header, base64String] = image.split(',');
      mimeType = header.match(/:(.*?);/)?.[1] || 'image/jpeg';
      buffer = Buffer.from(base64String, 'base64');
    } else {
      buffer = Buffer.from(image, 'base64');
    }

    return {
      buffer,
      mimeType,
      fileName: fallbackFileName,
    };
  }

  private formatEtablissementBranding(etab: any) {
    if (!etab) return etab;

    const result: any = { ...etab };

    if (etab.logoAffichage) {
      try {
        const logoBuffer = Buffer.isBuffer(etab.logoAffichage)
          ? etab.logoAffichage
          : Buffer.from(etab.logoAffichage);
        result.logoAffichage = this.convertImageToBase64(
          logoBuffer,
          etab.logoTypeContenu,
        );
      } catch {
        result.logoAffichage = null;
      }
    } else {
      result.logoAffichage = null;
    }

    if (etab.banniereAffichage) {
      try {
        const bannerBuffer = Buffer.isBuffer(etab.banniereAffichage)
          ? etab.banniereAffichage
          : Buffer.from(etab.banniereAffichage);
        result.banniereAffichage = this.convertImageToBase64(
          bannerBuffer,
          etab.banniereTypeContenu,
        );
      } catch {
        result.banniereAffichage = null;
      }
    } else {
      result.banniereAffichage = null;
    }

    return result;
  }

  // Helper pour convertir une catégorie avec photo en base64
  private formatCategorie(cat: any) {
    const result: any = {
      id: cat.id,
      nom: cat.nom,
      description: cat.description,
      ordre: cat.ordre,
      sousRestaurantId: cat.sousRestaurantId,
      photoTypeContenu: cat.photoTypeContenu,
      photoNomFichier: cat.photoNomFichier,
      photoTaille: cat.photoTaille,
      createdAt: cat.createdAt,
      updatedAt: cat.updatedAt,
      photoAffichage: null, // Par défaut null
    };
    
    // Convertir la photo en base64 si elle existe
    if (cat.photoAffichage) {
      try {
        let buffer = cat.photoAffichage;
        // Si ce n'est pas un Buffer, essayer de le convertir
        if (!Buffer.isBuffer(buffer)) {
          buffer = Buffer.from(buffer);
        }
        const mimeType = cat.photoTypeContenu || 'image/jpeg';
        result.photoAffichage = `data:${mimeType};base64,${buffer.toString('base64')}`;
        // log supprimé
      } catch (error) {
        console.error('[formatCategorie] Erreur conversion photo en base64:', error, 'cat.photoAffichage type:', typeof cat.photoAffichage);
      }
    }
    
    return result;
  }

  // Récupérer l'établissementId de l'admin
  private async obtenirEtablissementId(adminId: string): Promise<string> {
    const admin = await this.prisma.adminEtablissement.findUnique({
      where: { utilisateurId: adminId },
    });

    if (!admin) {
      throw new ForbiddenException('Admin non trouvé');
    }

    return admin.etablissementId;
  }

  // Vérifier que l'admin a accès à cet établissement
  private async verifierAccessEtablissement(
    adminId: string,
    etablissementId: string,
  ): Promise<void> {
    const id = await this.obtenirEtablissementId(adminId);

    if (id !== etablissementId) {
      throw new ForbiddenException(
        'Vous n\'avez pas accès à cet établissement',
      );
    }
  }

  // ========== DASHBOARD ==========

  async obtenirMonEtablissement(adminId: string) {
    try {
      // D'abord, chercher l'admin
      const admin = await this.prisma.adminEtablissement.findUnique({
        where: { utilisateurId: adminId },
      });

      if (!admin) {
        throw new ForbiddenException('Aucun établissement trouvé pour cet administrateur');
      }

      // Ensuite, charger l'établissement avec les relations
      const etablissement = await this.prisma.etablissement.findUnique({
        where: { id: admin.etablissementId },
        include: {
          sousRestaurants: {
            where: { estActif: true },
            include: {
              tables: true,
              categories: {
                where: { estActive: true },
              },
            },
          },
          serveurs: true,
        },
      });

      if (!etablissement) {
        throw new ForbiddenException('L\'établissement associé n\'existe plus');
      }

      return this.formatEtablissementBranding(etablissement);
    } catch (error) {
      if (error instanceof ForbiddenException) {
        throw error;
      }
      console.error('ERREUR DANS obtenirMonEtablissement:', error);
      throw new ForbiddenException('Erreur lors du chargement de l\'établissement: ' + (error.message || 'Erreur inconnue'));
    }
  }

  async mettreAJourMonEtablissement(
    adminId: string,
    dto: UpdateMonEtablissementDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const updateData: any = {
      nom: dto.nom,
      ville: dto.ville,
      telephone: dto.telephone,
      email: dto.email,
    };

    if (dto.logoAffichage !== undefined) {
      if (dto.logoAffichage.trim() == '') {
        updateData.logoAffichage = null;
        updateData.logoTypeContenu = null;
        updateData.logoNomFichier = null;
        updateData.logoTaille = null;
      } else {
        try {
          const logo = this.parseBase64Image(dto.logoAffichage, 'etablissement-logo.jpg');
          updateData.logoAffichage = logo.buffer;
          updateData.logoTypeContenu = logo.mimeType;
          updateData.logoNomFichier = logo.fileName;
          updateData.logoTaille = logo.buffer.length;
        } catch {
          throw new BadRequestException('Logo invalide');
        }
      }
    }

    if (dto.banniereAffichage !== undefined) {
      if (dto.banniereAffichage.trim() == '') {
        updateData.banniereAffichage = null;
        updateData.banniereTypeContenu = null;
        updateData.banniereNomFichier = null;
        updateData.banniereTaille = null;
      } else {
        try {
          const banner = this.parseBase64Image(
            dto.banniereAffichage,
            'etablissement-banniere.jpg',
          );
          updateData.banniereAffichage = banner.buffer;
          updateData.banniereTypeContenu = banner.mimeType;
          updateData.banniereNomFichier = banner.fileName;
          updateData.banniereTaille = banner.buffer.length;
        } catch {
          throw new BadRequestException('Bannière invalide');
        }
      }
    }

    const updated = await this.prisma.etablissement.update({
      where: { id: etablissementId },
      data: updateData,
    });

    return this.formatEtablissementBranding(updated);
  }

  // ========== SOUS-RESTAURANTS ==========

  async creerSousRestaurant(
    adminId: string,
    createSousRestaurantDto: CreateSousRestaurantDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    // récupérer l'établissement pour vérifier la catégorie
    const etab = await this.prisma.etablissement.findUnique({
      where: { id: etablissementId },
    });
    if (!etab) {
      throw new NotFoundException('Établissement introuvable');
    }

    // ne pas autoriser la création lorsque la catégorie est SIMPLE
    if (etab.categorie === 'SIMPLE') {
      throw new ForbiddenException(
        'Impossible d\'ajouter un sous-restaurant à un établissement de catégorie SIMPLE',
      );
    }

    const existant = await this.prisma.sousRestaurant.findFirst({
      where: {
        etablissementId,
        nom: createSousRestaurantDto.nom,
      },
    });

    if (existant) {
      throw new BadRequestException(
        'Un sous-restaurant avec ce nom existe déjà',
      );
    }

    return this.prisma.sousRestaurant.create({
      data: {
        nom: createSousRestaurantDto.nom,
        description: createSousRestaurantDto.description,
        etablissementId,
      },
    });
  }

  async obtenirSousRestaurants(adminId: string) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    // Rattrapage: un établissement SIMPLE doit toujours avoir un sous-restaurant unique.
    const etablissement = await this.prisma.etablissement.findUnique({
      where: { id: etablissementId },
      select: { categorie: true },
    });

    if (!etablissement) {
      throw new NotFoundException('Établissement introuvable');
    }

    if (etablissement.categorie === 'SIMPLE') {
      const sousRestaurantExistant = await this.prisma.sousRestaurant.findFirst({
        where: { etablissementId },
        select: { id: true },
      });

      if (!sousRestaurantExistant) {
        await this.prisma.sousRestaurant.create({
          data: {
            nom: 'Restaurant principal',
            description: 'Sous-restaurant principal (créé automatiquement)',
            etablissementId,
          },
        });
      }
    }

    return this.prisma.sousRestaurant.findMany({
      where: { etablissementId },
      include: {
        tables: true,
        categories: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async obtenirSousRestaurant(
    adminId: string,
    sousRestaurantId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
      include: {
        tables: true,
        categories: {
          include: {
            plats: {
              include: {
                images: {
                  orderBy: { ordre: 'asc' },
                },
              },
            },
          },
        },
      },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    // Retourner sans les buffers pour éviter erreur sérialisation JSON
    return {
      id: sousRestaurant.id,
      nom: sousRestaurant.nom,
      etablissementId: sousRestaurant.etablissementId,
      createdAt: sousRestaurant.createdAt,
      updatedAt: sousRestaurant.updatedAt,
      tables: sousRestaurant.tables,
      categories: sousRestaurant.categories.map(cat => {
        const formatted = this.formatCategorie(cat);
        return {
          ...formatted,
          plats: cat.plats.map(plat => ({
            id: plat.id,
            nom: plat.nom,
            description: plat.description,
            prix: plat.prix,
            categorieId: plat.categorieId,
            createdAt: plat.createdAt,
            updatedAt: plat.updatedAt,
            images: plat.images.map(img => ({
              id: img.id,
              typeContenu: img.typeContenu,
              nomFichier: img.nomFichier,
              taille: img.taille,
              ordre: img.ordre,
              platId: img.platId,
              createdAt: img.createdAt,
              updatedAt: img.updatedAt,
            })),
          })),
        };
      }),
    };
  }

  async mettreAJourSousRestaurant(
    adminId: string,
    sousRestaurantId: string,
    updateDto: UpdateSousRestaurantDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    return this.prisma.sousRestaurant.update({
      where: { id: sousRestaurantId },
      data: updateDto,
    });
  }

  async supprimerSousRestaurant(
    adminId: string,
    sousRestaurantId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    return this.prisma.sousRestaurant.delete({
      where: { id: sousRestaurantId },
    });
  }

  // ========== TABLES ==========

  async creerTable(
    adminId: string,
    sousRestaurantId: string,
    createTableDto: CreateTableDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const tableExistante = await this.prisma.table.findFirst({
      where: {
        sousRestaurantId,
        numero: createTableDto.numero,
      },
    });

    if (tableExistante) {
      throw new BadRequestException('Cette table existe déjà dans ce sous-restaurant');
    }

    return this.prisma.table.create({
      data: {
        numero: createTableDto.numero,
        sousRestaurantId,
      },
    });
  }

  async obtenirTables(
    adminId: string,
    sousRestaurantId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    return this.prisma.table.findMany({
      where: { sousRestaurantId },
      include: {
        commandes: {
          where: { statut: 'EN_ATTENTE' },
        },
      },
      orderBy: { numero: 'asc' },
    });
  }

  async mettreAJourTable(
    adminId: string,
    sousRestaurantId: string,
    tableId: string,
    updateTableDto: UpdateTableDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const table = await this.prisma.table.findUnique({
      where: { id: tableId },
    });

    if (!table || table.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Table non trouvée');
    }

    return this.prisma.table.update({
      where: { id: tableId },
      data: updateTableDto,
    });
  }

  async supprimerTable(
    adminId: string,
    sousRestaurantId: string,
    tableId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const table = await this.prisma.table.findUnique({
      where: { id: tableId },
    });

    if (!table || table.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Table non trouvée');
    }

    return this.prisma.table.delete({
      where: { id: tableId },
    });
  }

  // ========== CATÉGORIES ==========

  async creerCategorie(
    adminId: string,
    sousRestaurantId: string,
    createCategorieDto: CreateCategorieDto,
  ) {
    // log de création catégorie supprimé

    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorieExistante = await this.prisma.categorie.findFirst({
      where: {
        sousRestaurantId,
        nom: createCategorieDto.nom,
      },
    });

    if (categorieExistante) {
      throw new BadRequestException('Une catégorie avec ce nom existe déjà');
    }

    // Traiter la photo si fournie
    let photoData: any = {};
    if (createCategorieDto.photoAffichage) {
      try {
        let buffer: Buffer;
        let mimeType = 'image/jpeg';

        if (createCategorieDto.photoAffichage.startsWith('data:')) {
          // Format: data:image/jpeg;base64,...
          const [header, base64String] = createCategorieDto.photoAffichage.split(',');
          mimeType = header.match(/:(.*?);/)?.[1] || 'image/jpeg';
          buffer = Buffer.from(base64String, 'base64');
        } else {
          buffer = Buffer.from(createCategorieDto.photoAffichage, 'base64');
        }

        // log de traitement photo supprimé

        photoData = {
          photoAffichage: buffer,
          photoTypeContenu: mimeType,
          photoNomFichier: 'categorie-photo.jpg',
          photoTaille: buffer.length,
        };
      } catch (error) {
        console.error('[CATEGORIE] Erreur traitement photo:', error);
        throw new BadRequestException('Erreur lors du traitement de la photo');
      }
    }

    return this.prisma.categorie.create({
      data: {
        nom: createCategorieDto.nom,
        description: createCategorieDto.description,
        ordre: createCategorieDto.ordre || 0,
        sousRestaurantId,
        ...photoData,
      },
    }).then(cat => {
      // log succès création supprimé
      return this.formatCategorie(cat);
    }).catch(error => {
      console.error('[CATEGORIE] Erreur Prisma lors de la création:', error);
      throw error;
    });
  }

  async obtenirCategories(
    adminId: string,
    sousRestaurantId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categories = await this.prisma.categorie.findMany({
      where: { sousRestaurantId },
      include: {
        plats: {
          include: {
            images: {
              orderBy: { ordre: 'asc' },
            },
          },
        },
      },
      orderBy: { ordre: 'asc' },
    });

    // logs de récupération des catégories supprimés

    // Formater les catégories avec photos en base64
    return categories.map(cat => {
      const formatted = this.formatCategorie(cat);
      return {
        ...formatted,
        plats: cat.plats,
      };
    });
  }

  async mettreAJourCategorie(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
    updateCategorieDto: UpdateCategorieDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    // Traiter la photo si fournie
    const updateData: any = {
      nom: updateCategorieDto.nom,
      description: updateCategorieDto.description,
      ordre: updateCategorieDto.ordre,
    };

    if (updateCategorieDto.photoAffichage) {
      let buffer: Buffer;
      let mimeType = 'image/jpeg';

      if (updateCategorieDto.photoAffichage.startsWith('data:')) {
        // Format: data:image/jpeg;base64,...
        const [header, base64String] = updateCategorieDto.photoAffichage.split(',');
        mimeType = header.match(/:(.*?);/)?.[1] || 'image/jpeg';
        buffer = Buffer.from(base64String, 'base64');
      } else {
        buffer = Buffer.from(updateCategorieDto.photoAffichage, 'base64');
      }

      updateData.photoAffichage = buffer;
      updateData.photoTypeContenu = mimeType;
      updateData.photoNomFichier = 'categorie-photo.jpg';
      updateData.photoTaille = buffer.length;
    }

    return this.prisma.categorie.update({
      where: { id: categorieId },
      data: updateData,
    }).then(cat => {
      return this.formatCategorie(cat);
    });
  }

  async supprimerCategorie(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    return this.prisma.categorie.delete({
      where: { id: categorieId },
    });
  }

  // ========== PLATS ==========

  async creerPlat(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
    createPlatDto: CreatePlatDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    // Limiter à 3 images
    if (createPlatDto.images && createPlatDto.images.length > 3) {
      throw new BadRequestException('Maximum 3 images autorisées');
    }

    // Préparer les données des images
    const imagesData = createPlatDto.images?.map((imageBase64, index) => {
      // Décoder le base64
      let buffer: Buffer;
      let mimeType = 'image/jpeg';
      let fileName = `plat-image-${index + 1}.jpg`;

      if (imageBase64.startsWith('data:')) {
        // Format: data:image/jpeg;base64,...
        const [header, base64String] = imageBase64.split(',');
        mimeType = header.match(/:(.*?);/)?.[1] || 'image/jpeg';
        buffer = Buffer.from(base64String, 'base64');
      } else {
        buffer = Buffer.from(imageBase64, 'base64');
      }

      return {
        donnees: buffer,
        typeContenu: mimeType,
        nomFichier: fileName,
        taille: buffer.length,
        ordre: index,
      };
    }) ?? [];

    return this.prisma.plat.create({
      data: {
        nom: createPlatDto.nom,
        description: createPlatDto.description,
        prix: createPlatDto.prix,
        categorieId,
        images: {
          create: imagesData,
        },
      },
      include: {
        images: {
          orderBy: { ordre: 'asc' },
        },
      },
    }).then(plat => {
      // Retourner sans les buffers pour éviter erreur sérialisation JSON
      return {
        id: plat.id,
        nom: plat.nom,
        description: plat.description,
        prix: plat.prix,
        categorieId: plat.categorieId,
        createdAt: plat.createdAt,
        updatedAt: plat.updatedAt,
        images: plat.images.map(img => ({
          id: img.id,
          typeContenu: img.typeContenu,
          nomFichier: img.nomFichier,
          taille: img.taille,
          ordre: img.ordre,
          platId: img.platId,
          createdAt: img.createdAt,
          updatedAt: img.updatedAt,
          // Ajouter les données image en base64
          donnees: img.donnees.toString('base64'),
        })),
      };
    });
  }

  async obtenirPlats(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    const plats = await this.prisma.plat.findMany({
      where: { categorieId },
      include: {
        images: {
          orderBy: { ordre: 'asc' },
        },
      },
    });

    // Retourner sans les buffers pour éviter erreur sérialisation JSON
    return plats.map(plat => ({
      id: plat.id,
      nom: plat.nom,
      description: plat.description,
      prix: plat.prix,
      categorieId: plat.categorieId,
      createdAt: plat.createdAt,
      updatedAt: plat.updatedAt,
      images: plat.images.map(img => ({
        id: img.id,
        typeContenu: img.typeContenu,
        nomFichier: img.nomFichier,
        taille: img.taille,
        ordre: img.ordre,
        platId: img.platId,
        createdAt: img.createdAt,
        updatedAt: img.updatedAt,
        // Ajouter les données image en base64
        donnees: img.donnees.toString('base64'),
      })),
    }));
  }

  async obtenirPlat(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
    platId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    const plat = await this.prisma.plat.findUnique({
      where: { id: platId },
      include: {
        images: {
          orderBy: { ordre: 'asc' },
        },
      },
    });

    if (!plat || plat.categorieId !== categorieId) {
      throw new NotFoundException('Plat non trouvé');
    }

    // Retourner sans les buffers pour éviter erreur sérialisation JSON
    return {
      id: plat.id,
      nom: plat.nom,
      description: plat.description,
      prix: plat.prix,
      categorieId: plat.categorieId,
      createdAt: plat.createdAt,
      updatedAt: plat.updatedAt,
      images: plat.images.map(img => ({
        id: img.id,
        typeContenu: img.typeContenu,
        nomFichier: img.nomFichier,
        taille: img.taille,
        ordre: img.ordre,
        platId: img.platId,
        createdAt: img.createdAt,
        updatedAt: img.updatedAt,
        // Ajouter les données image en base64
        donnees: img.donnees.toString('base64'),
      })),
    };
  }

  async mettreAJourPlat(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
    platId: string,
    updatePlatDto: UpdatePlatDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    const plat = await this.prisma.plat.findUnique({
      where: { id: platId },
    });

    if (!plat || plat.categorieId !== categorieId) {
      throw new NotFoundException('Plat non trouvé');
    }

    // Préparer les données de mise à jour
    const updateData: any = {};
    if (updatePlatDto.nom !== undefined) updateData.nom = updatePlatDto.nom;
    if (updatePlatDto.description !== undefined) updateData.description = updatePlatDto.description;
    if (updatePlatDto.prix !== undefined) updateData.prix = updatePlatDto.prix;

    // Gérer la suppression des images existantes
    if (updatePlatDto.removeImageIds && updatePlatDto.removeImageIds.length > 0) {
      // Supprimer les images spécifiées
      for (const imageId of updatePlatDto.removeImageIds) {
        await this.prisma.imagePlat.delete({
          where: { id: imageId },
        }).catch(() => {
          // Ignorer les erreurs si l'image n'existe pas
        });
      }
    }

    // Gérer l'ajout des nouvelles images
    if (updatePlatDto.images && updatePlatDto.images.length > 0) {
      // Limiter à 3 images totales
      const currentImageCount = await this.prisma.imagePlat.count({
        where: { platId: platId },
      });
      
      if (currentImageCount + updatePlatDto.images.length > 3) {
        throw new BadRequestException('Maximum 3 images autorisées au total');
      }

      // Préparer les données des nouvelles images
      const imagesData = updatePlatDto.images.map((imageBase64, index) => {
        let buffer: Buffer;
        let mimeType = 'image/jpeg';
        let fileName = `plat-image-${index + 1}.jpg`;

        if (imageBase64.startsWith('data:')) {
          const [header, base64String] = imageBase64.split(',');
          mimeType = header.match(/:(.*?);/)?.[1] || 'image/jpeg';
          buffer = Buffer.from(base64String, 'base64');
        } else {
          buffer = Buffer.from(imageBase64, 'base64');
        }

        return {
          donnees: buffer,
          typeContenu: mimeType,
          nomFichier: fileName,
          taille: buffer.length,
          ordre: index,
        };
      });

      // Créer les nouvelles images
      updateData.images = {
        create: imagesData,
      };
    }

    const updatedPlat = await this.prisma.plat.update({
      where: { id: platId },
      data: updateData,
      include: {
        images: {
          orderBy: { ordre: 'asc' },
        },
      },
    });

    // Retourner sans les buffers pour éviter erreur sérialisation JSON
    return {
      id: updatedPlat.id,
      nom: updatedPlat.nom,
      description: updatedPlat.description,
      prix: updatedPlat.prix,
      categorieId: updatedPlat.categorieId,
      createdAt: updatedPlat.createdAt,
      updatedAt: updatedPlat.updatedAt,
      images: updatedPlat.images.map(img => ({
        id: img.id,
        typeContenu: img.typeContenu,
        nomFichier: img.nomFichier,
        taille: img.taille,
        ordre: img.ordre,
        platId: img.platId,
        createdAt: img.createdAt,
        updatedAt: img.updatedAt,
        // Ajouter les données image en base64
        donnees: img.donnees.toString('base64'),
      })),
    };
  }

  async supprimerPlat(
    adminId: string,
    sousRestaurantId: string,
    categorieId: string,
    platId: string,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new NotFoundException('Sous-restaurant non trouvé');
    }

    const categorie = await this.prisma.categorie.findUnique({
      where: { id: categorieId },
    });

    if (!categorie || categorie.sousRestaurantId !== sousRestaurantId) {
      throw new NotFoundException('Catégorie non trouvée');
    }

    const plat = await this.prisma.plat.findUnique({
      where: { id: platId },
    });

    if (!plat || plat.categorieId !== categorieId) {
      throw new NotFoundException('Plat non trouvé');
    }

    return this.prisma.plat.delete({
      where: { id: platId },
    });
  }

  // ========== SERVEURS ==========

  async creerServeur(
    adminId: string,
    createServeurDto: CreateServeurDto,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const utilisateurExistant = await this.prisma.utilisateur.findUnique({
      where: { codeAgent: createServeurDto.codeAgent },
    });

    if (utilisateurExistant) {
      throw new BadRequestException('Ce code agent est déjà utilisé');
    }

    // Vérifier que le sous-restaurant appartient à l'établissement (sousRestaurantId est obligatoire)
    const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
      where: { id: createServeurDto.sousRestaurantId },
    });

    if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
      throw new BadRequestException('Sous-restaurant non trouvé ou n\'appartient pas à cet établissement');
    }

    // log supprimé pour ne pas exposer le code agent

    const utilisateur = await this.authService.creerUtilisateur(
      createServeurDto.codeAgent,
      createServeurDto.motDePasse,
      'SERVEUR',
    );

    // log utilisateur créé supprimé pour raisons de sécurité

    const serveur = await this.prisma.serveur.create({
      data: {
        utilisateurId: utilisateur.id,
        etablissementId,
        sousRestaurantId: createServeurDto.sousRestaurantId,
      },
      include: {
        utilisateur: {
          select: {
            id: true,
            codeAgent: true,
            role: true,
            estActif: true,
          },
        },
        sousRestaurant: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    // serveur créé avec succès (log supprimé)

    return serveur;
  }

  async obtenirServeurs(adminId: string) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    return this.prisma.serveur.findMany({
      where: { etablissementId },
      include: {
        utilisateur: {
          select: {
            id: true,
            codeAgent: true,
            role: true,
            estActif: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async modifierServeur(
    adminId: string,
    serveurId: string,
    updateServeurDto: any,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
    });

    if (!serveur || serveur.etablissementId !== etablissementId) {
      throw new NotFoundException('Serveur non trouvé ou non autorisé');
    }

    // Vérifier que le sousRestaurantId appartient à l'établissement si fourni
    if (updateServeurDto.sousRestaurantId) {
      const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
        where: { id: updateServeurDto.sousRestaurantId },
      });

      if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
        throw new ForbiddenException('Le sous-restaurant n\'appartient pas à votre établissement');
      }
    }

    const serveurModifie = await this.prisma.serveur.update({
      where: { id: serveurId },
      data: updateServeurDto,
      include: {
        utilisateur: {
          select: {
            id: true,
            codeAgent: true,
            role: true,
            estActif: true,
          },
        },
        sousRestaurant: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    return serveurModifie;
  }

  async modifierServeurComplet(
    adminId: string,
    serveurId: string,
    updateServeurDto: any,
  ) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    // Vérifier que le serveur existe et appartient à l'établissement
    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
      include: { utilisateur: true },
    });

    if (!serveur || serveur.etablissementId !== etablissementId) {
      throw new NotFoundException('Serveur non trouvé ou non autorisé');
    }

    // Vérifier que le sousRestaurantId appartient à l'établissement
    if (updateServeurDto.sousRestaurantId) {
      const sousRestaurant = await this.prisma.sousRestaurant.findUnique({
        where: { id: updateServeurDto.sousRestaurantId },
      });

      if (!sousRestaurant || sousRestaurant.etablissementId !== etablissementId) {
        throw new ForbiddenException('Le sous-restaurant n\'appartient pas à votre établissement');
      }
    }

    // Préparer les mises à jour
    const updateData: any = {
      codeAgent: updateServeurDto.codeAgent,
    };

    // Vérifier l'unicité du code agent si modifié
    if (
      updateServeurDto.codeAgent &&
      updateServeurDto.codeAgent !== serveur.utilisateur.codeAgent
    ) {
      const utilisateurExistant = await this.prisma.utilisateur.findUnique({
        where: { codeAgent: updateServeurDto.codeAgent },
        select: { id: true },
      });

      if (utilisateurExistant) {
        throw new BadRequestException('Ce code agent est déjà utilisé');
      }
    }

    // Mettre à jour le mot de passe si fourni
    if (updateServeurDto.ancienMotDePasse && updateServeurDto.nouveauMotDePasse) {
      // Vérifier l'ancien mot de passe
      const utilisateur = serveur.utilisateur;
      const isPasswordValid = await bcrypt.compare(
        updateServeurDto.ancienMotDePasse,
        utilisateur.motDePasse,
      );

      if (!isPasswordValid) {
        throw new UnauthorizedException('L\'ancien mot de passe est incorrect');
      }

      // Hasher et mettre à jour le nouveau mot de passe
      const hashedPassword = await bcrypt.hash(updateServeurDto.nouveauMotDePasse, 10);
      updateData.motDePasse = hashedPassword;
    }

    // Mettre à jour l'utilisateur
    try {
      await this.prisma.utilisateur.update({
        where: { id: serveur.utilisateurId },
        data: updateData,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new BadRequestException('Ce code agent est déjà utilisé');
      }
      throw error;
    }

    // Mettre à jour le serveur (sous-restaurant)
    const serveurModifie = await this.prisma.serveur.update({
      where: { id: serveurId },
      data: {
        sousRestaurantId: updateServeurDto.sousRestaurantId,
      },
      include: {
        utilisateur: {
          select: {
            id: true,
            codeAgent: true,
            role: true,
            estActif: true,
          },
        },
        sousRestaurant: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    return serveurModifie;
  }

  async basculerEtatServeur(adminId: string, serveurId: string) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
      include: { utilisateur: true },
    });

    if (!serveur || serveur.etablissementId !== etablissementId) {
      throw new NotFoundException('Serveur non trouvé');
    }

    const utilisateur = await this.prisma.utilisateur.update({
      where: { id: serveur.utilisateurId },
      data: { estActif: !serveur.utilisateur.estActif },
      select: {
        id: true,
        codeAgent: true,
        role: true,
        estActif: true,
      },
    });

    return utilisateur;
  }

  async supprimerServeur(adminId: string, serveurId: string) {
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
      include: { utilisateur: true },
    });

    if (!serveur || serveur.etablissementId !== etablissementId) {
      throw new NotFoundException('Serveur non trouvé');
    }

    // Supprimer d'abord le serveur
    await this.prisma.serveur.delete({
      where: { id: serveurId },
    });

    // Puis supprimer l'utilisateur
    await this.prisma.utilisateur.delete({
      where: { id: serveur.utilisateurId },
    });

    return { message: 'Serveur supprimé avec succès' };
  }

  // ========== GESTION DES MOTS DE PASSE ==========

  async changerMotDePasseAdminEtablissement(
    adminId: string,
    changePasswordDto: ChangePasswordDto,
  ) {
    // Récupérer l'admin d'établissement
    const adminEtablissement = await this.prisma.adminEtablissement.findUnique({
      where: { utilisateurId: adminId },
      include: { utilisateur: true },
    });

    if (!adminEtablissement) {
      throw new NotFoundException('Admin d\'établissement non trouvé');
    }

    // Vérifier l'ancien mot de passe
    const estValide = await this.authService.verifierMotDePasse(
      changePasswordDto.ancienMotDePasse,
      adminEtablissement.utilisateur.motDePasse,
    );

    if (!estValide) {
      throw new BadRequestException('L\'ancien mot de passe est incorrect');
    }

    // Hasher le nouveau mot de passe
    const nouveauMotDePasseHash = await this.authService.hasherMotDePasse(
      changePasswordDto.nouveauMotDePasse,
    );

    // Mettre à jour le mot de passe
    await this.prisma.utilisateur.update({
      where: { id: adminId },
      data: { motDePasse: nouveauMotDePasseHash },
    });

    return { message: 'Mot de passe changé avec succès' };
  }

  async changerMotDePasseServeur(
    adminId: string,
    serveurId: string,
    changePasswordDto: ChangeUserPasswordDto,
  ) {
    // Vérifier que le serveur appartient à l'établissement de cet admin
    const etablissementId = await this.obtenirEtablissementId(adminId);

    const serveur = await this.prisma.serveur.findUnique({
      where: { id: serveurId },
      include: { utilisateur: true },
    });

    if (!serveur || serveur.etablissementId !== etablissementId) {
      throw new NotFoundException('Serveur non trouvé');
    }

    // Hasher le nouveau mot de passe
    const nouveauMotDePasseHash = await this.authService.hasherMotDePasse(
      changePasswordDto.nouveauMotDePasse,
    );

    // Mettre à jour le mot de passe
    await this.prisma.utilisateur.update({
      where: { id: serveur.utilisateurId },
      data: { motDePasse: nouveauMotDePasseHash },
    });

    return { message: 'Mot de passe du serveur changé avec succès' };
  }
}
