import { IsEnum, IsOptional, IsString } from 'class-validator';
import { MessageType } from '@noton/shared';

export class CreateMessageDto {
  @IsString()
  content: string;

  @IsEnum(['text', 'file', 'system'])
  @IsOptional()
  type?: MessageType;

  @IsString()
  @IsOptional()
  threadId?: string;
}
