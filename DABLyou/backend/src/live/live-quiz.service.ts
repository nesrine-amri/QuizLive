import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MediaType, QuestionSource } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type LiveQuestionPayload = {
  id: string;
  mediaId: string;
  mediaType: 'TV' | 'RADIO';
  questionText: string;
  options: string[];
  validFrom: string;
  validUntil: string;
  points: number;
  questionType: string;
  source: 'AI' | 'HUMAN' | 'SPONSORED';
  campaignId?: string | null;
};

export type LeaderboardEntry = {
  rank: number;
  userId: string;
  firstName: string;
  lastName: string;
  pointsAwarded: number;
  responseTimeMs: number;
};

export type LeaderboardPayload = {
  questionId: string;
  mediaId: string;
  correctAnswer: string;
  totalAnswers: number;
  correctAnswers: number;
  entries: LeaderboardEntry[]; // top 10
};

// Shape returned by FastAPI /generate-question
type FastApiQuestion = {
  guest_name: string | null;
  question: string;
  options: string[];
  correct_index: number;
  category: string;
  confidence: number;
  transcript: string;
};

// How many seconds into the video to start the next clip.
// Advances by 30s each call so every question covers a fresh segment.
// Wraps around at VIDEO_MAX_SECONDS to loop the video for demos.
const CLIP_DURATION_S  = 30;
const VIDEO_MAX_SECONDS = 1800; // 30 min — adjust if your video is shorter

// Points awarded per correct answer
const BASE_POINTS = 10;

// How long (ms) the question stays open for answers
const QUESTION_VALIDITY_MS = 60_000; // 30 seconds

// How often NestJS asks FastAPI for a new question (per media channel)
const CYCLE_MS = 60_000; // 30 seconds — plus réactif entre deux questions

@Injectable()
export class LiveQuizService implements OnModuleInit {
  private readonly logger = new Logger(LiveQuizService.name);
  private readonly currentByMediaId = new Map<string, LiveQuestionPayload>();
  private broadcast?: (mediaId: string, payload: LiveQuestionPayload) => void;
  private broadcastLeaderboard?: (mediaId: string, payload: LeaderboardPayload) => void;

  // Sliding offset through the video — shared across all media channels for the demo
  private videoOffsetSeconds = 30;

  // FastAPI base URL — set FASTAPI_URL in .env to override
  private readonly fastapiUrl: string;

