import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { FileUploadedPayload } from '@noton/shared';

export const INDEXING_QUEUE = 'indexing';

@Processor(INDEXING_QUEUE)
export class IndexingProcessor extends WorkerHost {
  private readonly logger = new Logger(IndexingProcessor.name);

  async process(job: Job<FileUploadedPayload>) {
    const { fileId, bucketKey, mimeType, workspaceId } = job.data;
    this.logger.log(`Indexing file ${fileId} (${mimeType}) from ${bucketKey}`);

    // In production: download from MinIO, extract text, enqueue embeddings job
    // For now: log and mark as done
    this.logger.log(`[indexing] workspace=${workspaceId} file=${fileId} done`);
    return { indexed: true, fileId };
  }
}
