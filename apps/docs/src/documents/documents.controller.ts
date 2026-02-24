import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { DocumentsService } from './documents.service';
import { CreateDocumentDto } from './dto/create-document.dto';
import { UpdateDocumentDto } from './dto/update-document.dto';

@Controller('documents')
export class DocumentsController {
  constructor(private readonly documentsService: DocumentsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(
    @Body() dto: CreateDocumentDto,
    @Headers('x-user-id') _userId: string,
  ) {
    return this.documentsService.create(dto);
  }

  @Get()
  findByWorkspace(@Query('workspaceId') workspaceId: string) {
    return this.documentsService.findByWorkspace(workspaceId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.documentsService.findById(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateDocumentDto,
    @Headers('x-user-id') userId: string,
  ) {
    return this.documentsService.update(id, dto, userId ?? 'anonymous');
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.documentsService.delete(id);
  }

  @Get(':id/versions')
  listVersions(@Param('id') id: string) {
    return this.documentsService.listVersions(id);
  }
}
