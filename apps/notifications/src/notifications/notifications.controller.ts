import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findAll(
    @Headers('x-user-id') userId: string,
    @Query('workspaceId') workspaceId?: string,
  ) {
    return this.notificationsService.findByUser(userId, workspaceId);
  }

  @Patch(':id/read')
  @HttpCode(HttpStatus.OK)
  markRead(
    @Param('id') id: string,
    @Headers('x-user-id') userId: string,
  ) {
    return this.notificationsService.markRead(id, userId);
  }

  @Patch('read-all')
  @HttpCode(HttpStatus.OK)
  markAllRead(
    @Headers('x-user-id') userId: string,
    @Query('workspaceId') workspaceId?: string,
  ) {
    return this.notificationsService.markAllRead(userId, workspaceId);
  }
}
