import { IsString, MinLength, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Code agent pour la connexion', example: 'AGENT001' })
  codeAgent: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  @ApiProperty({ description: 'Mot de passe (minimum 6 caractères)', example: 'password123' })
  motDePasse: string;
}
