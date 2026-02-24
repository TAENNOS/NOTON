import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OllamaService } from '../ollama/ollama.service';
import { EmbeddingsService } from '../embeddings/embeddings.service';
import { CreateConversationDto } from './dto/create-conversation.dto';

@Injectable()
export class ConversationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ollama: OllamaService,
    private readonly embeddings: EmbeddingsService,
  ) {}

  create(dto: CreateConversationDto, userId: string) {
    return this.prisma.conversation.create({
      data: { workspaceId: dto.workspaceId, userId, title: dto.title },
    });
  }

  findByUser(userId: string, workspaceId?: string) {
    return this.prisma.conversation.findMany({
      where: { userId, ...(workspaceId ? { workspaceId } : {}) },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async getMessages(conversationId: string) {
    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!conv) throw new NotFoundException(`Conversation ${conversationId} not found`);
    return conv.messages;
  }

  async *chat(conversationId: string, userMessage: string) {
    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { messages: { orderBy: { createdAt: 'asc' }, take: 20 } },
    });
    if (!conv) throw new NotFoundException(`Conversation ${conversationId} not found`);

    // Save user message
    await this.prisma.conversationMessage.create({
      data: { conversationId, role: 'user', content: userMessage },
    });

    // RAG: fetch relevant context from embeddings
    let systemContext = '';
    try {
      const results = await this.embeddings.search(conv.workspaceId, userMessage, 3);
      if (results.length > 0) {
        systemContext =
          'Relevant context:\n' + results.map((r) => r.content).join('\n\n') + '\n\n';
      }
    } catch {
      // Embeddings unavailable — proceed without RAG
    }

    const messages = [
      ...(systemContext
        ? [{ role: 'system' as const, content: systemContext }]
        : []),
      ...conv.messages.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user' as const, content: userMessage },
    ];

    // Stream response
    let fullResponse = '';
    for await (const chunk of this.ollama.streamChat(messages)) {
      fullResponse += chunk;
      yield chunk;
    }

    // Save assistant message
    await this.prisma.conversationMessage.create({
      data: { conversationId, role: 'assistant', content: fullResponse },
    });
    // Update conversation timestamp
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });
  }
}
