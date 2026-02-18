import { IsString, IsNotEmpty, IsOptional, IsInt, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSousRestaurantDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Nom du sous-restaurant', example: 'Terrasse' })
  nom: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Description du sous-restaurant', example: 'Espace en plein air', required: false })
  description?: string;
}

export class UpdateSousRestaurantDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Nom du sous-restaurant', example: 'Terrasse', required: false })
  nom?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Description du sous-restaurant', example: 'Espace en plein air', required: false })
  description?: string;
}
