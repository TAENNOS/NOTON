import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class RegisterFileDto {
  @IsString()
  workspaceId: string;

  @IsString()
  originalName: string;

  @IsString()
  mimeType: string;

  @IsInt()
  @Min(0)
  size: number;

  @IsString()
  bucketKey: string;

  @IsOptional()
  isPublic?: boolean;
}
