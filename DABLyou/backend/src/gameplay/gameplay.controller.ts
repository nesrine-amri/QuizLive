import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ReqUser } from '../common/request-user.decorator';
import { SubmitAnswerDto } from './dto/submit-answer.dto';
import { GameplayService } from './gameplay.service';

@Controller('gameplay')
@UseGuards(JwtAuthGuard)
export class GameplayController {
  constructor(private readonly gameplay: GameplayService) {}

  @Post('answer')
  async answer(
    @ReqUser() user: { userId: string },
    @Body() dto: SubmitAnswerDto,
  ) {
    return await this.gameplay.submitAnswer(user.userId, dto);
  }
}
