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
} from '@nestjs/common';
import { MessagesService } from './messages.service';
import { CreateMessageDto } from './dto/create-message.dto';

@Controller('channels/:channelId')
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Post('messages')
  @HttpCode(HttpStatus.CREATED)
  createMessage(
    @Param('channelId') channelId: string,
    @Body() dto: CreateMessageDto,
    @Headers('x-user-id') authorId: string,
  ) {
    return this.messagesService.create(channelId, dto, authorId ?? 'anonymous');
  }

  @Get('messages')
  findMessages(
    @Param('channelId') channelId: string,
    @Query('threadId') threadId?: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.messagesService.findByChannel(
      channelId,
      threadId,
      cursor,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  @Post('threads')
  @HttpCode(HttpStatus.CREATED)
  createThread(@Param('channelId') channelId: string) {
    return this.messagesService.createThread(channelId);
  }
}
