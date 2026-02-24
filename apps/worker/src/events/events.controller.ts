import { Controller, Logger } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { EVENTS, FileUploadedPayload } from '@noton/shared';
import { INDEXING_QUEUE } from '../processors/indexing.processor';

@Controller()
export class EventsController {
  private readonly logger = new Logger(EventsController.name);

  constructor(
    @InjectQueue(INDEXING_QUEUE) private readonly indexingQueue: Queue,
  ) {}

  @EventPattern(EVENTS.FILE_UPLOADED)
  async handleFileUploaded(@Payload() data: FileUploadedPayload) {
    this.logger.log(`[worker] file.uploaded → enqueue indexing job for ${data.fileId}`);
    await this.indexingQueue.add('index', data, { attempts: 3, backoff: { type: 'exponential', delay: 1000 } });
  }
}
