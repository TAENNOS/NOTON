import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: true }),
  );

  const config = app.get(ConfigService);
  const natsUrl = config.get<string>('NATS_URL', 'nats://localhost:4222');

  // NATS microservice for event subscriptions
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.NATS,
    options: { servers: [natsUrl] },
  });

  await app.startAllMicroservices();

  const port = config.get<number>('PORT', 3009);
  await app.listen(port, '0.0.0.0');
  console.log(`[worker] running on port ${port}`);
  console.log(`[worker] NATS subscribed: ${natsUrl}`);
  console.log(`[worker] BullMQ queues: indexing, embeddings`);
}

bootstrap();
