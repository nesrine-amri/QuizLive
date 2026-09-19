import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ReqUser } from '../common/request-user.decorator';
import { RewardsService } from './rewards.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class RewardsController {
  constructor(private readonly rewards: RewardsService) {}

  @Get('rewards')
  async listRewards() {
    return await this.rewards.listRewards();
  }

  @Post('rewards/redeem')
  async redeem(
    @ReqUser() user: { userId: string },
    @Body() body: { rewardId: string },
  ) {
    return await this.rewards.redeem(user.userId, body.rewardId);
  }

  @Get('coupons/mine')
  async myCoupons(@ReqUser() user: { userId: string }) {
    return await this.rewards.myCoupons(user.userId);
  }

  @Post('coupons/:id/use')
  async use(@ReqUser() user: { userId: string }, @Param('id') id: string) {
    return await this.rewards.useCoupon(user.userId, id);
  }

  @Get('points/history')
  async points(@ReqUser() user: { userId: string }) {
    return await this.rewards.pointsHistory(user.userId);
  }
}
