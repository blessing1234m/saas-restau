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
    const utilisateur = await this.prisma.utilisateur.findUnique({
      where: { codeAgent },
    });

    if (!utilisateur) {
      return null;
    }

    const estValide = await this.verifierMotDePasse(
      motDePasse,
      utilisateur.motDePasse,
    );

    if (!estValide) {
      return null;
    }

    if (!utilisateur.estActif) {
      return null;
    }

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
