import { Module } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RewardsController } from './rewards.controller';
import { RewardsService } from './rewards.service';

@Module({
  controllers: [RewardsController],
  providers: [RewardsService, PrismaService],
  exports: [RewardsService],
})
export class RewardsModule {}
