import { IsString, IsNotEmpty, IsEmail, IsOptional, IsInt, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateEtablissementDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Nom de l\'établissement', example: 'Restaurant Le Gourmet' })
  nom: string;

  
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
