import { Controller, Get, Post, Query, UseGuards, Body } from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ReqUser } from '../common/request-user.decorator';
import { MediaService } from './media.service';

@Controller('media')
export class MediaController {
  constructor(private readonly media: MediaService) {}

  @Get()
  async list(@Query('type') type?: 'TV' | 'RADIO') {
    return await this.media.list(type);
  }

  @Post('select')
  @UseGuards(JwtAuthGuard)
  async select(
    @ReqUser() user: { userId: string },
    @Body() body: { mediaId: string },
  ) {
    return await this.media.select(user.userId, body.mediaId);
  }
}
