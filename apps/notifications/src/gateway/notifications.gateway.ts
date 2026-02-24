import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/notifications' })
export class NotificationsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    // Client sends userId on connect via handshake query
    const userId = client.handshake.query.userId as string;
    if (userId) {
      client.join(`user:${userId}`);
      console.log(`[notifications] client ${client.id} joined user:${userId}`);
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`[notifications] client ${client.id} disconnected`);
  }

  @SubscribeMessage('join:channel')
  joinChannel(
    @ConnectedSocket() client: Socket,
    @MessageBody() channelId: string,
  ) {
    client.join(`channel:${channelId}`);
  }

  emitToUser(userId: string, event: string, data: unknown) {
    this.server.to(`user:${userId}`).emit(event, data);
  }

  emitToChannel(channelId: string, event: string, data: unknown) {
    this.server.to(`channel:${channelId}`).emit(event, data);
  }
}
