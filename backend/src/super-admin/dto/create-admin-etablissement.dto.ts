import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateAdminEtablissementDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Code agent de l\'administrateur', example: 'A1B1' })
  codeAgent: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  @ApiProperty({ description: 'Mot de passe (minimum 6 caractères)', example: 'password123' })
  motDePasse: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID de l\'établissement', example: 'uuid-etablissement-123' })
  etablissementId: string;
}
