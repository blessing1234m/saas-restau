import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateCategorieDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Nom de la catégorie', example: 'Plats principaux' })
  nom: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Description de la catégorie', example: 'Les meilleurs plats de notre restaurant', required: false })
  description?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Photo d\'affichage en base64', example: 'data:image/jpeg;base64,/9j/4AAQSkZJRg...', required: false })
  photoAffichage?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Ordre d\'affichage', example: '1', required: false })
  ordre?: number;
}

export class UpdateCategorieDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Nom de la catégorie', example: 'Plats principaux', required: false })
  nom?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Description de la catégorie', example: 'Les meilleurs plats de notre restaurant', required: false })
  description?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Photo d\'affichage en base64', example: 'data:image/jpeg;base64,/9j/4AAQSkZJRg...', required: false })
  photoAffichage?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Ordre d\'affichage', example: '1', required: false })
  ordre?: number;
}
