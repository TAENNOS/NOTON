import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { IndexingProcessor, INDEXING_QUEUE } from './processors/indexing.processor';
import { EmbeddingsProcessor, EMBEDDINGS_QUEUE } from './processors/embeddings.processor';
import { EventsController } from './events/events.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('REDIS_HOST', 'localhost'),
          port: config.get<number>('REDIS_PORT', 6379),
          password: config.get<string>('REDIS_PASSWORD') || undefined,
        },
      }),
    }),
    BullModule.registerQueue(
      { name: INDEXING_QUEUE },
      { name: EMBEDDINGS_QUEUE },
    ),
  ],
  controllers: [EventsController],
  providers: [IndexingProcessor, EmbeddingsProcessor],
})
export class AppModule {}
