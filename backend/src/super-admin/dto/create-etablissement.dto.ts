import { IsString, IsNotEmpty, IsEmail, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

// on redéfinit localement pour éviter d'attendre la génération Prisma
export enum CategorieEtablissement {
  SIMPLE = 'SIMPLE',
  PRIVILEGE = 'PRIVILEGE',
}

export class CreateEtablissementDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Nom de l\'établissement', example: 'Restaurant Le Gourmet' })
  nom: string;

  @IsEnum(CategorieEtablissement)
  @ApiProperty({
    description: 'Catégorie de l\'établissement (affecte les droits des admins)',
    enum: CategorieEtablissement,
    example: CategorieEtablissement.SIMPLE,
  })
  categorie: CategorieEtablissement;

  
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Ville où se trouve l\'établissement', example: 'Paris' })
  ville: string;


  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Numéro de téléphone', example: '+33123456789', required: false })
  telephone?: string;

  @IsEmail()
  @IsOptional()
  @ApiProperty({ description: 'Adresse email', example: 'contact@restaurant.com', required: false })
  email?: string;
}
