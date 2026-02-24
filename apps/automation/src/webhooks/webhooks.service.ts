import { Inject, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateWebhookDto } from './dto/create-webhook.dto';

@Injectable()
export class WebhooksService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject('NATS_SERVICE') private readonly nats: ClientProxy,
  ) {}

  create(dto: CreateWebhookDto) {
    return this.prisma.webhook.create({
      data: {
        workspaceId: dto.workspaceId,
        name: dto.name,
        n8nWorkflowId: dto.n8nWorkflowId,
        secret: randomBytes(24).toString('hex'),
      },
    });
  }

  findByWorkspace(workspaceId: string) {
    return this.prisma.webhook.findMany({
      where: { workspaceId, isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async receive(id: string, secret: string, payload: Record<string, unknown>) {
    const webhook = await this.prisma.webhook.findUnique({ where: { id } });
    if (!webhook || !webhook.isActive) throw new NotFoundException(`Webhook ${id} not found`);
    if (webhook.secret !== secret) throw new UnauthorizedException('Invalid webhook secret');

    const event = await this.prisma.webhookEvent.create({
      data: { webhookId: id, payload, status: 'received' },
    });

    // Publish to NATS for downstream processing
    this.nats.emit('webhook.received', { webhookId: id, eventId: event.id, payload }).subscribe({
      error: (err: unknown) => console.error('[automation] NATS emit failed:', err),
    });

    return { received: true, eventId: event.id };
  }

  async delete(id: string) {
    const webhook = await this.prisma.webhook.findUnique({ where: { id } });
    if (!webhook) throw new NotFoundException(`Webhook ${id} not found`);
    return this.prisma.webhook.update({ where: { id }, data: { isActive: false } });
  }
}
