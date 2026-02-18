import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { SuperAdminModule } from './super-admin/super-admin.module';
import { AdminEtablissementModule } from './admin-etablissement/admin-etablissement.module';
import { CommandesModule } from './commandes/commandes.module';

@Module({
  imports: [PrismaModule, AuthModule, SuperAdminModule, AdminEtablissementModule, CommandesModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
