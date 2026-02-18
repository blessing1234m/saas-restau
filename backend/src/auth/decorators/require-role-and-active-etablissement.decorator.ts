import { applyDecorators, UseGuards } from '@nestjs/common';
import { RoleGuard } from '../guards/role.guard';
import { EtablissementActifGuard } from '../guards/etablissement-actif.guard';
import { Roles } from './roles.decorator';

/**
 * Décorateur composé qui applique les deux guards:
 * - RoleGuard: pour vérifier les rôles
 * - EtablissementActifGuard: pour vérifier que l'établissement est actif
 * 
 * Usage:
 * @RequireRoleAndActiveEtablissement('ADMIN_ETABLISSEMENT', 'SERVEUR')
 */
export function RequireRoleAndActiveEtablissement(...roles: string[]) {
  return applyDecorators(
    Roles(...roles),
    UseGuards(RoleGuard, EtablissementActifGuard),
  );
}
