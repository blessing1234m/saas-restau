import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { LoginResponseDto } from './dto/login-response.dto';

@Injectable()
export class AuthenticationService {
  constructor(
    private authService: AuthService,
    private prisma: PrismaService,
  ) {}

  async login(loginDto: LoginDto): Promise<LoginResponseDto> {
    console.log('LOGIN REQUEST RECEIVED for code agent:', loginDto.codeAgent);
    
    const utilisateur = await this.authService.validerUtilisateur(
      loginDto.codeAgent,
      loginDto.motDePasse,
    );

    console.log('Utilisateur trouvé:', utilisateur ? utilisateur.codeAgent : 'NON');

    if (!utilisateur) {
      throw new UnauthorizedException(
        'Code agent ou mot de passe incorrect',
      );
    }

    const accessToken = await this.authService.creerToken(utilisateur);

    // Build response with optional establishment info
    const response: LoginResponseDto = {
      accessToken,
      utilisateurId: utilisateur.id,
      codeAgent: utilisateur.codeAgent,
      role: utilisateur.role,
      estActif: utilisateur.estActif,
    };

    // Add establishment info if user is AdminEtablissement
    if (utilisateur.role === 'ADMIN_ETABLISSEMENT') {
      const adminEtab = await this.prisma.adminEtablissement.findUnique({
        where: { utilisateurId: utilisateur.id },
        include: { etablissement: true },
      });

      if (adminEtab && adminEtab.etablissement) {
        response.etablissementId = adminEtab.etablissementId;
        response.etablissementName = adminEtab.etablissement.nom;
        console.log('[LOGIN] AdminEtab établissement:', {
          id: adminEtab.etablissementId,
          nom: adminEtab.etablissement.nom,
        });
      } else {
        console.log('[LOGIN] AdminEtab found but no établissement:', adminEtab);
      }
    }

    console.log('[LOGIN] Final response:', response);
    return response;
  }
}

