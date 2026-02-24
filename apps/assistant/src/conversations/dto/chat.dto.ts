import { IsOptional, IsString } from 'class-validator';

export class ChatDto {
  @IsString()
  message: string;

  @IsString()
  @IsOptional()
  workspaceId?: string;
}
