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
import { FilesService } from './files.service';
import { RegisterFileDto } from './dto/register-file.dto';

@Controller('files')
export class FilesController {
  constructor(private readonly filesService: FilesService) {}

  /** Step 1: get presign URL before client uploads to MinIO */
  @Get('presign/upload')
  getUploadPresign(
    @Query('filename') filename: string,
    @Query('mimeType') mimeType: string,
  ) {
    return this.filesService.getUploadPresignUrl(filename, mimeType);
  }

  /** Step 2: after client uploads, register metadata + publish NATS */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  register(
    @Body() dto: RegisterFileDto,
    @Headers('x-user-id') uploaderId: string,
  ) {
    return this.filesService.register(dto, uploaderId ?? 'anonymous');
  }

  @Get()
  findByWorkspace(@Query('workspaceId') workspaceId: string) {
    return this.filesService.findByWorkspace(workspaceId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.filesService.findById(id);
  }

  @Get(':id/download')
  getDownloadPresign(@Param('id') id: string) {
    return this.filesService.getDownloadPresignUrl(id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.filesService.delete(id);
  }
}
