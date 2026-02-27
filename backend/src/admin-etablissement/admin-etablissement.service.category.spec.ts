import { Test, TestingModule } from '@nestjs/testing';
import { AdminEtablissementService } from './admin-etablissement.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';

describe('AdminEtablissementService - sous-restaurant creation with category rule', () => {
  let service: AdminEtablissementService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const mockPrisma = {
      adminEtablissement: {
        findUnique: jest.fn(),
      },
      etablissement: {
        findUnique: jest.fn(),
      },
      sousRestaurant: {
        findFirst: jest.fn(),
        create: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminEtablissementService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<AdminEtablissementService>(AdminEtablissementService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should forbid creation when establishment category is SIMPLE', async () => {
    (prisma.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
      id: 'admin-1',
      utilisateurId: 'user1',
      etablissementId: 'etab-1',
    });
    (prisma.etablissement.findUnique as jest.Mock).mockResolvedValue({
      id: 'etab-1',
      categorie: 'SIMPLE',
    });

    await expect(
      service.creerSousRestaurant('user1', { nom: 'SR1' } as any),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should create sous-restaurant when category is PRIVILEGE and name is unique', async () => {
    (prisma.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
      id: 'admin-1',
      utilisateurId: 'user1',
      etablissementId: 'etab-1',
    });
    (prisma.etablissement.findUnique as jest.Mock).mockResolvedValue({
      id: 'etab-1',
      categorie: 'PRIVILEGE',
    });
    (prisma.sousRestaurant.findFirst as jest.Mock).mockResolvedValue(null);
    const mockResult = { id: 'sr-1', nom: 'SR1', etablissementId: 'etab-1' };
    (prisma.sousRestaurant.create as jest.Mock).mockResolvedValue(mockResult);

    const result = await service.creerSousRestaurant('user1', { nom: 'SR1' } as any);
    expect(result).toEqual(mockResult);
    expect(prisma.sousRestaurant.create).toHaveBeenCalledWith({
      data: {
        nom: 'SR1',
        description: undefined,
        etablissementId: 'etab-1',
      },
    });
  });

  it('should throw BadRequestException when a sous-restaurant with same name exists', async () => {
    (prisma.adminEtablissement.findUnique as jest.Mock).mockResolvedValue({
      id: 'admin-1',
      utilisateurId: 'user1',
      etablissementId: 'etab-1',
    });
    (prisma.etablissement.findUnique as jest.Mock).mockResolvedValue({
      id: 'etab-1',
      categorie: 'PRIVILEGE',
    });
    (prisma.sousRestaurant.findFirst as jest.Mock).mockResolvedValue({
      id: 'already',
    });

    await expect(
      service.creerSousRestaurant('user1', { nom: 'dup' } as any),
    ).rejects.toThrow(BadRequestException);
  });
});
