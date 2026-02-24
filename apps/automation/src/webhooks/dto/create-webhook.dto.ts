import { IsOptional, IsString, MinLength } from 'class-validator';

export class CreateWebhookDto {
  @IsString()
  workspaceId: string;

  @IsString()
  @MinLength(1)
  name: string;

  @IsString()
  @IsOptional()
  n8nWorkflowId?: string;
}
