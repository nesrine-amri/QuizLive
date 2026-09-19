import { Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { OnGatewayInit } from '@nestjs/websockets';
import { LiveQuizService } from './live-quiz.service';

type JoinPayload = { mediaId: string };

@WebSocketGateway({
  cors: { origin: true, credentials: true },
  namespace: '/live',
})
export class LiveGateway implements OnGatewayInit {
  private readonly logger = new Logger(LiveGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(private readonly live: LiveQuizService) {}

  afterInit(): void {
    // Broadcast new question to everyone watching that channel
    this.live.setBroadcaster((mediaId, payload) => {
      this.server.to(`media:${mediaId}`).emit('question', payload);
    });

    // Broadcast leaderboard once the question window closes
    this.live.setLeaderboardBroadcaster((mediaId, payload) => {
      this.server.to(`media:${mediaId}`).emit('leaderboard', payload);
    });
  }

  @SubscribeMessage('join_media')
  async join(
    @ConnectedSocket() socket: Socket,
    @MessageBody() body: JoinPayload,
  ) {
    if (!body?.mediaId) return { ok: false, error: 'MISSING_MEDIA_ID' };

    const room = `media:${body.mediaId}`;
    await socket.join(room);

    const current = this.live.getCurrentQuestion(body.mediaId);
    if (current) {
      socket.emit('question', current);
    } else {
      // Don’t wait for the global tick queue (other channels) — generate now.
      void this.live.generateForMedia(body.mediaId).catch((e) =>
        this.logger.warn(`Eager generate failed for ${body.mediaId}`, e),
      );
    }

    this.logger.log(`socket ${socket.id} joined ${room}`);
    return { ok: true };
  }

  // Admin/dev helper: manually generate and broadcast a new question
  @SubscribeMessage('dev_generate_question')
  async devGenerate(@MessageBody() body: JoinPayload) {
    if (!body?.mediaId) return { ok: false, error: 'MISSING_MEDIA_ID' };
    const q = await this.live.generateForMedia(body.mediaId);
    if (!q) return { ok: false, error: 'MEDIA_NOT_FOUND_OR_INACTIVE_OR_FASTAPI_DOWN' };

    return { ok: true, question: q };
  }
}
