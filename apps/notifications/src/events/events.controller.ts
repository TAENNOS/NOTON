import { Controller } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { EVENTS, MessageCreatedPayload } from '@noton/shared';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationsGateway } from '../gateway/notifications.gateway';

@Controller()
export class EventsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly gateway: NotificationsGateway,
  ) {}

  @EventPattern(EVENTS.MESSAGE_CREATED)
  async handleMessageCreated(@Payload() data: MessageCreatedPayload) {
    // Emit real-time event to all clients subscribed to the channel
    this.gateway.emitToChannel(data.channelId, 'message:new', data);
    console.log(`[notifications] message.created in channel ${data.channelId}`);
  }
}
