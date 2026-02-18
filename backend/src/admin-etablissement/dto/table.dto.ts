import { IsString, IsNotEmpty, IsOptional, IsInt, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTableDto {
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  @ApiProperty({ description: 'Numéro de la table', example: 1, minimum: 1 })
  numero: number;

  // @IsInt()
  // @Min(1)
  // @IsNotEmpty()
  // capacite: number;
}

export class UpdateTableDto {
  @IsInt()
  @Min(1)
  @IsOptional()
  @ApiProperty({ description: 'Numéro de la table', example: 1, minimum: 1, required: false })
  numero?: number;

  // @IsInt()
  // @Min(1)
  // @IsOptional()
  // capacite?: number;
}
