#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NOTON — Oracle Cloud Free Tier ARM VM 초기 설치 스크립트
#
# 실행 환경: Ubuntu 22.04 (ARM64) — Oracle Cloud Ampere A1
#
# 사용법:
#   1. Oracle Cloud에서 VM 생성 (아래 '준비 사항' 참고)
#   2. SSH 접속:  ssh ubuntu@YOUR_VM_IP
#   3. 스크립트 복사:  scp infra/scripts/setup-oracle.sh ubuntu@YOUR_VM_IP:~
#   4. 실행:  chmod +x setup-oracle.sh && ./setup-oracle.sh
# ─────────────────────────────────────────────────────────────────────────────
# 준비 사항 (Oracle Cloud Console):
#   - Shape: VM.Standard.A1.Flex  (Ampere ARM)
#   - OCPU: 4,  Memory: 24 GB
#   - OS: Canonical Ubuntu 22.04 Minimal aarch64
#   - Network: 퍼블릭 IP 할당
#   - Security List 인바운드 규칙 추가:
#       TCP 22   (SSH)
#       TCP 80   (HTTP / Flutter Web)
#       TCP 9000 (MinIO API — presigned URL)
#       TCP 9001 (MinIO Console)
#       TCP 5678 (n8n)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_URL="https://github.com/TAENNOS/NOTON.git"
REPO_DIR="$HOME/NOTON"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# ── 1. 시스템 패키지 ───────────────────────────────────────────────────────────
info "시스템 패키지 업데이트"
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y git curl wget unzip apt-transport-https ca-certificates gnupg lsb-release

# ── 2. Docker 설치 ────────────────────────────────────────────────────────────
info "Docker 설치"
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  info "Docker 설치 완료. 그룹 적용을 위해 재로그인이 필요합니다."
  info "  → sudo -u $USER -i 로 새 셸을 열거나, 아래 명령으로 계속 진행:"
  info "     newgrp docker && bash setup-oracle.sh"
  warn "지금은 sudo docker로 실행을 계속합니다."
  DOCKER_CMD="sudo docker"
else
  info "Docker 이미 설치됨"
  DOCKER_CMD="docker"
fi

# Docker Compose plugin 확인
if ! $DOCKER_CMD compose version &> /dev/null; then
  info "Docker Compose plugin 설치"
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  COMPOSE_VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-linux-aarch64" \
    -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
fi

# ── 3. 레포지토리 클론 ────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  info "레포지토리 이미 존재 — git pull"
  git -C "$REPO_DIR" pull
else
  info "레포지토리 클론: $REPO_URL"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# ── 4. .env.prod 설정 ────────────────────────────────────────────────────────
ENV_FILE="$REPO_DIR/infra/docker/.env.prod"
if [ ! -f "$ENV_FILE" ]; then
  cp "$REPO_DIR/infra/docker/.env.prod.example" "$ENV_FILE"
  warn "══════════════════════════════════════════════════════════"
  warn " .env.prod 파일을 편집해서 비밀번호/시크릿을 설정하세요!"
  warn "  nano $ENV_FILE"
  warn "══════════════════════════════════════════════════════════"
  warn "편집 완료 후 이 스크립트를 다시 실행하거나 아래 명령을 실행:"
  warn "  cd $REPO_DIR && bash infra/scripts/deploy.sh"
  exit 0
fi

