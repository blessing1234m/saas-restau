import { Test, TestingModule } from '@nestjs/testing';
import { ServeurService } from './serveur.service';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ChangePasswordDto } from '../auth/dto/change-password.dto';
import { Role } from '@prisma/client';

describe('ServeurService - Password Management', () => {
  let service: ServeurService;
  let authService: AuthService;
  let prismaService: PrismaService;

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
        ServeurService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuthService, useValue: mockAuthService },
      ],
    }).compile();

    service = module.get<ServeurService>(ServeurService);
    authService = module.get<AuthService>(AuthService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  describe('changerMotDePasseServeur', () => {
    it('devrait changer le mot de passe du serveur avec succès', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'oldPassword123',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.serveur.findUnique as jest.Mock).mockResolvedValue({
        id: 'serveur-1',
        utilisateurId: 'serveur-1',
        etablissementId: 'etab-1',
        sousRestaurantId: 'sr-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        utilisateur: mockServeurUtilisateur,
      });

      (authService.verifierMotDePasse as jest.Mock).mockResolvedValue(true);
      (authService.hasherMotDePasse as jest.Mock).mockResolvedValue(
        'newHashedPassword',
      );
      (prismaService.utilisateur.update as jest.Mock).mockResolvedValue({
        ...mockServeurUtilisateur,
        motDePasse: 'newHashedPassword',
      });

      const result = await service.changerMotDePasseServeur(
        'serveur-1',
        changePasswordDto,
      );

      expect(result).toEqual({
        message: 'Mot de passe changé avec succès',
      });
      expect(prismaService.utilisateur.update).toHaveBeenCalledWith({
        where: { id: 'serveur-1' },
        data: { motDePasse: 'newHashedPassword' },
      });
    });

    it('devrait lancer une erreur si le serveur n\'existe pas', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'oldPassword123',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.serveur.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(
        service.changerMotDePasseServeur('non-existant', changePasswordDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('devrait lancer une erreur si l\'ancien mot de passe est incorrect', async () => {
      const changePasswordDto: ChangePasswordDto = {
        ancienMotDePasse: 'wrongPassword',
        nouveauMotDePasse: 'newPassword123',
      };

      (prismaService.serveur.findUnique as jest.Mock).mockResolvedValue({
        id: 'serveur-1',
        utilisateurId: 'serveur-1',
        etablissementId: 'etab-1',
        sousRestaurantId: 'sr-1',
        createdAt: new Date(),
        updatedAt: new Date(),
        utilisateur: mockServeurUtilisateur,
      });

      (authService.verifierMotDePasse as jest.Mock).mockResolvedValue(false);

      await expect(
        service.changerMotDePasseServeur('serveur-1', changePasswordDto),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('genererMenuPublicHtml', () => {
    it('intègre toutes les images du plat dans le HTML', async () => {
      // préparer un menu avec un plat qui a deux images
      const sampleMenu = {
        etablissement: { nom: 'TestEtab' },
        nom: 'TestMenu',
        categories: [
          {
            nom: 'Entrées',
            description: null,
            plats: [
              {
                nom: 'Salade Multiphoto',
                description: 'Une salade avec plusieurs vues',
                prix: 5.5,
                images: [
                  { donnees: 'data:image/jpeg;base64,AAA' },
                  { donnees: 'data:image/jpeg;base64,BBB' },
                ],
              },
            ],
          },
        ],
      } as any;

      jest
        .spyOn(service, 'obtenirMenuPublic')
        .mockResolvedValue(sampleMenu as any);

      const html = await service.genererMenuPublicHtml('sr-123');

      // on attend deux balises <img> correspondant aux deux photos
      expect(html.match(/<img[^>]+src="data:image\/jpeg;base64,AAA"/)).toBeTruthy();
      expect(html.match(/<img[^>]+src="data:image\/jpeg;base64,BBB"/)).toBeTruthy();

      // la structure de conteneur pour multi‑images doit être présente
      expect(html).toContain('class="plat-images"');
    });
  });
});
