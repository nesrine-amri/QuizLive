import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── helpers ───────────────────────────────────────────────────────────────
  private startOfToday(): Date {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }

  // ── 1. KPI overview ───────────────────────────────────────────────────────
  async overview() {
    const today = this.startOfToday();

    const [
      totalAnswersToday,
      correctAnswersToday,
      pointsToday,
      activeUsersToday,
      totalUsers,
      totalQuestions,
      couponsRedeemed,
      avgResponseRaw,
    ] = await Promise.all([
      this.prisma.answer.count({ where: { createdAt: { gte: today } } }),

      this.prisma.answer.count({ where: { createdAt: { gte: today }, isCorrect: true } }),

      this.prisma.answer.aggregate({
        where: { createdAt: { gte: today } },
        _sum: { pointsAwarded: true },
      }),

      this.prisma.answer.findMany({
        where: { createdAt: { gte: today } },
        distinct: ['userId'],
        select: { userId: true },
      }),

      this.prisma.user.count(),

      this.prisma.question.count({ where: { createdAt: { gte: today } } }),

      this.prisma.coupon.count({ where: { status: 'USED' } }),

      this.prisma.answer.aggregate({
        where: { createdAt: { gte: today }, isCorrect: true },
        _avg: { responseTimeMs: true },
      }),
    ]);

    const engagementRate =
      totalUsers > 0 ? (activeUsersToday.length / totalUsers) * 100 : 0;

    const correctRate =
      totalAnswersToday > 0 ? (correctAnswersToday / totalAnswersToday) * 100 : 0;

    return {
      totalAnswersToday,
      correctAnswersToday,
      correctRate: Math.round(correctRate * 10) / 10,
      pointsDistributedToday: pointsToday._sum.pointsAwarded ?? 0,
      activeUsersToday: activeUsersToday.length,
      totalUsers,
      totalQuestionsToday: totalQuestions,
      couponsRedeemed,
      engagementRate: Math.round(engagementRate * 10) / 10,
      avgResponseTimeMs: Math.round(avgResponseRaw._avg.responseTimeMs ?? 0),
    };
  }

  // ── 2. Geographic distribution (by city) ─────────────────────────────────
  async geo() {
    const rows: Array<{
      city: string | null;
      count: bigint;
      correct: bigint;
    }> = await this.prisma.$queryRaw`
      SELECT
        city,
        COUNT(*)::bigint             AS count,
        SUM(CASE WHEN "isCorrect" THEN 1 ELSE 0 END)::bigint AS correct
      FROM "Answer"
      WHERE city IS NOT NULL
      GROUP BY city
      ORDER BY count DESC
    `;

    return rows.map((r) => ({
      city: r.city ?? 'غير محدد',
      count: Number(r.count),
      correctRate:
        Number(r.count) > 0
          ? Math.round((Number(r.correct) / Number(r.count)) * 1000) / 10
          : 0,
    }));
  }

  // ── 3. Device OS breakdown ────────────────────────────────────────────────
  async devices() {
    const rows: Array<{ deviceOs: string | null; count: bigint }> =
      await this.prisma.$queryRaw`
        SELECT "deviceOs", COUNT(*)::bigint AS count
        FROM "Answer"
        WHERE "deviceOs" IS NOT NULL
        GROUP BY "deviceOs"
        ORDER BY count DESC
      `;

    const total = rows.reduce((s, r) => s + Number(r.count), 0);
    return rows.map((r) => ({
      os: r.deviceOs ?? 'unknown',
      count: Number(r.count),
      pct: total > 0 ? Math.round((Number(r.count) / total) * 1000) / 10 : 0,
    }));
  }

  // ── 4. Demographics (gender + age groups) ────────────────────────────────
  async demographics() {
    const genderRows: Array<{ gender: string; count: bigint }> =
      await this.prisma.$queryRaw`
        SELECT gender::text, COUNT(*)::bigint AS count
        FROM "User"
        GROUP BY gender
      `;

    const ageRows: Array<{ age_group: string; count: bigint }> =
      await this.prisma.$queryRaw`
        SELECT
          CASE
            WHEN EXTRACT(YEAR FROM AGE("birthDate")) < 18  THEN 'أقل من 18'
            WHEN EXTRACT(YEAR FROM AGE("birthDate")) < 25  THEN '18–24'
            WHEN EXTRACT(YEAR FROM AGE("birthDate")) < 35  THEN '25–34'
            WHEN EXTRACT(YEAR FROM AGE("birthDate")) < 45  THEN '35–44'
            WHEN EXTRACT(YEAR FROM AGE("birthDate")) < 55  THEN '45–54'
            ELSE '55+'
          END AS age_group,
          COUNT(*)::bigint AS count
        FROM "User"
        GROUP BY age_group
        ORDER BY MIN(EXTRACT(YEAR FROM AGE("birthDate")))
      `;

    return {
      gender: genderRows.map((r) => ({
        gender: r.gender,
        count: Number(r.count),
      })),
      ageGroups: ageRows.map((r) => ({
        group: r.age_group,
        count: Number(r.count),
      })),
    };
  }

  // ── 5. Channel performance ────────────────────────────────────────────────
  async channels() {
    const today = this.startOfToday();

    const rows: Array<{
      mediaId: string;
      name: string;
      type: string;
      total: bigint;
      correct: bigint;
      avgMs: number | null;
    }> = await this.prisma.$queryRaw`
      SELECT
        q."mediaId",
        m.name,
        m.type::text,
        COUNT(a.id)::bigint                                           AS total,
        SUM(CASE WHEN a."isCorrect" THEN 1 ELSE 0 END)::bigint        AS correct,
        AVG(a."responseTimeMs")                                       AS "avgMs"
      FROM "Answer" a
      JOIN "Question" q ON a."questionId" = q.id
      JOIN "Media"   m ON q."mediaId"    = m.id
      WHERE a."createdAt" >= ${today}
      GROUP BY q."mediaId", m.name, m.type
      ORDER BY total DESC
    `;

    return rows.map((r) => ({
      mediaId: r.mediaId,
      name: r.name,
      type: r.type,
      totalAnswers: Number(r.total),
      correctRate:
        Number(r.total) > 0
          ? Math.round((Number(r.correct) / Number(r.total)) * 1000) / 10
          : 0,
      avgResponseMs: Math.round(r.avgMs ?? 0),
    }));
  }

  // ── 6. Hourly timeline — last 24 hours ───────────────────────────────────
  async timeline() {
    const rows: Array<{
      hour: Date;
      answers: bigint;
      correct: bigint;
    }> = await this.prisma.$queryRaw`
      SELECT
        DATE_TRUNC('hour', "createdAt") AS hour,
        COUNT(*)::bigint                                         AS answers,
        SUM(CASE WHEN "isCorrect" THEN 1 ELSE 0 END)::bigint     AS correct
      FROM "Answer"
      WHERE "createdAt" >= NOW() - INTERVAL '24 hours'
      GROUP BY hour
      ORDER BY hour ASC
    `;

    return rows.map((r) => ({
      hour: r.hour.toISOString(),
      answers: Number(r.answers),
      correct: Number(r.correct),
    }));
  }

  // ── 7. Top questions by engagement ───────────────────────────────────────
  async topQuestions(limit = 10) {
    const today = this.startOfToday();

    const rows: Array<{
      id: string;
      questionText: string;
      total: bigint;
      correct: bigint;
      avgMs: number | null;
    }> = await this.prisma.$queryRaw`
      SELECT
        q.id,
        q."questionText",
        COUNT(a.id)::bigint                                       AS total,
        SUM(CASE WHEN a."isCorrect" THEN 1 ELSE 0 END)::bigint    AS correct,
        AVG(a."responseTimeMs")                                   AS "avgMs"
      FROM "Answer" a
      JOIN "Question" q ON a."questionId" = q.id
      WHERE a."createdAt" >= ${today}
      GROUP BY q.id, q."questionText"
      ORDER BY total DESC
      LIMIT ${limit}
    `;

    return rows.map((r) => ({
      id: r.id,
      questionText: r.questionText,
      totalAnswers: Number(r.total),
      correctRate:
        Number(r.total) > 0
          ? Math.round((Number(r.correct) / Number(r.total)) * 1000) / 10
          : 0,
      avgResponseMs: Math.round(r.avgMs ?? 0),
    }));
  }

  // ── 8. Leaderboard — top users all time ──────────────────────────────────
  async leaderboard(limit = 10) {
    return this.prisma.user.findMany({
      orderBy: { totalPoints: 'desc' },
      take: limit,
      select: {
        id: true,
        firstName: true,
        lastName: true,
        city: true,
        gender: true,
        totalPoints: true,
        _count: { select: { answers: true } },
      },
    });
  }

  // ── 9. Points distribution buckets (for histogram) ───────────────────────
  async pointsDistribution() {
    const buckets = [0, 100, 250, 500, 750, 1000, 1500, 2000];
    const rows: Array<{ bucket: string; count: bigint }> =
      await this.prisma.$queryRaw`
        SELECT
          CASE
            WHEN "totalPoints" = 0        THEN '0'
            WHEN "totalPoints" < 100      THEN '1–99'
            WHEN "totalPoints" < 250      THEN '100–249'
            WHEN "totalPoints" < 500      THEN '250–499'
            WHEN "totalPoints" < 750      THEN '500–749'
            WHEN "totalPoints" < 1000     THEN '750–999'
            WHEN "totalPoints" < 2000     THEN '1000–1999'
            ELSE '2000+'
          END AS bucket,
          COUNT(*)::bigint AS count
        FROM "User"
        GROUP BY bucket
      `;

    const order = ['0','1–99','100–249','250–499','500–749','750–999','1000–1999','2000+'];
    const map = Object.fromEntries(rows.map((r) => [r.bucket, Number(r.count)]));
    return order.map((b) => ({ bucket: b, count: map[b] ?? 0 }));
  }

  // ── 10. Audience by hour — AGE GROUP × HOUR OF DAY ───────────────────────
  //   Core advertiser query: "who is engaged at each hour of the day?"
  //   Returns a matrix: for each hour (0-23), how many viewers per age group.
  //   Used to decide when to book a spot for a product targeting 25-34 year olds.
  async audienceByHour() {
    const rows: Array<{
      hour: number;
      age_group: string;
      count: bigint;
      avg_response_ms: number;
    }> = await this.prisma.$queryRaw`
      SELECT
        EXTRACT(HOUR FROM a."createdAt")::int   AS hour,
        CASE
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 18  THEN 'أقل من 18'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 25  THEN '18–24'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 35  THEN '25–34'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 45  THEN '35–44'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 55  THEN '45–54'
          ELSE '55+'
        END                                    AS age_group,
        COUNT(*)::bigint                        AS count,
        AVG(a."responseTimeMs")                AS avg_response_ms
      FROM "Answer" a
      JOIN "User" u ON a."userId" = u.id
      GROUP BY hour, age_group
      ORDER BY hour, age_group
    `;

    // Build matrix: { hour: 0..23, groups: { '18-24': n, ... } }
    const matrix: Record<number, Record<string, { count: number; avgMs: number }>> = {};
    for (let h = 0; h < 24; h++) matrix[h] = {};

    for (const r of rows) {
      matrix[r.hour][r.age_group] = {
        count: Number(r.count),
        avgMs: Math.round(r.avg_response_ms ?? 0),
      };
    }

    // Compute an "ad value score" per hour:
    //   score = total_viewers × avg_engagement_rate (faster = more engaged)
    const AGE_GROUPS = ['أقل من 18', '18–24', '25–34', '35–44', '45–54', '55+'];
    const result = Array.from({ length: 24 }, (_, h) => {
      const groups = matrix[h];
      const totalViewers = Object.values(groups).reduce((s, g) => s + g.count, 0);
      const avgMs = totalViewers > 0
        ? Object.values(groups).reduce((s, g) => s + g.avgMs * g.count, 0) / totalViewers
        : 30000;
      // Score: 100 at 0ms response → 0 at 30s. Higher = more engaged audience.
      const engagementScore = Math.max(0, Math.round((1 - avgMs / 30000) * 100));
      return {
        hour: h,
        label: `${String(h).padStart(2, '0')}:00`,
        totalViewers,
        engagementScore,
        adValueScore: Math.round(totalViewers * (engagementScore / 100) * 10) / 10,
        groups: Object.fromEntries(
          AGE_GROUPS.map((g) => [g, groups[g]?.count ?? 0])
        ),
      };
    });

    return result;
  }

  // ── 11. Channel demographics — per channel: age + gender breakdown ────────
  //   Answers: "El Hiwar Ettounsi at prime time is 60% women aged 25-44"
  //   Used by advertisers to match their target audience to the right channel.
  async channelDemographics() {
    const rows: Array<{
      mediaId: string;
      name: string;
      type: string;
      age_group: string;
      gender: string;
      count: bigint;
      avg_response_ms: number;
    }> = await this.prisma.$queryRaw`
      SELECT
        q."mediaId",
        m.name,
        m.type::text                                               AS type,
        CASE
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 18  THEN 'أقل من 18'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 25  THEN '18–24'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 35  THEN '25–34'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 45  THEN '35–44'
          WHEN EXTRACT(YEAR FROM AGE(u."birthDate")) < 55  THEN '45–54'
          ELSE '55+'
        END                                                        AS age_group,
        u.gender::text                                             AS gender,
        COUNT(*)::bigint                                           AS count,
        AVG(a."responseTimeMs")                                    AS avg_response_ms
      FROM "Answer" a
      JOIN "Question" q ON a."questionId" = q.id
      JOIN "Media"   m ON q."mediaId"    = m.id
      JOIN "User"    u ON a."userId"     = u.id
      GROUP BY q."mediaId", m.name, m.type, age_group, gender
      ORDER BY q."mediaId", count DESC
    `;

    // Group by channel
    const channels: Record<string, {
      mediaId: string; name: string; type: string;
      totalAnswers: number;
      ageGroups: Record<string, number>;
      gender: Record<string, number>;
      avgResponseMs: number;
    }> = {};

    for (const r of rows) {
      if (!channels[r.mediaId]) {
        channels[r.mediaId] = {
          mediaId: r.mediaId, name: r.name, type: r.type,
          totalAnswers: 0, ageGroups: {}, gender: {}, avgResponseMs: 0,
        };
      }
      const ch = channels[r.mediaId];
      const n = Number(r.count);
      ch.totalAnswers += n;
      ch.ageGroups[r.age_group] = (ch.ageGroups[r.age_group] ?? 0) + n;
      ch.gender[r.gender] = (ch.gender[r.gender] ?? 0) + n;
    }

    // Compute dominant age group, gender split, engagement score
    return Object.values(channels).map((ch) => {
      const dominantAge = Object.entries(ch.ageGroups)
        .sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'N/A';
      const male   = ch.gender['MALE']   ?? 0;
      const female = ch.gender['FEMALE'] ?? 0;
      const total  = ch.totalAnswers || 1;
      return {
        ...ch,
        dominantAge,
        malePct:   Math.round((male   / total) * 100),
        femalePct: Math.round((female / total) * 100),
      };
    }).sort((a, b) => b.totalAnswers - a.totalAnswers);
  }
}
