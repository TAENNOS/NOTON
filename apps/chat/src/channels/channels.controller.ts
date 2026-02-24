import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ChannelsService } from './channels.service';
import { CreateChannelDto } from './dto/create-channel.dto';

@Controller('channels')
export class ChannelsController {
  constructor(private readonly channelsService: ChannelsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @Body() dto: CreateChannelDto,
    @Headers('x-user-id') userId: string,
  ) {
    return this.channelsService.create(dto, userId ?? 'anonymous');
  }

  @Get()
  findByWorkspace(@Query('workspaceId') workspaceId: string) {
    return this.channelsService.findByWorkspace(workspaceId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.channelsService.findById(id);
  }

  @Post(':id/join')
  @HttpCode(HttpStatus.OK)
  join(
    @Param('id') id: string,
    @Headers('x-user-id') userId: string,
  ) {
    return this.channelsService.join(id, userId ?? 'anonymous');
  }
}
