import { Test, TestingModule } from '@nestjs/testing';
import { AdminEtablissementService } from './admin-etablissement.service';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import {
  ChangePasswordDto,
  ChangeUserPasswordDto,
} from '../auth/dto/change-password.dto';
import { Role } from '@prisma/client';

describe('AdminEtablissementService - Password Management', () => {
  let service: AdminEtablissementService;
  let authService: AuthService;
  let prismaService: PrismaService;

  const mockAdminUtilisateur = {
    id: 'admin-1',
    codeAgent: 'A001',
    motDePasse: 'hashedPassword',
    role: Role.ADMIN_ETABLISSEMENT,
    estActif: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockServeurUtilisateur = {
    id: 'serveur-1',
    codeAgent: 'S001',
    motDePasse: 'hashedPassword',
    role: Role.SERVEUR,
    estActif: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const mockPrismaService = {
      adminEtablissement: {
        findUnique: jest.fn(),
      },
      serveur: {
        findUnique: jest.fn(),
      },
      utilisateur: {
        update: jest.fn(),
      },
    };

    const mockAuthService = {
      hasherMotDePasse: jest.fn(),
      verifierMotDePasse: jest.fn(),
      creerUtilisateur: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminEtablissementService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuthService, useValue: mockAuthService },
      ],
    }).compile();

    service = module.get<AdminEtablissementService>(
      AdminEtablissementService,
    );
    authService = module.get<AuthService>(AuthService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  describe('changerMotDePasseAdminEtablissement', () => {
    it('devrait changer le mot de passe de l\'admin avec succès', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'oldPassword123',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
        id: 'admin-etab-1',
        utilisateurId: 'admin-1',
        etablissementId: 'etab-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        utilisateur: mockAdminUtilisateur,
      });

      (authService.verifierMotDePasse as jest.Mock).mockResolvedValue(true);
      (authService.hasherMotDePasse as jest.Mock).mockResolvedValue(
        'newHashedPassword',
      );
      (prismaService.utilisateur.update as jest.Mock).mockResolvedValue({
        ...mockAdminUtilisateur,
        motDePasse: 'newHashedPassword',
      });

      const result = await service.changerMotDePasseAdminEtablissement(
        'admin-1',
        changePasswordDto,
      );

      expect(result).toEqual({
        message: 'Mot de passe changé avec succès',
      });
    });

    it('devrait lancer une erreur si l\'ancien mot de passe est incorrect', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'wrongPassword',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
        id: 'admin-etab-1',
        utilisateurId: 'admin-1',
        etablissementId: 'etab-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        utilisateur: mockAdminUtilisateur,
      });

      (authService.verifierMotDePasse as jest.Mock).mockResolvedValue(false);

      await expect(
        service.changerMotDePasseAdminEtablissement('admin-1', changePasswordDto),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('changerMotDePasseServeur', () => {
    it('devrait changer le mot de passe du serveur avec succès', async () => {
      const changePasswordDto: ChangeUserPasswordDto = {
        nouveauMotDePasse: 'newServerPassword123',
      };

      (prismaService.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
        id: 'admin-etab-1',
        utilisateurId: 'admin-1',
        etablissementId: 'etab-1',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      (prismaService.serveur.findUnique as jest.Mock).mockResolvedValue({
        id: 'serveur-1',
        utilisateurId: 'serveur-1',
        etablissementId: 'etab-1',
        sousRestaurantId: 'sr-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        utilisateur: mockServeurUtilisateur,
      });

      (authService.hasherMotDePasse as jest.Mock).mockResolvedValue(
        'newHashedServerPassword',
      );
      (prismaService.utilisateur.update as jest.Mock).mockResolvedValue({
        ...mockServeurUtilisateur,
        motDePasse: 'newHashedServerPassword',
      });

      const result = await service.changerMotDePasseServeur(
        'admin-1',
        'serveur-1',
        changePasswordDto,
      );

      expect(result).toEqual({
        message: 'Mot de passe du serveur changé avec succès',
      });
    });

    it('devrait lancer une erreur si le serveur n\'appartient pas à cet établissement', async () => {
      const changePasswordDto: ChangeUserPasswordDto = {
        nouveauMotDePasse: 'newServerPassword123',
      };

      (prismaService.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
        id: 'admin-etab-1',
        utilisateurId: 'admin-1',
        etablissementId: 'etab-1',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      (prismaService.serveur.findUnique as jest.Mock).mockResolvedValue({
        id: 'serveur-1',
        utilisateurId: 'serveur-1',
        etablissementId: 'other-etab',
        sousRestaurantId: 'sr-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        utilisateur: mockServeurUtilisateur,
      });

      await expect(
        service.changerMotDePasseServeur(
          'admin-1',
          'serveur-1',
          changePasswordDto,
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('devrait lancer une erreur si le serveur n\'existe pas', async () => {
      const changePasswordDto: ChangeUserPasswordDto = {
        nouveauMotDePasse: 'newServerPassword123',
      };

      (prismaService.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
        id: 'admin-etab-1',
        utilisateurId: 'admin-1',
        etablissementId: 'etab-1',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      (prismaService.serveur.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(
        service.changerMotDePasseServeur(
          'admin-1',
          'non-existant',
          changePasswordDto,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
