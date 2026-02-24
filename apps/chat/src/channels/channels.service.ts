import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateChannelDto } from './dto/create-channel.dto';

@Injectable()
export class ChannelsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateChannelDto, userId: string) {
    const channel = await this.prisma.channel.create({
      data: {
        workspaceId: dto.workspaceId,
        name: dto.name,
        description: dto.description,
        isPrivate: dto.isPrivate ?? false,
      },
    });
    // Auto-join creator
    await this.prisma.channelMember.create({
      data: { channelId: channel.id, userId },
    });
    return channel;
  }

  findByWorkspace(workspaceId: string) {
    return this.prisma.channel.findMany({
      where: { workspaceId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findById(id: string) {
    const channel = await this.prisma.channel.findUnique({
      where: { id },
      include: { members: true },
    });
    if (!channel) throw new NotFoundException(`Channel ${id} not found`);
    return channel;
  }

  async join(channelId: string, userId: string) {
    await this.findById(channelId);
    return this.prisma.channelMember.upsert({
      where: { channelId_userId: { channelId, userId } },
      create: { channelId, userId },
      update: {},
    });
  }
}
