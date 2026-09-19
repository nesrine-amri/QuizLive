import { Module } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GameplayController } from './gameplay.controller';
import { GameplayService } from './gameplay.service';

@Module({
  controllers: [GameplayController],
  providers: [GameplayService, PrismaService],
})
export class GameplayModule {}
