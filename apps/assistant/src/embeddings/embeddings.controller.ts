import { Controller, Post, Body, Query, Get } from '@nestjs/common';
import { EmbeddingsService } from './embeddings.service';
import { IsString } from 'class-validator';

class StoreEmbeddingDto {
  @IsString() workspaceId: string;
  @IsString() sourceType: string;
  @IsString() sourceId: string;
  @IsString() content: string;
}

@Controller('embeddings')
export class EmbeddingsController {
  constructor(private readonly embeddingsService: EmbeddingsService) {}

  @Post()
  store(@Body() dto: StoreEmbeddingDto) {
    return this.embeddingsService.store(dto);
  }

  @Get('search')
  search(
    @Query('workspaceId') workspaceId: string,
    @Query('q') query: string,
    @Query('limit') limit?: string,
  ) {
    return this.embeddingsService.search(
      workspaceId,
      query,
      limit ? parseInt(limit, 10) : 5,
    );
  }
}
