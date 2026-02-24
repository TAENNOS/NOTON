import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateWorkspaceDto } from './dto/create-workspace.dto';

@Injectable()
export class WorkspacesService {
  constructor(private readonly prisma: PrismaService) {}

  create(dto: CreateWorkspaceDto) {
    return this.prisma.workspace.create({ data: dto });
  }

  findAll() {
    return this.prisma.workspace.findMany({ orderBy: { createdAt: 'desc' } });
  }

  findById(id: string) {
    return this.prisma.workspace.findUnique({
      where: { id },
      include: {
        documents: {
          where: { parentId: null },
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }
}
