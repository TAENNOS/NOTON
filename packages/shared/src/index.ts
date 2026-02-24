// ── Shared Types, DTOs, and Constants for NOTON ─────────────────────────────

// Pagination
export interface PaginationDto {
  page?: number;
  limit?: number;
}

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Common response wrapper
export interface ApiResponse<T = void> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// User
export interface UserDto {
  id: string;
  email: string;
  displayName: string;
  avatarUrl?: string;
  createdAt: string;
}

// JWT Payload
export interface JwtPayload {
  sub: string;       // user id
  email: string;
  iat?: number;
  exp?: number;
}

// Document Block types
export type BlockType =
  | 'paragraph'
  | 'heading1'
  | 'heading2'
  | 'heading3'
  | 'bulletList'
  | 'numberedList'
  | 'todo'
  | 'code'
  | 'quote'
  | 'divider'
  | 'image'
  | 'file'
  | 'embed';

// Chat
export type MessageType = 'text' | 'file' | 'system';

// Events (NATS subjects)
export const EVENTS = {
  USER_CREATED: 'user.created',
  USER_UPDATED: 'user.updated',
  DOC_CREATED: 'doc.created',
  DOC_UPDATED: 'doc.updated',
  MESSAGE_CREATED: 'message.created',
  FILE_UPLOADED: 'file.uploaded',
  NOTIFICATION_SEND: 'notification.send',
} as const;

export type EventType = typeof EVENTS[keyof typeof EVENTS];

// NATS Event Payloads
export interface MessageCreatedPayload {
  channelId: string;
  threadId?: string;
  authorId: string;
  content: string;
  type: MessageType;
}

export interface FileUploadedPayload {
  fileId: string;
  workspaceId: string;
  uploaderId: string;
  mimeType: string;
  bucketKey: string;
}

export interface DocUpdatedPayload {
  documentId: string;
  workspaceId: string;
  updatedBy: string;
}

export interface EmbeddingJobPayload {
  resourceId: string;
  resourceType: 'document' | 'message' | 'file';
  content: string;
}

// Auth
export interface AuthTokensDto {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
