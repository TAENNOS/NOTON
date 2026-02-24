import { Injectable } from '@nestjs/common';
import type { JwtPayload } from '@noton/shared';

interface PresenceUser {
  userId: string;
  email: string;
}

@Injectable()
export class PresenceService {
  // documentId → Map<socketId, PresenceUser>
  private readonly rooms = new Map<string, Map<string, PresenceUser>>();

  join(documentId: string, socketId: string, user: JwtPayload): void {
    if (!this.rooms.has(documentId)) {
      this.rooms.set(documentId, new Map());
    }
    this.rooms.get(documentId)!.set(socketId, {
      userId: user.sub,
      email: user.email,
    });
  }

  leave(documentId: string, socketId: string): void {
    const room = this.rooms.get(documentId);
    if (!room) return;
    room.delete(socketId);
    if (room.size === 0) this.rooms.delete(documentId);
  }

  leaveAll(socketId: string): string[] {
    const affected: string[] = [];
    for (const [docId, room] of this.rooms) {
      if (room.has(socketId)) {
        room.delete(socketId);
        affected.push(docId);
        if (room.size === 0) this.rooms.delete(docId);
      }
    }
    return affected;
  }

  getPresence(documentId: string): PresenceUser[] {
    return [...(this.rooms.get(documentId)?.values() ?? [])];
  }
}
