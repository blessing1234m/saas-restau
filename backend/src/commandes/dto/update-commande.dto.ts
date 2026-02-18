import { IsString, IsOptional, IsEnum, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateCommandeStatusDto {
  @IsEnum(['EN_ATTENTE', 'EN_PREPARATION', 'SERVIE'], {
    message: 'Le statut doit être EN_ATTENTE, EN_PREPARATION ou SERVIE',
  })
  @IsNotEmpty()
  @ApiProperty({ description: 'Statut de la commande', enum: ['EN_ATTENTE', 'EN_PREPARATION', 'SERVIE'], example: 'EN_PREPARATION' })
  statut: 'EN_ATTENTE' | 'EN_PREPARATION' | 'SERVIE';
}

export class UpdateCommandeDto {
  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'Notes additionnelles', example: 'Client absent', required: false })
  notes?: string;
}
