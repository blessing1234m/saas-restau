import { IsString, IsNumber, IsNotEmpty, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateItemCommandeItemDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'ID du plat', example: 'uuid-plat-123' })
  platId: string;

  @IsNumber()
  @Min(1)
  @IsNotEmpty()
  @ApiProperty({ description: 'Quantité du plat', example: 1, minimum: 1 })
  quantite: number;
}
