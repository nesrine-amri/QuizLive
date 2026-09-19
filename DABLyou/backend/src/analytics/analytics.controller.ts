import { Controller, Get, Query } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly svc: AnalyticsService) {}

  @Get('overview')
  overview() { return this.svc.overview(); }

  @Get('geo')
  geo() { return this.svc.geo(); }

  @Get('devices')
  devices() { return this.svc.devices(); }

  @Get('demographics')
  demographics() { return this.svc.demographics(); }

  @Get('channels')
  channels() { return this.svc.channels(); }

  @Get('timeline')
  timeline() { return this.svc.timeline(); }

  @Get('top-questions')
  topQuestions(@Query('limit') limit?: string) {
    return this.svc.topQuestions(limit ? parseInt(limit) : 10);
  }

  @Get('leaderboard')
  leaderboard(@Query('limit') limit?: string) {
    return this.svc.leaderboard(limit ? parseInt(limit) : 10);
  }

  @Get('points-distribution')
  pointsDistribution() { return this.svc.pointsDistribution(); }

  @Get('audience-by-hour')
  audienceByHour() { return this.svc.audienceByHour(); }

  @Get('channel-demographics')
  channelDemographics() { return this.svc.channelDemographics(); }
}
