import { IsString, IsNotEmpty, IsArray, IsOptional, ValidateNested, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateItemCommandeDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID du plat', example: 'uuid-plat-123' })
  platId: string;

  @IsNumber()
  @Min(1)
  @IsNotEmpty()
  @ApiProperty({ description: 'Quantité du plat', example: 2, minimum: 1 })
  quantite: number;
}

export class CreateCommandeDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID de la table', example: 'uuid-table-123' })
  tableId: string;

  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID du sous-restaurant', example: 'uuid-sous-restaurant-123' })
  sousRestaurantId: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateItemCommandeDto)
  @IsNotEmpty()
  @ApiProperty({ description: 'Liste des items de la commande', type: [CreateItemCommandeDto] })
  items: CreateItemCommandeDto[];

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Notes additionnelles', example: 'Sans oignons', required: false })
  notes?: string;
}
