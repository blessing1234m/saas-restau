import { IsEmail, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateMonEtablissementDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: "Nom de l'établissement", required: false })
  nom?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: "Ville de l'établissement", required: false })
  ville?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: "Téléphone de l'établissement", required: false })
  telephone?: string;

  @IsEmail()
  @IsOptional()
  @ApiProperty({ description: "Email de l'établissement", required: false })
  email?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({
    description: 'Logo en base64 (data URI ou base64 brut). Envoyer une chaîne vide pour supprimer.',
    required: false,
  })
  logoAffichage?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({
    description: 'Bannière en base64 (data URI ou base64 brut). Envoyer une chaîne vide pour supprimer.',
    required: false,
  })
  banniereAffichage?: string;
}
