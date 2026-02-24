import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { GatewayModule } from './gateway/gateway.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PreferencesModule } from './preferences/preferences.module';
import { EventsController } from './events/events.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    GatewayModule,
    NotificationsModule,
    PreferencesModule,
  ],
  // EventsController은 NATS @EventPattern 핸들러 — HTTP 라우트 없음
  controllers: [EventsController],
})
export class AppModule {}
