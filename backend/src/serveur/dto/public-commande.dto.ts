import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

export class PublicCommandeItemDto {
  @IsString()
  @IsNotEmpty()
  platId: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  quantite: number;
}

export class CreatePublicCommandeDto {
  @IsString()
  @IsNotEmpty()
  tableId: string;

  @IsString()
  @IsNotEmpty()
  tableToken: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => PublicCommandeItemDto)
  items: PublicCommandeItemDto[];

  @IsString()
  @IsOptional()
  notes?: string;
}
