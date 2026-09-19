import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { LiveGateway } from './live.gateway';
import { LiveQuizService } from './live-quiz.service';

@Module({
  imports: [ConfigModule],
  providers: [LiveGateway, LiveQuizService, PrismaService],
})
export class LiveModule {}
