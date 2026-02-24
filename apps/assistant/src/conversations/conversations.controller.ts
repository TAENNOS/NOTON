import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
  Res,
} from '@nestjs/common';
import { FastifyReply } from 'fastify';
import { ConversationsService } from './conversations.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { ChatDto } from './dto/chat.dto';

@Controller('conversations')
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @Body() dto: CreateConversationDto,
    @Headers('x-user-id') userId: string,
  ) {
    return this.conversationsService.create(dto, userId ?? 'anonymous');
  }

  @Get()
  findAll(
    @Headers('x-user-id') userId: string,
    @Query('workspaceId') workspaceId?: string,
  ) {
    return this.conversationsService.findByUser(userId, workspaceId);
  }

  @Get(':id/messages')
  getMessages(@Param('id') id: string) {
    return this.conversationsService.getMessages(id);
  }

  /** Streaming SSE endpoint */
  @Post(':id/chat')
  async chat(
    @Param('id') id: string,
    @Body() dto: ChatDto,
    @Res() reply: FastifyReply,
  ) {
    reply.raw.setHeader('Content-Type', 'text/event-stream');
    reply.raw.setHeader('Cache-Control', 'no-cache');
    reply.raw.setHeader('Connection', 'keep-alive');
    reply.raw.flushHeaders();

    try {
      for await (const chunk of this.conversationsService.chat(id, dto.message)) {
        reply.raw.write(`data: ${JSON.stringify({ chunk })}\n\n`);
      }
    } catch (err) {
      reply.raw.write(`data: ${JSON.stringify({ error: String(err) })}\n\n`);
    }
    reply.raw.write('data: [DONE]\n\n');
    reply.raw.end();
  }
}
