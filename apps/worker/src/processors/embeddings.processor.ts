import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { EmbeddingJobPayload } from '@noton/shared';

export const EMBEDDINGS_QUEUE = 'embeddings';

@Processor(EMBEDDINGS_QUEUE)
export class EmbeddingsProcessor extends WorkerHost {
  private readonly logger = new Logger(EmbeddingsProcessor.name);

  async process(job: Job<EmbeddingJobPayload>) {
    const { resourceId, resourceType, content } = job.data;
    this.logger.log(
      `Generating embeddings for ${resourceType}:${resourceId} (${content.length} chars)`,
    );
    // In production: call Ollama embed API, store in pgvector
    this.logger.log(`[embeddings] ${resourceType}:${resourceId} done`);
    return { embedded: true, resourceId };
  }
}
