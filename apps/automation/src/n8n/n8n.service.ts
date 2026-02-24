import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class N8nService {
  private readonly n8nUrl: string;

  constructor(private readonly config: ConfigService) {
    this.n8nUrl = config.get<string>('N8N_URL', 'http://localhost:5678');
  }

  async proxy(path: string, method: string, body?: unknown, headers?: Record<string, string>) {
    const url = `${this.n8nUrl}${path}`;
    const res = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const text = await res.text();
    try {
      return JSON.parse(text);
    } catch {
      return { raw: text };
    }
  }
}
