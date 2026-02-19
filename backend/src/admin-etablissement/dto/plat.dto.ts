import { IsString, IsNotEmpty, IsOptional, IsNumber, Min, IsArray, ArrayMaxSize } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePlatDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty({ description: 'Nom du plat', example: 'Couscous Royal' })
  nom: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Description du plat', example: 'Couscous servi avec merguez et poulet', required: false })
  description?: string;

  @IsNumber()
  @Min(0.01)
  @IsNotEmpty()
  @ApiProperty({ description: 'Prix du plat', example: 15.99, minimum: 0.01 })
  prix: number;

  @IsArray()
  @ArrayMaxSize(3, { message: 'Maximum 3 images autorisées' })
  @IsOptional()
  @ApiProperty({ 
    description: 'Images du plat en base64 (maximum 3)', 
    example: ['data:image/jpeg;base64,/9j/4AAQSkZJRg...', 'data:image/jpeg;base64,...'],
    maxItems: 3,
    required: false 
  })
  images?: string[];
}

export class UpdatePlatDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Nom du plat', example: 'Couscous Royal', required: false })
  nom?: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Description du plat', example: 'Couscous servi avec merguez et poulet', required: false })
  description?: string;

  @IsNumber()
  @Min(0.01)
  @IsOptional()
  @ApiProperty({ description: 'Prix du plat', example: 15.99, minimum: 0.01, required: false })
  prix?: number;
}
