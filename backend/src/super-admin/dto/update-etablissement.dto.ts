import { IsString, IsNotEmpty, IsOptional, IsEmail } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

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
}
