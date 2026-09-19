import { Injectable } from '@nestjs/common';
import { MediaType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MediaService {
  constructor(private readonly prisma: PrismaService) {}

  async list(type?: 'TV' | 'RADIO') {
    return await this.prisma.media.findMany({
      where: {
        isActive: true,
        ...(type
          ? { type: type === 'TV' ? MediaType.TV : MediaType.RADIO }
          : {}),
      },
      orderBy: [{ popularity: 'desc' }, { name: 'asc' }],
      select: {
        id: true,
        name: true,
        type: true,
        logoUrl: true,
        popularity: true,
      },
    });
  }

  async select(userId: string, mediaId: string) {
    const selection = await this.prisma.mediaSelection.create({
      data: { userId, mediaId },
    });
    return { ok: true, selectionId: selection.id };
  }
}
