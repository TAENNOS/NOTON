import { Module } from '@nestjs/common';
import { OllamaModule } from '../ollama/ollama.module';
import { EmbeddingsModule } from '../embeddings/embeddings.module';
import { ConversationsController } from './conversations.controller';
import { ConversationsService } from './conversations.service';

@Module({
  imports: [OllamaModule, EmbeddingsModule],
  controllers: [ConversationsController],
  providers: [ConversationsService],
})
export class ConversationsModule {}
