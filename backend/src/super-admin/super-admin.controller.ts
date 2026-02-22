import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
  Patch,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SuperAdminService } from './super-admin.service';
import { CreateEtablissementDto } from './dto/create-etablissement.dto';
import { UpdateEtablissementDto } from './dto/update-etablissement.dto';
import { CreateAdminEtablissementDto } from './dto/create-admin-etablissement.dto';
import { UpdateAdminEtablissementDto } from './dto/update-admin-etablissement.dto';
import { RoleGuard } from '../auth/guards/role.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UtilisateurActuel } from '../auth/decorators/utilisateur-actuel.decorator';
import { ChangePasswordDto } from '../auth/dto/change-password.dto';

@Controller('super-admin')
@UseGuards(AuthGuard('jwt'), RoleGuard)
export class SuperAdminController {
  constructor(private superAdminService: SuperAdminService) {}

  // ========== ÉTABLISSEMENTS ==========

  @Post('etablissements')
  @Roles('SUPER_ADMIN')
  async creerEtablissement(@Body() createEtablissementDto: CreateEtablissementDto) {
    return this.superAdminService.creerEtablissement(createEtablissementDto);
  }

  @Get('etablissements')
  @Roles('SUPER_ADMIN')
  async obtenirTousLesEtablissements() {
    return this.superAdminService.obtenirTousLesEtablissements();
  }

  @Get('etablissements/:id')
  @Roles('SUPER_ADMIN')
  async obtenirEtablissement(@Param('id') id: string) {
    return this.superAdminService.obtenirEtablissement(id);
  }

  @Put('etablissements/:id')
  @Roles('SUPER_ADMIN')
  async mettreAJourEtablissement(
    @Param('id') id: string,
    @Body() updateEtablissementDto: UpdateEtablissementDto,
  ) {
    return this.superAdminService.mettreAJourEtablissement(
      id,
      updateEtablissementDto,
    );
  }

  @Delete('etablissements/:id')
  @Roles('SUPER_ADMIN')
  async supprimerEtablissement(@Param('id') id: string) {
    return this.superAdminService.supprimerEtablissement(id);
  }

  @Patch('changer-etat-etablissements/:id')
  @Roles('SUPER_ADMIN')
  async basculerEtatEtablissement(@Param('id') id: string) {
    return this.superAdminService.basculerEtatEtablissement(id);
  }

  // ADMINS D'ÉTABLISSEMENT

  @Post('admin-etablissements')
  @Roles('SUPER_ADMIN')
  async creerAdminEtablissement(
    @Body() createAdminDto: CreateAdminEtablissementDto,
  ) {
    return this.superAdminService.creerAdminEtablissement(createAdminDto);
  }

  @Get('admin-etablissements')
  @Roles('SUPER_ADMIN')
  async obtenirTousLesAdminsEtablissement() {
    return this.superAdminService.obtenirTousLesAdminsEtablissement();
  }

  @Get('admin-etablissements/:id')
  @Roles('SUPER_ADMIN')
  async obtenirAdminEtablissement(@Param('id') id: string) {
    return this.superAdminService.obtenirAdminEtablissement(id);
  }

  @Put('admin-etablissements/:id')
  @Roles('SUPER_ADMIN')
  async mettreAJourAdminEtablissement(
    @Param('id') id: string,
    @Body() updateAdminDto: UpdateAdminEtablissementDto,
  ) {
    return this.superAdminService.mettreAJourAdminEtablissement(id, updateAdminDto);
  }

  @Patch('changer-etat-admin/:id')
  @Roles('SUPER_ADMIN')
  async basculerEtatAdminEtablissement(@Param('id') id: string) {
    return this.superAdminService.basculerEtatAdminEtablissement(id);
  }

  @Delete('admin-etablissements/:id')
  @Roles('SUPER_ADMIN')
  async supprimerAdminEtablissement(@Param('id') id: string) {
    return this.superAdminService.supprimerAdminEtablissement(id);
  }

  // ========== GESTION DES MOTS DE PASSE ==========

  @Patch('changer-mot-de-passe')
  @Roles('SUPER_ADMIN')
  async changerMotDePasseSuperAdmin(
    @UtilisateurActuel() user,
    @Body() changePasswordDto: ChangePasswordDto,
  ) {
    return this.superAdminService.changerMotDePasseSuperAdmin(
      user.utilisateurId,
      changePasswordDto,
    );
  }
}
