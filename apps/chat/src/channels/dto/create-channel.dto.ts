import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateChannelDto {
  @IsString()
  workspaceId: string;

  @IsString()
  @MinLength(1)
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsBoolean()
  @IsOptional()
  isPrivate?: boolean;
}
