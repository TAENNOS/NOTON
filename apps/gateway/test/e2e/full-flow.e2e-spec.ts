/**
 * NOTON 전체 서비스 E2E 테스트
 *
 * 사전 조건:
 *   - 인프라: docker compose -f infra/docker/docker-compose.dev.yml up -d
 *   - 서비스: pnpm dev (모든 서비스 실행 중)
 *
 * 실행:
 *   pnpm --filter @noton/gateway test:e2e
 */

import axios, { AxiosInstance } from 'axios';

const BASE = process.env.GATEWAY_URL ?? 'http://localhost:3000';
const TEST_EMAIL = `e2e_${Date.now()}@noton.test`;
const TEST_PASSWORD = 'E2eTest1234!';
const TEST_DISPLAY_NAME = 'E2E 테스터';

let api: AxiosInstance;
let accessToken: string;
let workspaceId: string;
let documentId: string;
let channelId: string;
let conversationId: string;

beforeAll(() => {
  api = axios.create({
    baseURL: BASE,
    validateStatus: () => true, // 모든 상태 코드 허용 (직접 assert)
  });
});

// ─────────────────────────────────────────────
// 1. 인증 (Auth)
// ─────────────────────────────────────────────

describe('Auth', () => {
  test('POST /api/identity/auth/register — 회원가입', async () => {
    const res = await api.post('/api/identity/auth/register', {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      displayName: TEST_DISPLAY_NAME,
    });
    expect(res.status).toBe(201);
    expect(res.data).toHaveProperty('accessToken');
    accessToken = res.data.accessToken;
    api.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
  });

  test('POST /api/identity/auth/login — 로그인', async () => {
    const res = await api.post('/api/identity/auth/login', {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    });
    expect(res.status).toBe(200);
    expect(res.data).toHaveProperty('accessToken');
    accessToken = res.data.accessToken;
    api.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
  });

  test('GET /api/identity/auth/me — 내 정보 조회', async () => {
    const res = await api.get('/api/identity/auth/me');
    expect(res.status).toBe(200);
    expect(res.data.email).toBe(TEST_EMAIL);
    expect(res.data.displayName).toBe(TEST_DISPLAY_NAME);
  });
});

// ─────────────────────────────────────────────
// 2. 문서 — 워크스페이스
// ─────────────────────────────────────────────

describe('Docs — Workspace', () => {
  test('POST /api/docs/workspaces — 워크스페이스 생성', async () => {
    const slug = `e2e-${Date.now()}`;
    const res = await api.post('/api/docs/workspaces', {
      name: 'E2E 워크스페이스',
      slug,
    });
    expect(res.status).toBe(201);
    expect(res.data).toHaveProperty('id');
    workspaceId = res.data.id;
  });

  test('GET /api/docs/workspaces — 목록 조회', async () => {
    const res = await api.get('/api/docs/workspaces');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
    expect(res.data.some((ws: any) => ws.id === workspaceId)).toBe(true);
  });

  test('GET /api/docs/workspaces/:id — 단건 조회', async () => {
    const res = await api.get(`/api/docs/workspaces/${workspaceId}`);
    expect(res.status).toBe(200);
    expect(res.data.id).toBe(workspaceId);
  });
});

// ─────────────────────────────────────────────
// 3. 문서 — Document
// ─────────────────────────────────────────────

