import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

function promoCode(partner: string) {
  const suffix = randomUUID().replace(/-/g, '').slice(0, 5).toUpperCase();
  const cleaned = partner
    .replace(/[^A-Z0-9]/gi, '')
    .slice(0, 10)
    .toUpperCase();
  return `TABA3-${cleaned}-${suffix}`;
}

@Injectable()
export class RewardsService {
  constructor(private readonly prisma: PrismaService) {}

  async listRewards() {
    return await this.prisma.reward.findMany({
      where: { isActive: true, partner: { isActive: true } },
      orderBy: [{ requiredPoints: 'asc' }, { title: 'asc' }],
      select: {
        id: true,
        title: true,
        description: true,
        requiredPoints: true,
        discountValue: true,
        expiresInDays: true,
        partner: { select: { id: true, name: true, logoUrl: true } },
      },
    });
  }

  async redeem(userId: string, rewardId: string) {
    const reward = await this.prisma.reward.findUnique({
      where: { id: rewardId },
      include: { partner: true },
    });
    if (!reward || !reward.isActive || !reward.partner.isActive)
      throw new BadRequestException('REWARD_NOT_AVAILABLE');

    return await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { id: true, totalPoints: true },
      });

      if (user.totalPoints < reward.requiredPoints)
        throw new BadRequestException('NOT_ENOUGH_POINTS');

      const expiresAt = new Date(
        Date.now() + reward.expiresInDays * 24 * 60 * 60 * 1000,
      );

      const coupon = await tx.coupon.create({
        data: {
          userId,
          rewardId: reward.id,
          code: promoCode(reward.partner.name),
          expiresAt,
        },
        select: {
          id: true,
          code: true,
          status: true,
          createdAt: true,
          expiresAt: true,
          reward: {
            select: {
              id: true,
              title: true,
              discountValue: true,
              partner: { select: { id: true, name: true, logoUrl: true } },
            },
          },
        },
      });

      await tx.user.update({
        where: { id: userId },
        data: { totalPoints: { decrement: reward.requiredPoints } },
      });

      await tx.pointEvent.create({
        data: {
          userId,
          delta: -reward.requiredPoints,
          reason: 'REDEEM_REWARD',
          couponId: coupon.id,
        },
      });

      const updated = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { totalPoints: true },
      });

      return { coupon, totalPoints: updated.totalPoints };
    });
  }

  async myCoupons(userId: string) {
    return await this.prisma.coupon.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        code: true,
        status: true,
        createdAt: true,
        usedAt: true,
        expiresAt: true,
        reward: {
          select: {
            id: true,
            title: true,
            discountValue: true,
            partner: { select: { id: true, name: true, logoUrl: true } },
          },
        },
      },
    });
  }

  async useCoupon(userId: string, couponId: string) {
    const coupon = await this.prisma.coupon.findUniqueOrThrow({
      where: { id: couponId },
      include: { reward: { include: { partner: true } } },
    });

    if (coupon.userId !== userId)
      throw new BadRequestException('NOT_YOUR_COUPON');
    if (coupon.status !== 'AVAILABLE')
      throw new BadRequestException('COUPON_NOT_AVAILABLE');
    if (coupon.expiresAt.getTime() < Date.now())
      throw new BadRequestException('COUPON_EXPIRED');

    const updated = await this.prisma.coupon.update({
      where: { id: couponId },
      data: { status: 'USED', usedAt: new Date() },
      select: {
        id: true,
        status: true,
        usedAt: true,
      },
    });
    return updated;
  }

  async pointsHistory(userId: string) {
    return await this.prisma.pointEvent.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 200,
      select: { id: true, delta: true, reason: true, createdAt: true },
    });
  }
}
