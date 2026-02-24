import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { EVENTS, MessageCreatedPayload } from '@noton/shared';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMessageDto } from './dto/create-message.dto';

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject('NATS_SERVICE') private readonly nats: ClientProxy,
  ) {}

  async create(channelId: string, dto: CreateMessageDto, authorId: string) {
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
    });
    if (!channel) throw new NotFoundException(`Channel ${channelId} not found`);

    // Auto-create thread if threadId not provided and this is a thread reply
    let resolvedThreadId = dto.threadId ?? null;
    if (dto.threadId) {
      const thread = await this.prisma.thread.findUnique({
        where: { id: dto.threadId },
      });
      if (!thread) throw new NotFoundException(`Thread ${dto.threadId} not found`);
    }

    const message = await this.prisma.message.create({
      data: {
        channelId,
        threadId: resolvedThreadId,
        authorId,
        content: dto.content,
        type: dto.type ?? 'text',
      },
    });

    // Publish NATS event (fire-and-forget)
    const payload: MessageCreatedPayload = {
      channelId,
      threadId: message.threadId ?? undefined,
      authorId,
      content: message.content,
      type: message.type as MessageCreatedPayload['type'],
    };
    this.nats.emit(EVENTS.MESSAGE_CREATED, payload).subscribe({
      error: (err: unknown) => console.error('[chat] NATS emit failed:', err),
    });

    return message;
  }

  findByChannel(channelId: string, threadId?: string, cursor?: string, limit = 50) {
    return this.prisma.message.findMany({
      where: {
        channelId,
        threadId: threadId ?? null,
        ...(cursor ? { id: { lt: cursor } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async createThread(channelId: string) {
    const channel = await this.prisma.channel.findUnique({
      where: { id: channelId },
    });
    if (!channel) throw new NotFoundException(`Channel ${channelId} not found`);
    return this.prisma.thread.create({ data: { channelId } });
  }
}