# SERVER_IP 자동 설정 (비어 있으면)
PUBLIC_IP=$(curl -s https://ipv4.icanhazip.com || curl -s https://api.ipify.org)
if grep -q "YOUR_ORACLE_VM_IP" "$ENV_FILE"; then
  sed -i "s/YOUR_ORACLE_VM_IP/$PUBLIC_IP/g" "$ENV_FILE"
  info "SERVER_IP 자동 설정: $PUBLIC_IP"
fi

# ── 5. Flutter 설치 (ARM64) ───────────────────────────────────────────────────
info "Flutter 설치 확인"
if ! command -v flutter &> /dev/null; then
  info "Flutter SDK 설치 (ARM64)"
  FLUTTER_VER="3.27.4"   # stable
  cd /tmp
  wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VER}-stable.tar.xz" \
    -O flutter.tar.xz
  sudo tar xf flutter.tar.xz -C /opt/
  sudo chown -R "$USER" /opt/flutter
  echo 'export PATH="$PATH:/opt/flutter/bin"' >> "$HOME/.bashrc"
  export PATH="$PATH:/opt/flutter/bin"
  flutter precache --web
  info "Flutter 설치 완료"
fi

# ── 6. Flutter Web 빌드 ───────────────────────────────────────────────────────
info "Flutter Web 빌드"
export PATH="$PATH:/opt/flutter/bin"
PUBLIC_IP=$(grep "^SERVER_IP=" "$ENV_FILE" | cut -d= -f2)
cd "$REPO_DIR/apps/web"
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=http://${PUBLIC_IP}/api"
info "Flutter Web 빌드 완료 → apps/web/build/web/"

# ── 7. MinIO 버킷 생성 ────────────────────────────────────────────────────────
create_minio_bucket() {
  local access_key password bucket
  access_key=$(grep "^MINIO_ACCESS_KEY=" "$ENV_FILE" | cut -d= -f2)
  password=$(grep "^MINIO_SECRET_KEY=" "$ENV_FILE" | cut -d= -f2)
  bucket=$(grep "^MINIO_BUCKET=" "$ENV_FILE" | cut -d= -f2)

  info "MinIO 버킷 생성: $bucket"
  $DOCKER_CMD compose -f "$REPO_DIR/infra/docker/docker-compose.prod.yml" \
    --env-file "$ENV_FILE" \
    exec -T minio sh -c \
    "mc alias set local http://localhost:9000 $access_key $password && \
     mc mb --ignore-existing local/$bucket && \
     mc anonymous set download local/$bucket" 2>/dev/null || \
    warn "버킷 생성 실패 — 서비스 시작 후 수동으로 실행하세요"
}

# ── 8. Docker Compose 실행 ────────────────────────────────────────────────────
info "Docker Compose 빌드 & 실행 (시간이 걸립니다...)"
cd "$REPO_DIR"
$DOCKER_CMD compose \
  -f infra/docker/docker-compose.prod.yml \
  --env-file infra/docker/.env.prod \
  up -d --build

info "MinIO 초기화 대기 (30초)..."
sleep 30
create_minio_bucket

# ── 9. Ollama 모델 다운로드 ───────────────────────────────────────────────────
OLLAMA_MODEL=$(grep "^OLLAMA_MODEL=" "$ENV_FILE" | cut -d= -f2)
info "Ollama 모델 다운로드: $OLLAMA_MODEL (몇 분 소요)"
$DOCKER_CMD compose \
  -f infra/docker/docker-compose.prod.yml \
  --env-file infra/docker/.env.prod \
  exec -T ollama ollama pull "$OLLAMA_MODEL" || \
  warn "Ollama 모델 다운로드 실패 — 나중에 수동으로 실행:"
  warn "  docker exec noton-ollama ollama pull $OLLAMA_MODEL"

# ── 완료 ─────────────────────────────────────────────────────────────────────
echo ""
info "══════════════════════════════════════════════════════"
info " NOTON 배포 완료!"
info ""
info " Flutter Web:    http://${PUBLIC_IP}"
info " API:            http://${PUBLIC_IP}/api"
info " MinIO Console:  http://${PUBLIC_IP}:9001"
info " n8n:            http://${PUBLIC_IP}:5678"
info ""
info " 서비스 상태:    docker compose -f $REPO_DIR/infra/docker/docker-compose.prod.yml ps"
info " 로그:           docker compose -f $REPO_DIR/infra/docker/docker-compose.prod.yml logs -f"
info "══════════════════════════════════════════════════════"
