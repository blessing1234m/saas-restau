import { Test, TestingModule } from '@nestjs/testing';
import { SuperAdminService } from './super-admin.service';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ChangePasswordDto } from '../auth/dto/change-password.dto';
import { Role } from '@prisma/client';

describe('SuperAdminService - Password Management', () => {
  let service: SuperAdminService;
  let authService: AuthService;
  let prismaService: PrismaService;

  const mockUtilisateur = {
    id: 'super-admin-1',
    codeAgent: 'SA001',
    motDePasse: 'hashedPassword',
    role: Role.SUPER_ADMIN,
    estActif: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const mockPrismaService = {
      utilisateur: {
        findUnique: jest.fn(),
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
        SuperAdminService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuthService, useValue: mockAuthService },
      ],
    }).compile();

    service = module.get<SuperAdminService>(SuperAdminService);
    authService = module.get<AuthService>(AuthService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  describe('changerMotDePasseSuperAdmin', () => {
    it('devrait changer le mot de passe avec succès', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'oldPassword123',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.utilisateur.findUnique as jest.Mock).mockResolvedValue(
        mockUtilisateur,
      );
      (authService.verifierMotDePasse as jest.Mock).mockResolvedValue(true);
      (authService.hasherMotDePasse as jest.Mock).mockResolvedValue(
        'newHashedPassword',
      );
      (prismaService.utilisateur.update as jest.Mock).mockResolvedValue({
        ...mockUtilisateur,
        motDePasse: 'newHashedPassword',
      });

      const result = await service.changerMotDePasseSuperAdmin(
        'super-admin-1',
        changePasswordDto,
      );

      expect(result).toEqual({
        message: 'Mot de passe changé avec succès',
      });
      expect(prismaService.utilisateur.update).toHaveBeenCalledWith({
        where: { id: 'super-admin-1' },
        data: { motDePasse: 'newHashedPassword' },
      });
    });

    it('devrait lancer une erreur si l\'utilisateur n\'existe pas', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'oldPassword123',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.utilisateur.findUnique as jest.Mock).mockResolvedValue(
        null,
      );

      await expect(
        service.changerMotDePasseSuperAdmin('non-existant', changePasswordDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('devrait lancer une erreur si l\'ancien mot de passe est incorrect', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'wrongPassword',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.utilisateur.findUnique as jest.Mock).mockResolvedValue(
        mockUtilisateur,
      );
      (authService.verifierMotDePasse as jest.Mock).mockResolvedValue(false);

      await expect(
        service.changerMotDePasseSuperAdmin('super-admin-1', changePasswordDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('devrait lancer une erreur si ce n\'est pas un SUPER_ADMIN', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'oldPassword123',
        nouveauMotDePasse: 'newPassword123',
      };

      const adminUtilisateur = {
        ...mockUtilisateur,
        role: Role.ADMIN_ETABLISSEMENT,
      };

      (prismaService.utilisateur.findUnique as jest.Mock).mockResolvedValue(
        adminUtilisateur,
      );

      await expect(
        service.changerMotDePasseSuperAdmin('admin-1', changePasswordDto),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
