import { Module } from '@nestjs/common';
import { ServeurController } from './serveur.controller';
import { ServeurService } from './serveur.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ServeurController],
  providers: [ServeurService],
})
export class ServeurModule {}
