import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    return await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        gender: true,
        birthDate: true,
        totalPoints: true,
        createdAt: true,
        lastLoginAt: true,
      },
    });
  }

  async updateMe(userId: string, dto: UpdateProfileDto) {
    return await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.firstName ? { firstName: dto.firstName.trim() } : {}),
        ...(dto.lastName ? { lastName: dto.lastName.trim() } : {}),
        ...(dto.gender ? { gender: dto.gender } : {}),
        ...(dto.birthDate ? { birthDate: new Date(dto.birthDate) } : {}),
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        gender: true,
        birthDate: true,
        totalPoints: true,
        createdAt: true,
        lastLoginAt: true,
      },
    });
  }

  async deleteMe(userId: string) {
    await this.prisma.user.delete({ where: { id: userId } });
    return { ok: true };
  }
}
