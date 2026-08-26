#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# deploy.sh — Zero-downtime rolling deploy of Flutter Web to AWS ECS
# Usage:
#   ./deploy.sh              → normal deploy (uses Docker cache)
#   ./deploy.sh --no-cache   → force full rebuild
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
DIM="\033[2m"

ok()   { echo -e "  ${GREEN}✔${RESET}  $1"; }
info() { echo -e "  ${CYAN}→${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
fail() { echo -e "  ${RED}✘${RESET}  $1"; exit 1; }
step() { echo -e "\n${BOLD}${CYAN}[$1/7]${RESET} ${BOLD}$2${RESET}"; }
divider() { echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"; }

# ── Config ────────────────────────────────────────────────────────────────────
export AWS_REGION="${AWS_REGION:-us-east-1}"
export ECR_REGISTRY="${ECR_REGISTRY:-953216550294.dkr.ecr.us-east-1.amazonaws.com}"
export ECR_REPOSITORY="${ECR_REPOSITORY:-fastway-fastway-frontend}"
export ECS_CLUSTER="${ECS_CLUSTER:-fastway-cluster}"
export ECS_SERVICE="${ECS_SERVICE:-fastway-fastway-frontend-service}"
export ECS_TASK_FAMILY="${ECS_TASK_FAMILY:-fastway-fastway-frontend}"
export CONTAINER_NAME="${CONTAINER_NAME:-fastway-frontend}"
export IMAGE_TAG="deploy-$(date +%s)"
# API base URL — override for Main branch:
#   BASE_URL=https://fastway.atwdemo.com/api/v1 ./deploy.sh
# Defaults to the AWS branch (admin.fastwayprotein.com) if not set.
export BASE_URL="${BASE_URL:-https://admin.fastwayprotein.com/api/v1}"

NO_CACHE=""
if [[ "${1:-}" == "--no-cache" ]]; then
  NO_CACHE="--no-cache"
  warn "Building with --no-cache (full rebuild)"
fi

# ── Header ────────────────────────────────────────────────────────────────────
divider
echo -e "${BOLD}  📱  Fastway Flutter Web — ECS Deploy${RESET}"
echo -e "  ${DIM}Cluster : ${ECS_CLUSTER}${RESET}"
echo -e "  ${DIM}Service : ${ECS_SERVICE}${RESET}"
echo -e "  ${DIM}Image   : ${IMAGE_TAG}${RESET}"
divider

# ── Step 1: ECR Login ─────────────────────────────────────────────────────────
step 1 "Logging in to Amazon ECR"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY" 2>&1 \
  | grep -v "WARNING" || true
ok "ECR login successful"

# ── Step 2: Build & Push ──────────────────────────────────────────────────────
step 2 "Building & pushing Docker image"
info "Building Flutter web release inside Docker..."
info "Image: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
docker build $NO_CACHE \
  --build-arg BASE_URL="$BASE_URL" \
  -t "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" . \
  || fail "Docker build failed"
ok "Flutter web built and image created"

info "Pushing to ECR..."
docker push "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" \
  || fail "Docker push failed"
ok "Image pushed: $IMAGE_TAG"

# ── Step 3: Fetch live task definition ────────────────────────────────────────
step 3 "Fetching live task definition from AWS"
export OLD_REVISION
OLD_REVISION=$(aws ecs describe-task-definition \
  --task-definition "$ECS_TASK_FAMILY" \
  --region "$AWS_REGION" \
  --query 'taskDefinition.revision' \
  --output text 2>/dev/null || echo "1")
info "Current active revision: ${BOLD}$OLD_REVISION${RESET}"

aws ecs describe-task-definition \
  --task-definition "$ECS_TASK_FAMILY" \
  --region "$AWS_REGION" \
  --query 'taskDefinition' \
  --output json \
  | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)' \
  > /tmp/live-frontend-task-def.json
ok "Task definition fetched"

# ── Step 4: Inject new image tag ──────────────────────────────────────────────
step 4 "Injecting new image tag into task definition"
jq --arg img "$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" \
   --arg cname "$CONTAINER_NAME" \
   '(.containerDefinitions[] | select(.name == $cname).image) = $img' \
   /tmp/live-frontend-task-def.json > /tmp/new-frontend-task-def.json
ok "Container image updated → $IMAGE_TAG"

# ── Step 5: Register new task definition ─────────────────────────────────────
step 5 "Registering new task definition"
export NEW_ARN
NEW_ARN=$(aws ecs register-task-definition \
  --cli-input-json file:///tmp/new-frontend-task-def.json \
  --region "$AWS_REGION" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)
export NEW_REVISION
NEW_REVISION=$(echo "$NEW_ARN" | awk -F: '{print $NF}')
ok "New revision registered: ${BOLD}$NEW_REVISION${RESET}"

# ── Step 6: Update ECS service ────────────────────────────────────────────────
step 6 "Updating ECS service → revision $NEW_REVISION"
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --task-definition "$ECS_TASK_FAMILY:$NEW_REVISION" \
  --region "$AWS_REGION" \
  --no-cli-pager > /dev/null
ok "Service update triggered"

# ── Step 7: Wait for stable ───────────────────────────────────────────────────
step 7 "Waiting for deployment to stabilize..."
info "Flutter web builds are fast — this should take ~1-2 minutes."
aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --region "$AWS_REGION" \
  || fail "Deployment failed! Service did not stabilize. Check ECS events."
ok "Service is stable and healthy ✅"

# ── Optional: deregister old revision ────────────────────────────────────────
echo ""
read -p "  Deregister old revision ${OLD_REVISION}? (y/N) " DEREGISTER
if [[ "$DEREGISTER" == "y" || "$DEREGISTER" == "Y" ]]; then
  aws ecs deregister-task-definition \
    --task-definition "$ECS_TASK_FAMILY:$OLD_REVISION" \
    --region "$AWS_REGION" \
    --no-cli-pager > /dev/null
  ok "Revision $OLD_REVISION deregistered"
else
  info "Skipped — revision $OLD_REVISION still exists"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
divider
echo -e "${BOLD}${GREEN}  ✅  Flutter Deploy Complete!${RESET}"
echo -e "  ${DIM}Old revision : $OLD_REVISION${RESET}"
echo -e "  ${DIM}New revision : $NEW_REVISION${RESET}"
echo -e "  ${DIM}Image tag    : $IMAGE_TAG${RESET}"
divider
echo ""
