import { IsOptional, IsString } from 'class-validator';

export class CreateConversationDto {
  @IsString()
  workspaceId: string;

  @IsString()
  @IsOptional()
  title?: string;
}
