import { IsBoolean, IsString } from 'class-validator';

export class UpsertPreferenceDto {
  @IsString()
  workspaceId: string;

  @IsString()
  type: string;

  @IsBoolean()
  enabled: boolean;
}
