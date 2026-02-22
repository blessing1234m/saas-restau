import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateServeurDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Code agent du serveur', example: 'SERVEUR001' })
  codeAgent: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Mot de passe du serveur', example: 'password123' })
  motDePasse: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID du sous-restaurant assigné (obligatoire)', example: 'clx...' })
  sousRestaurantId: string;
}

export class UpdateServeurDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'ID du sous-restaurant (optionnel)', example: 'clx...', required: false })
  sousRestaurantId?: string;
}

export class UpdateServeurCompletDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Nouveau code agent', example: 'SERVEUR002' })
  codeAgent: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID du sous-restaurant', example: 'clx...' })
  sousRestaurantId: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Ancien mot de passe (si changement)', example: 'oldPassword123', required: false })
  ancienMotDePasse?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Nouveau mot de passe (si changement)', example: 'newPassword123', required: false })
  nouveauMotDePasse?: string;
}
