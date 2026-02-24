import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class CreateDocumentDto {
  @IsString()
  workspaceId: string;

  @IsOptional()
  @IsString()
  parentId?: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;
}
