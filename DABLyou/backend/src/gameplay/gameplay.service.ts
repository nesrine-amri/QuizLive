import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubmitAnswerDto } from './dto/submit-answer.dto';

// ── Scoring constants ────────────────────────────────────────────────────────
//
//  Every correct answer earns BASE_POINTS + a speed bonus (0–MAX_SPEED_BONUS).
//  Speed bonus is proportional to how quickly the user answered relative to
//  the question's validity window.
//
//  Examples (30-second window, BASE=10, MAX_BONUS=5):
//    Answered in  3s → bonus 5 → 15 pts  (lightning fast)
//    Answered in 10s → bonus 3 → 13 pts  (quick)
//    Answered in 20s → bonus 1 → 11 pts  (slow)
//    Answered in 28s → bonus 0 → 10 pts  (last second)
//    Wrong answer    →          →  0 pts
//
//  Reward thresholds (kept in sync with prisma/seed.ts):
//    500  pts → 10% discount coupon  ≈ 1h average viewing
//    1000 pts → 15% discount coupon  ≈ 2h average viewing
//
const BASE_POINTS      = 10;
const MAX_SPEED_BONUS  = 5;   // max extra pts for instant answers

function calcPoints(
  isCorrect: boolean,
  basePoints: number,
  responseTimeMs: number,
  validFromMs: number,
  validUntilMs: number,
): { points: number; speedBonus: number } {
  if (!isCorrect) return { points: 0, speedBonus: 0 };

  const windowMs   = validUntilMs - validFromMs;                  // e.g. 30 000 ms
  const elapsed    = Math.max(0, Math.min(responseTimeMs, windowMs));
  // speedFactor goes from 1.0 (instant) down to 0.0 (answered at the last ms)
  const speedFactor = 1 - elapsed / windowMs;
  const speedBonus  = Math.round(speedFactor * MAX_SPEED_BONUS);  // 0–5
  return { points: basePoints + speedBonus, speedBonus };
}

// Next reward threshold above current total (500 or 1000)
function nextThreshold(totalPoints: number): number {
  if (totalPoints < 500)  return 500;
  if (totalPoints < 1000) return 1000;
  // After 1000: keep cycling in 1000-pt increments for repeat coupons
  return Math.ceil((totalPoints + 1) / 1000) * 1000;
}

@Injectable()
export class GameplayService {
  constructor(private readonly prisma: PrismaService) {}

  async submitAnswer(userId: string, dto: SubmitAnswerDto) {
    const question = await this.prisma.question.findUnique({
      where: { id: dto.questionId },
      select: {
        id: true,
        correctAnswer: true,
        options: true,
        validFrom: true,
        validUntil: true,
        points: true,
      },
    });
    if (!question) throw new BadRequestException('QUESTION_NOT_FOUND');

    const now = Date.now();
    if (now < question.validFrom.getTime())
      throw new BadRequestException('QUESTION_NOT_YET_VALID');
    if (now > question.validUntil.getTime())
      throw new BadRequestException('QUESTION_EXPIRED');

    if (!question.options.includes(dto.selectedAnswer))
      throw new BadRequestException('INVALID_OPTION');

    // Fetch user's city once — stored on the answer for advertiser analytics
    const userProfile = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { city: true },
    });

    return await this.prisma.$transaction(async (tx) => {
      const existing = await tx.answer.findUnique({
        where: { userId_questionId: { userId, questionId: question.id } },
        select: { id: true },
      });
      if (existing) throw new BadRequestException('ALREADY_ANSWERED');

      const isCorrect = dto.selectedAnswer === question.correctAnswer;

      const { points: pointsAwarded, speedBonus } = calcPoints(
        isCorrect,
        question.points ?? BASE_POINTS,
        dto.responseTimeMs,
        question.validFrom.getTime(),
        question.validUntil.getTime(),
      );

      const answer = await tx.answer.create({
        data: {
          userId,
          questionId:    question.id,
          selectedAnswer: dto.selectedAnswer,
          isCorrect,
          responseTimeMs: dto.responseTimeMs,
          pointsAwarded,
          city:     userProfile?.city ?? null,   // from user profile
          deviceOs: dto.deviceOs     ?? null,    // from Flutter client
        },
        select: {
          id: true,
          isCorrect: true,
          pointsAwarded: true,
          createdAt: true,
        },
      });

      if (pointsAwarded > 0) {
        await tx.user.update({
          where: { id: userId },
          data: { totalPoints: { increment: pointsAwarded } },
        });
        await tx.pointEvent.create({
          data: {
            userId,
            delta: pointsAwarded,
            reason: speedBonus > 0 ? `CORRECT_ANSWER (+${speedBonus} speed bonus)` : 'CORRECT_ANSWER',
            answerId: answer.id,
          },
        });
      } else {
        await tx.pointEvent.create({
          data: {
            userId,
            delta: 0,
            reason: 'WRONG_ANSWER',
            answerId: answer.id,
          },
        });
      }

      const user = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { totalPoints: true },
      });

      const next            = nextThreshold(user.totalPoints);
      const progressToNext  = user.totalPoints % next === 0 && user.totalPoints > 0
        ? next  // just hit the threshold
        : user.totalPoints % (next <= 1000 ? next : 1000);
      const remainingToNext = next - user.totalPoints;

      return {
        answer: {
          ...answer,
          speedBonus,          // tell the Flutter app how many bonus pts they earned
        },
        totalPoints:          user.totalPoints,
        nextCouponThreshold:  next,
        progressToNextCoupon: user.totalPoints,
        remainingToNextCoupon: Math.max(0, remainingToNext),
      };
    });
  }
}
