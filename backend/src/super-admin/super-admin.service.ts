import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { CreateEtablissementDto } from './dto/create-etablissement.dto';
import { UpdateEtablissementDto } from './dto/update-etablissement.dto';
import { CreateAdminEtablissementDto } from './dto/create-admin-etablissement.dto';
import { UpdateAdminEtablissementDto } from './dto/update-admin-etablissement.dto';
import { ChangePasswordDto } from '../auth/dto/change-password.dto';

@Injectable()
export class SuperAdminService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
  ) {}

  // ÉTABLISSEMENTS 

  async creerEtablissement(createEtablissementDto: CreateEtablissementDto) {
    return this.prisma.etablissement.create({
      data: {
        nom: createEtablissementDto.nom,
        ville: createEtablissementDto.ville,
        telephone: createEtablissementDto.telephone,
        email: createEtablissementDto.email,
      },
    });
  }

  async obtenirTousLesEtablissements() {
    return this.prisma.etablissement.findMany({
      include: {
        adminEtablissements: {
          include: {
            utilisateur: {
              select: {
                id: true,
                codeAgent: true,
                role: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async obtenirEtablissement(id: string) {
    const etablissement = await this.prisma.etablissement.findUnique({
      where: { id },
      include: {
        adminEtablissements: {
          include: {
            utilisateur: {
              select: {
                id: true,
                codeAgent: true,
                role: true,
              },
            },
          },
        },
        sousRestaurants: true,
        serveurs: {
          include: {
            utilisateur: {
              select: {
                id: true,
                codeAgent: true,
                role: true,
              },
            },
          },
        },
      },
    });

    if (!etablissement) {
      throw new NotFoundException(`Établissement avec l'ID ${id} non trouvé`);
    }

    return etablissement;
  }

  async mettreAJourEtablissement(
    id: string,
    updateEtablissementDto: UpdateEtablissementDto,
  ) {
    const etablissement = await this.prisma.etablissement.findUnique({
      where: { id },
    });

    if (!etablissement) {
      throw new NotFoundException(`Établissement avec l'ID ${id} non trouvé`);
    }

    return this.prisma.etablissement.update({
      where: { id },
      data: updateEtablissementDto,
    });
  }

  async supprimerEtablissement(id: string) {
    const etablissement = await this.prisma.etablissement.findUnique({
      where: { id },
    });

    if (!etablissement) {
      throw new NotFoundException(`Établissement avec l'ID ${id} non trouvé`);
    }

    await this.prisma.etablissement.delete({
      where: { id },
    });

    return { message: `Établissement "${etablissement.nom}" a été supprimé avec succès` };
  }

  async basculerEtatEtablissement(id: string) {
    const etablissement = await this.prisma.etablissement.findUnique({
      where: { id },
    });

    if (!etablissement) {
      throw new NotFoundException(`Établissement avec l'ID ${id} non trouvé`);
    }

    return this.prisma.etablissement.update({
      where: { id },
      data: { estActif: !etablissement.estActif },
    });
  }

  // ADMINS D'ÉTABLISSEMENT 

  async creerAdminEtablissement(
    createAdminDto: CreateAdminEtablissementDto,
  ) {
    console.log('🔐 CREATING ADMIN:', createAdminDto);
    
    // Vérifier que le code agent est unique
    const utilisateurExistant = await this.prisma.utilisateur.findUnique({
      where: { codeAgent: createAdminDto.codeAgent },
    });

    if (utilisateurExistant) {
      console.log('Code agent déjà utilisé');
      throw new BadRequestException(
        'Ce code agent est déjà utilisé',
      );
    }

    // Vérifier que l'établissement existe
    const etablissement = await this.prisma.etablissement.findUnique({
      where: { id: createAdminDto.etablissementId },
    });

    if (!etablissement) {
      console.log('❌ Établissement non trouvé:', createAdminDto.etablissementId);
      throw new NotFoundException(
        `Établissement avec l'ID ${createAdminDto.etablissementId} non trouvé`,
      );
    }

    // Créer l'utilisateur
    const utilisateur = await this.authService.creerUtilisateur(
      createAdminDto.codeAgent,
      createAdminDto.motDePasse,
      'ADMIN_ETABLISSEMENT',
    );
    
    console.log('✅ Utilisateur créé:', utilisateur.id);

    // Créer l'admin d'établissement
    const adminEtablissement = await this.prisma.adminEtablissement.create({
      data: {
        utilisateurId: utilisateur.id,
        etablissementId: createAdminDto.etablissementId,
      },
      include: {
        utilisateur: {
          select: {
            id: true,
            codeAgent: true,
            role: true,
          },
        },
        etablissement: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    return adminEtablissement;
  }

  async obtenirTousLesAdminsEtablissement() {
    return this.prisma.adminEtablissement.findMany({
      include: {
        utilisateur: {
          select: {
            id: true,
            codeAgent: true,
            role: true,
            estActif: true,
          },
        },
        etablissement: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async obtenirAdminEtablissement(id: string) {
    const adminEtablissement = await this.prisma.adminEtablissement.findUnique(
      {
        where: { id },
        include: {
          utilisateur: {
            select: {
              id: true,
              codeAgent: true,
              role: true,
              estActif: true,
            },
          },
          etablissement: true,
        },
      },
    );

    if (!adminEtablissement) {
      throw new NotFoundException(`Admin d'établissement avec l'ID ${id} non trouvé`);
    }

    return adminEtablissement;
  }

  async mettreAJourAdminEtablissement(
    adminId: string,
    updateAdminDto: UpdateAdminEtablissementDto,
  ) {
    // Vérifier que l'admin existe
    const adminEtablissement = await this.prisma.adminEtablissement.findUnique(
      {
        where: { id: adminId },
        include: { utilisateur: true, etablissement: true },
      },
    );

    if (!adminEtablissement) {
      throw new NotFoundException(`Admin d'établissement avec l'ID ${adminId} non trouvé`);
    }

    // Vérifier que le nouvel établissement existe si on le change
    if (updateAdminDto.etablissementId !== adminEtablissement.etablissementId) {
      const nouvelEtablissement = await this.prisma.etablissement.findUnique({
        where: { id: updateAdminDto.etablissementId },
      });

      if (!nouvelEtablissement) {
        throw new NotFoundException(
          `Établissement avec l'ID ${updateAdminDto.etablissementId} non trouvé`,
        );
      }
    }

    // Vérifier que le code agent n'est pas déjà utilisé par un autre utilisateur
    if (updateAdminDto.codeAgent !== adminEtablissement.utilisateur.codeAgent) {
      const utilisateurExistant = await this.prisma.utilisateur.findUnique({
        where: { codeAgent: updateAdminDto.codeAgent },
      });

      if (utilisateurExistant) {
        throw new BadRequestException(
          'Ce code agent est déjà utilisé',
        );
      }
    }

    // Mettre à jour l'utilisateur
    const utilisateur = await this.prisma.utilisateur.update({
      where: { id: adminEtablissement.utilisateurId },
      data: {
        codeAgent: updateAdminDto.codeAgent,
        motDePasse: await this.authService.hasherMotDePasse(updateAdminDto.motDePasse),
      },
      select: {
        id: true,
        codeAgent: true,
        role: true,
        estActif: true,
      },
    });

    // Mettre à jour l'admin d'établissement
    const adminMisAJour = await this.prisma.adminEtablissement.update({
      where: { id: adminId },
      data: {
        etablissementId: updateAdminDto.etablissementId,
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
        etablissement: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    return adminMisAJour;
  }

  async basculerEtatAdminEtablissement(adminId: string) {
    const adminEtablissement = await this.prisma.adminEtablissement.findUnique(
      {
        where: { id: adminId },
        include: { utilisateur: true },
      },
    );

    if (!adminEtablissement) {
      throw new NotFoundException(`Admin d'établissement avec l'ID ${adminId} non trouvé`);
    }

    const utilisateur = await this.prisma.utilisateur.update({
      where: { id: adminEtablissement.utilisateurId },
      data: { estActif: !adminEtablissement.utilisateur.estActif },
      select: {
        id: true,
        codeAgent: true,
        role: true,
        estActif: true,
      },
    });

    return utilisateur;
  }

  async supprimerAdminEtablissement(adminId: string) {
    const adminEtablissement = await this.prisma.adminEtablissement.findUnique(
      {
        where: { id: adminId },
        include: { utilisateur: true },
      },
    );

    if (!adminEtablissement) {
      throw new NotFoundException(`Admin d'établissement avec l'ID ${adminId} non trouvé`);
    }

    // Supprimer d'abord l'AdminEtablissement
    await this.prisma.adminEtablissement.delete({
      where: { id: adminId },
    });

    // Puis supprimer l'Utilisateur
    await this.prisma.utilisateur.delete({
      where: { id: adminEtablissement.utilisateurId },
    });

    return { message: 'Admin d\'établissement supprimé avec succès' };
  }

  // GESTION DES MOTS DE PASSE

  async changerMotDePasseSuperAdmin(
    superAdminId: string,
    changePasswordDto: ChangePasswordDto,
  ) {
    // Récupérer le superAdmin
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { id: superAdminId },
    });

    if (!utilisateur) {
      throw new NotFoundException('SuperAdmin non trouvé');
    }

    // Vérifier que le rôle est bien SUPER_ADMIN
    if (utilisateur.role !== 'SUPER_ADMIN') {
      throw new BadRequestException('Cet utilisateur n\'est pas un SuperAdmin');
    }

    // Vérifier l'ancien mot de passe
    const estValide = await this.authService.verifierMotDePasse(
      changePasswordDto.ancienMotDePasse,
      utilisateur.motDePasse,
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
      where: { id: superAdminId },
      data: { motDePasse: nouveauMotDePasseHash },
    });

    return { message: 'Mot de passe changé avec succès' };
  }
}
