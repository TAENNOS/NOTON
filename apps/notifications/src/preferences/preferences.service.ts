import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertPreferenceDto } from './dto/upsert-preference.dto';

@Injectable()
export class PreferencesService {
  constructor(private readonly prisma: PrismaService) {}

  findByUser(userId: string, workspaceId?: string) {
    return this.prisma.notificationPreference.findMany({
      where: {
        userId,
        ...(workspaceId ? { workspaceId } : {}),
      },
    });
  }

  upsert(userId: string, dto: UpsertPreferenceDto) {
    return this.prisma.notificationPreference.upsert({
      where: {
        userId_workspaceId_type: {
          userId,
          workspaceId: dto.workspaceId,
          type: dto.type,
        },
      },
      create: {
        userId,
        workspaceId: dto.workspaceId,
        type: dto.type,
        enabled: dto.enabled,
      },
      update: { enabled: dto.enabled },
    });
  }
}