describe('Docs — Document', () => {
  test('POST /api/docs/documents — 문서 생성', async () => {
    const res = await api.post('/api/docs/documents', {
      workspaceId,
      title: 'E2E 테스트 문서',
    });
    expect(res.status).toBe(201);
    expect(res.data).toHaveProperty('id');
    documentId = res.data.id;
  });

  test('GET /api/docs/documents — 목록 조회', async () => {
    const res = await api.get(`/api/docs/documents?workspaceId=${workspaceId}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  test('GET /api/docs/documents/:id — 단건 조회', async () => {
    const res = await api.get(`/api/docs/documents/${documentId}`);
    expect(res.status).toBe(200);
    expect(res.data.id).toBe(documentId);
  });

  test('PATCH /api/docs/documents/:id — 문서 수정', async () => {
    const res = await api.patch(`/api/docs/documents/${documentId}`, {
      title: 'E2E 수정된 문서',
    });
    expect(res.status).toBe(200);
    expect(res.data.title).toBe('E2E 수정된 문서');
  });
});

// ─────────────────────────────────────────────
// 4. 채팅 — Channel & Message
// ─────────────────────────────────────────────

describe('Chat — Channel & Message', () => {
  test('POST /api/chat/channels — 채널 생성', async () => {
    const res = await api.post('/api/chat/channels', {
      workspaceId,
      name: 'e2e-general',
    });
    expect(res.status).toBe(201);
    expect(res.data).toHaveProperty('id');
    channelId = res.data.id;
  });

  test('GET /api/chat/channels — 목록 조회', async () => {
    const res = await api.get(`/api/chat/channels?workspaceId=${workspaceId}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  test('POST /api/chat/channels/:id/join — 채널 참가', async () => {
    const res = await api.post(`/api/chat/channels/${channelId}/join`);
    expect([200, 201]).toContain(res.status);
  });

  test('POST /api/chat/channels/:channelId/messages — 메시지 전송', async () => {
    const res = await api.post(`/api/chat/channels/${channelId}/messages`, {
      content: 'E2E 테스트 메시지입니다.',
    });
    expect(res.status).toBe(201);
    expect(res.data).toHaveProperty('id');
  });

  test('GET /api/chat/channels/:channelId/messages — 메시지 조회', async () => {
    const res = await api.get(`/api/chat/channels/${channelId}/messages`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
    expect(res.data.length).toBeGreaterThan(0);
  });
});

// ─────────────────────────────────────────────
// 5. 파일
// ─────────────────────────────────────────────

describe('Files', () => {
  test('GET /api/files/files/presign/upload — 업로드 presign URL 발급', async () => {
    const res = await api.get(
      '/api/files/files/presign/upload?filename=test.txt&contentType=text/plain',
    );
    expect(res.status).toBe(200);
    expect(res.data).toHaveProperty('url');
    expect(res.data).toHaveProperty('key');
  });
});

// ─────────────────────────────────────────────
// 6. AI 어시스턴트
// ─────────────────────────────────────────────

describe('Assistant', () => {
  test('POST /api/assistant/conversations — 대화 생성', async () => {
    const res = await api.post('/api/assistant/conversations', {
      workspaceId,
      title: 'E2E AI 대화',
    });
    expect(res.status).toBe(201);
    expect(res.data).toHaveProperty('id');
    conversationId = res.data.id;
  });

  test('GET /api/assistant/conversations — 목록 조회', async () => {
    const res = await api.get('/api/assistant/conversations');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  test('GET /api/assistant/conversations/:id/messages — 메시지 조회', async () => {
    const res = await api.get(
      `/api/assistant/conversations/${conversationId}/messages`,
    );
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
  });
});

// ─────────────────────────────────────────────
// 7. 알림
// ─────────────────────────────────────────────

describe('Notifications', () => {
  test('GET /api/notifications/notifications — 알림 목록 조회', async () => {
    const res = await api.get('/api/notifications/notifications');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  test('GET /api/notifications/notifications/preferences — 알림 설정 조회', async () => {
    const res = await api.get(
      '/api/notifications/notifications/preferences',
    );
    expect(res.status).toBe(200);
  });
});

// ─────────────────────────────────────────────
// 8. 정리
// ─────────────────────────────────────────────

describe('Cleanup', () => {
  test('DELETE /api/docs/documents/:id — 문서 삭제', async () => {
    const res = await api.delete(`/api/docs/documents/${documentId}`);
    expect([200, 204]).toContain(res.status);
  });
});
