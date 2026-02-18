import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class EtablissementActifGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Utilisateur non authentifié');
    }

    // Le SUPER_ADMIN n'est pas lié à un établissement spécifique
    if (user.role === 'SUPER_ADMIN') {
      return true;
    }

    // Pour ADMIN_ETABLISSEMENT et SERVEUR, vérifier l'établissement
    if (user.role === 'ADMIN_ETABLISSEMENT') {
      const adminEtablissement = await this.prisma.adminEtablissement.findUnique({
        where: { utilisateurId: user.utilisateurId },
        include: { etablissement: true },
      });

      if (!adminEtablissement) {
        throw new ForbiddenException('Établissement introuvable');
      }

      if (!adminEtablissement.etablissement.estActif) {
        throw new ForbiddenException(
          'Cet établissement est désactivé et n\'est plus accessible',
        );
      }

      // Ajouter l'établissementId au request pour utilisation dans les contrôleurs
      request.etablissementId = adminEtablissement.etablissementId;

      return true;
    }

    if (user.role === 'SERVEUR') {
      const serveur = await this.prisma.serveur.findUnique({
        where: { utilisateurId: user.utilisateurId },
        include: { etablissement: true },
      });

      if (!serveur) {
        throw new ForbiddenException('Serveur introuvable');
      }

      if (!serveur.etablissement.estActif) {
        throw new ForbiddenException(
          'Cet établissement est désactivé et n\'est plus accessible',
        );
      }

      // Ajouter l'établissementId et le serveurId au request
      request.etablissementId = serveur.etablissementId;
      request.serveurId = serveur.id;

      return true;
    }

    return true;
  }
}
