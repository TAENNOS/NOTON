import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class VersionsService {
  constructor(private readonly prisma: PrismaService) {}

  async createSnapshot(documentId: string, createdBy: string) {
    const doc = await this.prisma.document.findUnique({
      where: { id: documentId },
      select: { yjsState: true },
    });
    if (!doc?.yjsState) return null;
    return this.prisma.version.create({
      data: { documentId, yjsState: doc.yjsState, createdBy },
    });
  }

  findByDocument(documentId: string) {
    return this.prisma.version.findMany({
      where: { documentId },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: { id: true, documentId: true, createdBy: true, createdAt: true },
    });
  }
}
