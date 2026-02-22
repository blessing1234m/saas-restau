import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ChangePasswordDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Ancien mot de passe', example: 'oldPassword123' })
  ancienMotDePasse: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  @ApiProperty({ description: 'Nouveau mot de passe (minimum 6 caractères)', example: 'newPassword123' })
  nouveauMotDePasse: string;
}

export class ChangeUserPasswordDto {
  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  @ApiProperty({ description: 'Nouveau mot de passe (minimum 6 caractères)', example: 'newPassword123' })
  nouveauMotDePasse: string;
}