  /** Avoid duplicate FastAPI runs when tick + join_media overlap */
  private readonly inflightGeneration = new Map<
    string,
    Promise<LiveQuestionPayload | null>
  >();

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.fastapiUrl = this.config.get<string>('FASTAPI_URL', 'http://localhost:8000');
  }

  setBroadcaster(fn: (mediaId: string, payload: LiveQuestionPayload) => void) {
    this.broadcast = fn;
  }

  setLeaderboardBroadcaster(fn: (mediaId: string, payload: LeaderboardPayload) => void) {
    this.broadcastLeaderboard = fn;
  }

  onModuleInit() {
    // Fire immediately on startup so there is a question ready when the first
    // user connects, then repeat every CYCLE_MS.
    void this.tick().catch((e) => this.logger.error('Initial tick failed', e));

    setInterval(() => {
      void this.tick().catch((e) => this.logger.error('Tick failed', e));
    }, CYCLE_MS);
  }

  getCurrentQuestion(mediaId: string) {
    const q = this.currentByMediaId.get(mediaId);
    if (!q) return null;
    if (Date.parse(q.validUntil) < Date.now()) {
      this.currentByMediaId.delete(mediaId);
      return null;
    }
    return q;
  }

  // ── Called by tick, join_media (eager), and dev WebSocket helper ─────────
  async generateForMedia(mediaId: string): Promise<LiveQuestionPayload | null> {
    const ready = this.getCurrentQuestion(mediaId);
    if (ready) return ready;

    let pending = this.inflightGeneration.get(mediaId);
    if (pending) return pending;

    pending = this.executeGenerateForMedia(mediaId).finally(() => {
      this.inflightGeneration.delete(mediaId);
    });
    this.inflightGeneration.set(mediaId, pending);
    return pending;
  }

  private async executeGenerateForMedia(
    mediaId: string,
  ): Promise<LiveQuestionPayload | null> {
    const media = await this.prisma.media.findUnique({
      where: { id: mediaId },
      select: { id: true, type: true, isActive: true, youtubeUrl: true },
    });
    if (!media || !media.isActive) return null;

    // ── 1. Ask FastAPI for an AI question ──────────────────────────────────
    // If the channel has a YouTube live URL, pass it so FastAPI uses yt-dlp.
    // Otherwise fall back to the local video file with a sliding time offset.
    const startTime = this.buildTimestamp(this.videoOffsetSeconds);
    this.advanceOffset(); // move forward for the next call (no-op in live mode)

    let aiData: FastApiQuestion | null = null;
    try {
      const params = new URLSearchParams({ start_time: startTime });
      if (media.youtubeUrl) {
        params.set('stream_url', media.youtubeUrl);
      }
      const url = `${this.fastapiUrl}/generate-question?${params.toString()}`;
      this.logger.log(`Calling FastAPI → ${url}`);

      const res = await fetch(url, { signal: AbortSignal.timeout(90_000) });
      if (!res.ok) {
        const body = await res.text();
        throw new Error(`FastAPI returned ${res.status}: ${body}`);
      }
      aiData = (await res.json()) as FastApiQuestion;
    } catch (err) {
      this.logger.error('FastAPI call failed, skipping cycle', err);
      return null;
    }

    // ── 2. Validate the response ───────────────────────────────────────────
    if (
      !aiData.question ||
      !Array.isArray(aiData.options) ||
      aiData.options.length < 2 ||
      aiData.correct_index == null ||
      aiData.correct_index < 0 ||
      aiData.correct_index >= aiData.options.length
    ) {
      this.logger.error('FastAPI returned malformed question', aiData);
      return null;
    }

    const correctAnswer = aiData.options[aiData.correct_index];

    // ── 3. Persist to PostgreSQL ───────────────────────────────────────────
    const validFrom  = new Date();
    const validUntil = new Date(validFrom.getTime() + QUESTION_VALIDITY_MS);

    const created = await this.prisma.question.create({
      data: {
        mediaId:      media.id,
        mediaType:    media.type,
        questionText: aiData.question,
        options:      aiData.options,
        correctAnswer,
        questionType: aiData.category ?? 'ai_generated',
        points:       BASE_POINTS,
        validFrom,
        validUntil,
        source:       QuestionSource.AI,
      },
      select: {
        id: true, mediaId: true, mediaType: true,
        questionText: true, options: true,
        validFrom: true, validUntil: true,
        points: true, questionType: true,
        source: true, campaignId: true,
      },
    });

    // ── 4. Build payload and broadcast to all connected Flutter clients ────
    const payload: LiveQuestionPayload = {
      id:           created.id,
      mediaId:      created.mediaId,
      mediaType:    created.mediaType,
      questionText: created.questionText,
      options:      created.options,
      validFrom:    created.validFrom.toISOString(),
      validUntil:   created.validUntil.toISOString(),
      points:       created.points,
      questionType: created.questionType,
      source:       created.source,
      campaignId:   created.campaignId,
    };

    this.currentByMediaId.set(mediaId, payload);
    this.broadcast?.(mediaId, payload);

    this.logger.log(
      `[${media.id}] Question broadcast — "${aiData.question.slice(0, 60)}..."`,
    );

    // ── 5. Schedule leaderboard broadcast when the question closes ───────────
    // Wait until validUntil + 1s (give late answers a chance to land in DB)
    const msUntilClose = validUntil.getTime() - Date.now() + 1_000;
    setTimeout(() => {
      void this.broadcastLeaderboardForQuestion(created.id, media.id, correctAnswer)
        .catch((e) => this.logger.error('Leaderboard broadcast failed', e));
    }, msUntilClose);

    return payload;
  }

  // ── Fetch top 10 answers for a closed question and broadcast ─────────────
  async broadcastLeaderboardForQuestion(
    questionId: string,
    mediaId: string,
    correctAnswer: string,
  ): Promise<void> {
    const answers = await this.prisma.answer.findMany({
      where: { questionId },
      orderBy: [
        { pointsAwarded: 'desc' },   // correct + high speed bonus first
        { responseTimeMs: 'asc' },   // tiebreak: fastest
      ],
      take: 10,
      select: {
        userId: true,
        pointsAwarded: true,
        responseTimeMs: true,
        isCorrect: true,
        user: { select: { firstName: true, lastName: true } },
      },
    });

    const total   = await this.prisma.answer.count({ where: { questionId } });
    const correct = await this.prisma.answer.count({ where: { questionId, isCorrect: true } });

    const entries: LeaderboardEntry[] = answers.map((a, i) => ({
      rank:           i + 1,
      userId:         a.userId,
      firstName:      a.user.firstName,
      lastName:       a.user.lastName,
      pointsAwarded:  a.pointsAwarded,
      responseTimeMs: a.responseTimeMs,
    }));

    const leaderboardPayload: LeaderboardPayload = {
      questionId,
      mediaId,
      correctAnswer,
      totalAnswers:   total,
      correctAnswers: correct,
      entries,
    };

    this.broadcastLeaderboard?.(mediaId, leaderboardPayload);
    this.logger.log(
      `[${mediaId}] Leaderboard broadcast — ${total} answers, ${correct} correct`,
    );
  }

  // ── Runs every CYCLE_MS — generates for every active media that has no
  //    live question running right now ──────────────────────────────────────
  private async tick() {
    const mediaList = await this.prisma.media.findMany({
      where: { isActive: true },
      select: { id: true },
      take: 50,
    });

    // Generate sequentially to avoid hammering FastAPI with parallel requests
    for (const m of mediaList) {
      const current = this.getCurrentQuestion(m.id);
      if (current) continue; // still within validity window — skip
      await this.generateForMedia(m.id);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Convert total seconds → "HH:MM:SS" for ffmpeg -ss flag
  private buildTimestamp(totalSeconds: number): string {
    const h = Math.floor(totalSeconds / 3600);
    const m = Math.floor((totalSeconds % 3600) / 60);
    const s = totalSeconds % 60;
    return [h, m, s].map((n) => String(n).padStart(2, '0')).join(':');
  }

  // Move the clip window forward; wrap around at VIDEO_MAX_SECONDS
  private advanceOffset() {
    this.videoOffsetSeconds += CLIP_DURATION_S;
    if (this.videoOffsetSeconds >= VIDEO_MAX_SECONDS) {
      this.videoOffsetSeconds = 30; // restart from near the beginning
    }
  }
}
