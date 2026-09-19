import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AnalyticsModule } from './analytics/analytics.module';
import { AuthModule } from './auth/auth.module';
import { GameplayModule } from './gameplay/gameplay.module';
import { LiveModule } from './live/live.module';
import { MediaModule } from './media/media.module';
import { RewardsModule } from './rewards/rewards.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    UsersModule,
    MediaModule,
    GameplayModule,
    RewardsModule,
    LiveModule,
    AnalyticsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
