import {
  All,
  Controller,
  Req,
  Res,
} from '@nestjs/common';
import { FastifyRequest, FastifyReply } from 'fastify';
import { ConfigService } from '@nestjs/config';

/**
 * Transparent HTTP proxy to n8n.
 * All requests to /n8n/* are forwarded to the n8n instance.
 */
@Controller('n8n')
export class N8nController {
  private readonly n8nUrl: string;

  constructor(private readonly config: ConfigService) {
    this.n8nUrl = config.get<string>('N8N_URL', 'http://localhost:5678');
  }

  @All('*')
  async proxy(@Req() req: FastifyRequest, @Res() reply: FastifyReply) {
    const path = (req.params as { '*': string })['*'] ?? '';
    const url = `${this.n8nUrl}/${path}${req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : ''}`;

    const res = await fetch(url, {
      method: req.method,
      headers: { 'content-type': 'application/json' },
      ...(req.method !== 'GET' && req.method !== 'HEAD' && req.body
        ? { body: JSON.stringify(req.body) }
        : {}),
    });

    const contentType = res.headers.get('content-type') ?? 'application/json';
    const text = await res.text();
    reply.code(res.status).header('content-type', contentType).send(text);
  }
}
