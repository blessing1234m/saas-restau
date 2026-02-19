import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { LoginResponseDto } from './dto/login-response.dto';

@Injectable()
export class AuthenticationService {
  constructor(private authService: AuthService) {}

  async login(loginDto: LoginDto): Promise<LoginResponseDto> {
    console.log('LOGIN REQUEST RECEIVED');
    console.log('Body:', JSON.stringify(loginDto));
    console.log('Code Agent:', loginDto.codeAgent);
    console.log('Mot de passe:', loginDto.motDePasse);
    
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

    return {
      accessToken,
      utilisateurId: utilisateur.id,
      codeAgent: utilisateur.codeAgent,
      role: utilisateur.role,
    };
  }
}
