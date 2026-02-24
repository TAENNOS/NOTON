import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OllamaService } from '../ollama/ollama.service';

@Injectable()
export class EmbeddingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ollama: OllamaService,
  ) {}

  async store(data: {
    workspaceId: string;
    sourceType: string;
    sourceId: string;
    content: string;
  }) {
    const vector = await this.ollama.embed(data.content);
    // Raw SQL to insert pgvector — Prisma doesn't support vector type natively
    await this.prisma.$executeRaw`
      INSERT INTO "Embedding" (id, "workspaceId", "sourceType", "sourceId", content, embedding, "createdAt")
      VALUES (
        gen_random_uuid()::text,
        ${data.workspaceId},
        ${data.sourceType},
        ${data.sourceId},
        ${data.content},
        ${`[${vector.join(',')}]`}::vector,
        NOW()
      )
      ON CONFLICT DO NOTHING
    `;
    return { stored: true };
  }

  async search(workspaceId: string, query: string, limit = 5) {
    const vector = await this.ollama.embed(query);
    const results = await this.prisma.$queryRaw<
      Array<{ id: string; sourceType: string; sourceId: string; content: string; distance: number }>
    >`
      SELECT id, "sourceType", "sourceId", content,
             embedding <=> ${`[${vector.join(',')}]`}::vector AS distance
      FROM "Embedding"
      WHERE "workspaceId" = ${workspaceId}
      ORDER BY distance
      LIMIT ${limit}
    `;
    return results;
  }
}
