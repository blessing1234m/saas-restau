import { IsString, IsNotEmpty, IsOptional, IsEmail, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

// local enum duplicata de celui défini dans Prisma
export enum CategorieEtablissement {
  SIMPLE = 'SIMPLE',
  PRIVILEGE = 'PRIVILEGE',
}

export class UpdateEtablissementDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Nom de l\'établissement', example: 'Restaurant Le Gourmet', required: false })
  nom?: string;



  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Ville où se trouve l\'établissement', example: 'Paris', required: false })
  ville?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Numéro de téléphone', example: '+33123456789', required: false })
  telephone?: string;

  @IsEmail()
  @IsOptional()
  @ApiProperty({ description: 'Adresse email', example: 'contact@restaurant.com', required: false })
  email?: string;

  @IsEnum(CategorieEtablissement)
  @IsOptional()
  @ApiProperty({
    description: 'Catégorie de l\'établissement',
    enum: CategorieEtablissement,
    required: false,
  })
  categorie?: CategorieEtablissement;
}
