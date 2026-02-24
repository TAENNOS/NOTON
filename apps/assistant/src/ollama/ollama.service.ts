import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Ollama } from 'ollama';

@Injectable()
export class OllamaService {
  private readonly ollama: Ollama;
  readonly model: string;

  constructor(private readonly config: ConfigService) {
    this.ollama = new Ollama({
      host: config.get<string>('OLLAMA_HOST', 'http://localhost:11434'),
    });
    this.model = config.get<string>('OLLAMA_MODEL', 'llama3.2');
  }

  async *streamChat(
    messages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }>,
  ) {
    const stream = await this.ollama.chat({
      model: this.model,
      messages,
      stream: true,
    });
    for await (const chunk of stream) {
      yield chunk.message.content;
    }
  }

  async embed(text: string): Promise<number[]> {
    const res = await this.ollama.embed({ model: this.model, input: text });
    return res.embeddings[0];
  }
}
