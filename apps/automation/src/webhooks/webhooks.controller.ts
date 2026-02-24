import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { WebhooksService } from './webhooks.service';
import { CreateWebhookDto } from './dto/create-webhook.dto';

@Controller('webhooks')
export class WebhooksController {
  constructor(private readonly webhooksService: WebhooksService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: CreateWebhookDto) {
    return this.webhooksService.create(dto);
  }

  @Get()
  findByWorkspace(@Query('workspaceId') workspaceId: string) {
    return this.webhooksService.findByWorkspace(workspaceId);
  }

  /** Inbound webhook — called by external services */
  @Post(':id/receive')
  @HttpCode(HttpStatus.OK)
  receive(
    @Param('id') id: string,
    @Headers('x-webhook-secret') secret: string,
    @Body() payload: Record<string, unknown>,
  ) {
    return this.webhooksService.receive(id, secret, payload);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.webhooksService.delete(id);
  }
}
