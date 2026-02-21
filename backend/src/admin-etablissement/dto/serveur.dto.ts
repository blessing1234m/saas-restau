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
