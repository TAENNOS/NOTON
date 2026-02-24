import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  findByUser(userId: string, workspaceId?: string) {
    return this.prisma.notification.findMany({
      where: {
        userId,
        ...(workspaceId ? { workspaceId } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markRead(id: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markAllRead(userId: string, workspaceId?: string) {
    return this.prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
        ...(workspaceId ? { workspaceId } : {}),
      },
      data: { isRead: true, readAt: new Date() },
    });
  }

  create(data: {
    userId: string;
    workspaceId: string;
    type: string;
    title: string;
    body?: string;
    actionUrl?: string;
  }) {
    return this.prisma.notification.create({ data });
  }
}
