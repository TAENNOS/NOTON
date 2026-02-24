import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  // Express adapter (Socket.IO requires it)
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
  );

  const config = app.get(ConfigService);
  const natsUrl = config.get<string>('NATS_URL', 'nats://localhost:4222');

  // Connect NATS microservice (subscribe to events)
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.NATS,
    options: { servers: [natsUrl] },
  });

  await app.startAllMicroservices();

  const port = config.get<number>('PORT', 3008);
  await app.listen(port);
  console.log(`[notifications] running on port ${port}`);
  console.log(`[notifications] Socket.IO: ws://localhost:${port}/notifications`);
  console.log(`[notifications] NATS subscribed to: ${natsUrl}`);
}

bootstrap();
