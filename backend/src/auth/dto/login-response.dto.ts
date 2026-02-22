import { ApiProperty } from '@nestjs/swagger';

export class LoginResponseDto {
  @ApiProperty({ description: 'Token JWT pour l\'authentification', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' })
  accessToken: string;

  @ApiProperty({ description: 'ID de l\'utilisateur', example: 'uuid-123' })
  utilisateurId: string;

  @ApiProperty({ description: 'Code agent', example: 'AGENT001' })
  codeAgent: string;

  @ApiProperty({ description: 'Rôle de l\'utilisateur', example: 'ADMIN_ETABLISSEMENT' })
  role: string;

  @ApiProperty({ description: 'Statut de l\'utilisateur', example: true })
  estActif?: boolean;

  @ApiProperty({ description: 'ID de l\'établissement assigné', example: 'uuid-etab', required: false })
  etablissementId?: string;

  @ApiProperty({ description: 'Nom de l\'établissement assigné', example: 'Restaurant Principal', required: false })
  etablissementName?: string;
}
