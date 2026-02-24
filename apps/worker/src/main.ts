import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: true }),
  );
  const config = app.get(ConfigService);
  const port = config.get<number>('PORT', 3009);
  await app.listen(port, '0.0.0.0');
  console.log(`[worker] running on port ${port}`);
}

bootstrap();
