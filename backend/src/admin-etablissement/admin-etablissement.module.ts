import { Module } from '@nestjs/common';
import { AdminEtablissementService } from './admin-etablissement.service';
import { AdminEtablissementController } from './admin-etablissement.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [AdminEtablissementController],
  providers: [AdminEtablissementService],
})
export class AdminEtablissementModule {}
