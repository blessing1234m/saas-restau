import { Module } from '@nestjs/common';
import { ServeurController } from './serveur.controller';
import { ServeurService } from './serveur.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [ServeurController],
  providers: [ServeurService],
})
export class ServeurModule {}
