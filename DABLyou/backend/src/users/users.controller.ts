import {
  Body,
  Controller,
  Delete,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ReqUser } from '../common/request-user.decorator';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UsersService } from './users.service';

@Controller('me')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  async me(@ReqUser() user: { userId: string }) {
    return await this.users.getMe(user.userId);
  }

  @Patch()
  async update(
    @ReqUser() user: { userId: string },
    @Body() dto: UpdateProfileDto,
  ) {
    return await this.users.updateMe(user.userId, dto);
  }

  @Delete()
  async delete(@ReqUser() user: { userId: string }) {
    return await this.users.deleteMe(user.userId);
  }
}
