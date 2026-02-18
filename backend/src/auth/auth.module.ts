import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { AuthenticationService } from './authentication.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { PrismaModule } from '../prisma/prisma.module';
import { RoleGuard } from './guards/role.guard';
import { EtablissementActifGuard } from './guards/etablissement-actif.guard';

@Module({
  imports: [
    PassportModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'super-secret-key-change-in-production',
      signOptions: { expiresIn: '24h' },
    }),
    PrismaModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, AuthenticationService, JwtStrategy, RoleGuard, EtablissementActifGuard],
  exports: [AuthService, AuthenticationService, RoleGuard, EtablissementActifGuard],
})
export class AuthModule {}
