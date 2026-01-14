#!/usr/bin/env bash
# build-and-push.sh
#
# Local translation of the provided GitHub Actions workflow.
# Builds and pushes 2 images to GHCR:
#   - ghcr.io/<owner>/<repo>:server_<version> and :server_latest (if vX.Y.Z tag)
#   - ghcr.io/<owner>/<repo>:web_<version>    and :web_latest    (if vX.Y.Z tag)
#
# Usage examples:
#   ./build-and-push.sh --repo owner/repo --token "$GHCR_TOKEN" --ref refs/tags/v1.2.3
#   ./build-and-push.sh --repo owner/repo --token "$GHCR_TOKEN"               # defaults to current git tag/branch -> latest
#
# Notes:
# - Requires: docker (with buildx), git
# - Assumes you run it from the repository root (where Dockerfile-server & Dockerfile-web live).

set -euo pipefail

# -------- defaults / args --------
REPO=""
TOKEN=""
REF="${GITHUB_REF:-}"
PLATFORMS="linux/amd64"
BUILDKIT_PROGRESS="plain"
DOCKER_BUILDX_NAME="local-buildx"

usage() {
  cat <<'EOF'
Usage:
  build-and-push.sh --repo owner/repo --token <ghcr_token> [--ref refs/tags/vX.Y.Z] [--platforms linux/amd64] [--no-prune]

Options:
  --repo        GitHub repository in owner/repo form (required)
  --token       GHCR token with package write permissions (required)
  --ref         Git ref, e.g. refs/tags/v1.2.3 (optional; auto-detected if possible)
  --platforms   Docker platforms (default: linux/amd64)
  --no-prune    Skip docker prune steps
EOF
}

DO_PRUNE=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2;;
    --token) TOKEN="${2:-}"; shift 2;;
    --ref) REF="${2:-}"; shift 2;;
    --platforms) PLATFORMS="${2:-}"; shift 2;;
    --no-prune) DO_PRUNE=0; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$REPO" || -z "$TOKEN" ]]; then
  echo "ERROR: --repo and --token are required." >&2
  usage
  exit 1
fi

# -------- step: Check Disk Space --------
echo "==> Check Disk Space"
df -h || true
docker system df || true

# -------- step: Clean up Docker resources --------
if [[ "$DO_PRUNE" -eq 1 ]]; then
  echo "==> Clean up Docker resources"
  docker system prune -af || true
  docker builder prune -af || true
fi

# -------- step: Checkout code --------
# In Actions, checkout pulls repo. Locally we assume you're already in the repo.
# We only sanity-check that we're in a git repo.
echo "==> Verify repository"
git rev-parse --is-inside-work-tree >/dev/null

# -------- step: Set up Docker Buildx (driver-opts network=host) --------
echo "==> Set up Docker Buildx (${DOCKER_BUILDX_NAME})"
if docker buildx inspect "$DOCKER_BUILDX_NAME" >/dev/null 2>&1; then
  docker buildx use "$DOCKER_BUILDX_NAME"
else
  docker buildx create --name "$DOCKER_BUILDX_NAME" --use --driver docker-container \
    --driver-opt network=host >/dev/null
fi
docker buildx inspect --bootstrap >/dev/null

# -------- step: Login to GitHub Container Registry --------
echo "==> Login to GHCR"
# workflow uses: username = github.actor. Locally you can use any GH username; token controls access.
# We'll take the owner part of owner/repo as username by default.
GH_USER="${REPO%%/*}"
echo "$TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin

# -------- step: Extract version from tag --------
# Workflow logic: if GITHUB_REF matches refs/tags/vX.Y.Z -> VERSION=X.Y.Z and IS_VERSION=true else latest/false
if [[ -z "$REF" ]]; then
  # best-effort auto-detect:
  # 1) exact tag on HEAD (prefer vX.Y.Z)
  # 2) otherwise fallback to "latest"
  TAG_ON_HEAD="$(git tag --points-at HEAD | head -n1 || true)"
  if [[ -n "$TAG_ON_HEAD" ]]; then
    REF="refs/tags/$TAG_ON_HEAD"
  else
    REF="refs/heads/$(git rev-parse --abbrev-ref HEAD)"
  fi
fi

VERSION="latest"
IS_VERSION="false"
if [[ "$REF" =~ ^refs/tags/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  VERSION="${BASH_REMATCH[1]}"
  IS_VERSION="true"
fi

echo "==> Ref: $REF"
echo "==> VERSION=$VERSION  IS_VERSION=$IS_VERSION"

# -------- build tags (match workflow's conditional format) --------
IMAGE_BASE="ghcr.io/${REPO}"

SERVER_TAGS=("${IMAGE_BASE}:server_latest")
WEB_TAGS=("${IMAGE_BASE}:web_latest")

if [[ "$IS_VERSION" == "true" ]]; then
  SERVER_TAGS=("${IMAGE_BASE}:server_${VERSION}" "${IMAGE_BASE}:server_latest")
  WEB_TAGS=("${IMAGE_BASE}:web_${VERSION}" "${IMAGE_BASE}:web_latest")
fi

echo "==> Server tags: ${SERVER_TAGS[*]}"
echo "==> Web tags:    ${WEB_TAGS[*]}"

# helper: convert tag array -> repeated --tag args
tag_args() {
  local out=()
  for t in "$@"; do out+=(--tag "$t"); done
  printf '%q ' "${out[@]}"
}

# -------- step: Build and push xiaozhi-server --------
echo "==> Build and push xiaozhi-server (Dockerfile-server)"
# GitHub workflow uses GHA cache. Locally we use a local cache directory to keep behavior similar.
CACHE_DIR=".buildx-cache"
mkdir -p "$CACHE_DIR"

# shellcheck disable=SC2046
docker buildx build \
  --file Dockerfile-server \
  --platform "$PLATFORMS" \
  --push \
  $(tag_args "${SERVER_TAGS[@]}") \
  --build-arg "BUILDKIT_PROGRESS=${BUILDKIT_PROGRESS}" \
  --cache-from "type=local,src=${CACHE_DIR}" \
  --cache-to "type=local,dest=${CACHE_DIR},mode=max" \
  .

# -------- step: Build and push manager-web --------
echo "==> Build and push manager-web (Dockerfile-web)"
# shellcheck disable=SC2046
docker buildx build \
  --file Dockerfile-web \
  --platform "$PLATFORMS" \
  --push \
  $(tag_args "${WEB_TAGS[@]}") \
  --build-arg "BUILDKIT_PROGRESS=${BUILDKIT_PROGRESS}" \
  --cache-from "type=local,src=${CACHE_DIR}" \
  --cache-to "type=local,dest=${CACHE_DIR},mode=max" \
  .

echo "==> Done."
