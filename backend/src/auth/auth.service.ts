import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import { Utilisateur } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async hasherMotDePasse(motDePasse: string): Promise<string> {
    const salt = await bcrypt.genSalt(10);
    return bcrypt.hash(motDePasse, salt);
  }

  async verifierMotDePasse(
    motDePasse: string,
    motDePasseHash: string,
  ): Promise<boolean> {
    return bcrypt.compare(motDePasse, motDePasseHash);
  }

  async validerUtilisateur(
    codeAgent: string,
    motDePasse: string,
  ): Promise<Utilisateur | null> {
    console.log('[validerUtilisateur] Recherche utilisateur:', codeAgent);
    
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { codeAgent },
    });

    console.log('[validerUtilisateur] Utilisateur trouvé:', utilisateur ? 'OUI' : 'NON');

    if (!utilisateur) {
      console.log('[validerUtilisateur] Utilisateur non trouvé dans DB');
      return null;
    }

    const estValide = await this.verifierMotDePasse(
      motDePasse,
      utilisateur.motDePasse,
    );

    console.log('[validerUtilisateur] Mot de passe valide:', estValide);

    if (!estValide) {
      console.log('[validerUtilisateur] Mot de passe incorrect');
      return null;
    }

    console.log('[validerUtilisateur] Utilisateur actif:', utilisateur.estActif);

    if (!utilisateur.estActif) {
      console.log('[validerUtilisateur] Utilisateur inactif');
      return null;
    }

    console.log('[validerUtilisateur] Authentification réussie');
    return utilisateur;
  }

  async creerToken(utilisateur: Utilisateur): Promise<string> {
    const payload = {
      sub: utilisateur.id,
      codeAgent: utilisateur.codeAgent,
      role: utilisateur.role,
    };  

    return this.jwtService.sign(payload);
  }

  async creerUtilisateur(
    codeAgent: string,
    motDePasse: string,
    role: 'SUPER_ADMIN' | 'ADMIN_ETABLISSEMENT' | 'SERVEUR',
  ): Promise<Utilisateur> {
    const motDePasseHash = await this.hasherMotDePasse(motDePasse);

    return this.prisma.utilisateur.create({
      data: {
        codeAgent,
        motDePasse: motDePasseHash,
        role,
      },
    });
  }
}
