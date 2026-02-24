import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: true }),
  );
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
  );
  const config = app.get(ConfigService);
  const port = config.get<number>('PORT', 3007);
  await app.listen(port, '0.0.0.0');
  console.log(`[assistant] running on port ${port}`);
  console.log(`[assistant] Ollama model: ${config.get('OLLAMA_MODEL', 'llama3.2')}`);
}

bootstrap();
