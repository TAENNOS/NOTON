import {
  Controller,
  Get,
  Put,
  Body,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { PreferencesService } from './preferences.service';
import { UpsertPreferenceDto } from './dto/upsert-preference.dto';

@Controller('notifications/preferences')
export class PreferencesController {
  constructor(private readonly preferencesService: PreferencesService) {}

  @Get()
  findAll(
    @Headers('x-user-id') userId: string,
    @Query('workspaceId') workspaceId?: string,
  ) {
    return this.preferencesService.findByUser(userId, workspaceId);
  }

  @Put()
  @HttpCode(HttpStatus.OK)
  upsert(
    @Headers('x-user-id') userId: string,
    @Body() dto: UpsertPreferenceDto,
  ) {
    return this.preferencesService.upsert(userId, dto);
  }
}
