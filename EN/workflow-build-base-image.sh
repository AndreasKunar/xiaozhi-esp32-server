#!/usr/bin/env bash
# build-base-image.sh
#
# Local equivalent of `.github/workflows/build-base-image.yml`
# Builds and pushes:
#   ghcr.io/<owner>/<repo>:server-base
#
# Usage:
#   ./build-base-image.sh --repo owner/repo --token "$GHCR_TOKEN"
#
# Requirements:
#   docker (with buildx), git

set -euo pipefail

# -------- args --------
REPO=""
TOKEN=""
PLATFORMS="linux/amd64"
BUILDKIT_PROGRESS="plain"
BUILDX_NAME="base-image-buildx"

usage() {
  cat <<'EOF'
Usage:
  build-base-image.sh --repo owner/repo --token <ghcr_token>

Options:
  --repo    GitHub repository in owner/repo form (required)
  --token   GHCR token with write:packages permission (required)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)  REPO="${2:-}"; shift 2;;
    --token) TOKEN="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$REPO" || -z "$TOKEN" ]]; then
  echo "ERROR: --repo and --token are required"
  usage
  exit 1
fi

IMAGE="ghcr.io/${REPO}:server-base"
CACHE_DIR=".buildx-cache-server-base"

# -------- step: Checkout code --------
# GitHub Actions clones the repo. Locally we assume you're already in it.
echo "==> Verify git repository"
git rev-parse --is-inside-work-tree >/dev/null

# -------- step: Set up Docker Buildx --------
echo "==> Set up Docker Buildx ($BUILDX_NAME)"
if docker buildx inspect "$BUILDX_NAME" >/dev/null 2>&1; then
  docker buildx use "$BUILDX_NAME"
else
  docker buildx create --name "$BUILDX_NAME" --use --driver docker-container >/dev/null
fi
docker buildx inspect --bootstrap >/dev/null

# -------- step: Login to GHCR --------
echo "==> Login to ghcr.io"
GH_USER="${REPO%%/*}"
echo "$TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin

# -------- step: Build and push server-base --------
echo "==> Build and push ${IMAGE}"
mkdir -p "$CACHE_DIR"

docker buildx build \
  --file Dockerfile-server-base \
  --platform "$PLATFORMS" \
  --push \
  --tag "$IMAGE" \
  --build-arg "BUILDKIT_PROGRESS=${BUILDKIT_PROGRESS}" \
  --cache-from "type=local,src=${CACHE_DIR}" \
  --cache-to "type=local,dest=${CACHE_DIR},mode=max" \
  .

# -------- step: Output image info --------
echo "✅ Base image built and pushed successfully!"
echo "📦 Tag: ${IMAGE}"
