import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { EVENTS, DocUpdatedPayload } from '@noton/shared';
import { PrismaService } from '../prisma/prisma.service';
import { VersionsService } from '../versions/versions.service';
import { CreateDocumentDto } from './dto/create-document.dto';
import { UpdateDocumentDto } from './dto/update-document.dto';

@Injectable()
export class DocumentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly versions: VersionsService,
    @Inject('NATS_SERVICE') private readonly nats: ClientProxy,
  ) {}

  create(dto: CreateDocumentDto) {
    return this.prisma.document.create({
      data: {
        workspaceId: dto.workspaceId,
        parentId: dto.parentId,
        title: dto.title ?? 'Untitled',
        isPublic: dto.isPublic ?? false,
      },
    });
  }

  async findById(id: string) {
    const doc = await this.prisma.document.findUnique({
      where: { id },
      include: { children: { orderBy: { createdAt: 'desc' } } },
    });
    if (!doc) throw new NotFoundException(`Document ${id} not found`);
    return doc;
  }

  findByWorkspace(workspaceId: string) {
    return this.prisma.document.findMany({
      where: { workspaceId, parentId: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(id: string, dto: UpdateDocumentDto, userId: string) {
    const existing = await this.prisma.document.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException(`Document ${id} not found`);

    const data: Record<string, unknown> = {};
    if (dto.title !== undefined) data.title = dto.title;
    if (dto.icon !== undefined) data.icon = dto.icon;
    if (dto.coverUrl !== undefined) data.coverUrl = dto.coverUrl;
    if (dto.isPublic !== undefined) data.isPublic = dto.isPublic;
    if (dto.yjsState !== undefined) {
      data.yjsState = Buffer.from(dto.yjsState, 'base64');
    }

    const doc = await this.prisma.document.update({ where: { id }, data });

    // Snapshot version when yjsState is updated
    if (dto.yjsState) {
      await this.versions.createSnapshot(id, userId);
    }

    // Publish NATS event (fire-and-forget)
    const payload: DocUpdatedPayload = {
      documentId: doc.id,
      workspaceId: doc.workspaceId,
      updatedBy: userId,
    };
    this.nats.emit(EVENTS.DOC_UPDATED, payload).subscribe({
      error: (err: unknown) => console.error('[docs] NATS emit failed:', err),
    });

    return doc;
  }

  delete(id: string) {
    return this.prisma.document.delete({ where: { id } });
  }

  listVersions(documentId: string) {
    return this.versions.findByDocument(documentId);
  }
}
