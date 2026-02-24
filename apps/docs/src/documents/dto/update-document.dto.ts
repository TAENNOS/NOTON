import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class UpdateDocumentDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsString()
  coverUrl?: string;

  @IsOptional()
  @IsBoolean()
  isPublic?: boolean;

  /** Serialized Yjs state as base64 string */
  @IsOptional()
  @IsString()
  yjsState?: string;
}
