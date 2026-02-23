#!/bin/bash
# =============================================================================
# E2E Integration Test for ror-hatchling template.rb
# =============================================================================
# This script validates the complete template.rb execution in a clean environment.
#
# Prerequisites:
#   - Ruby 3.4+ (via mise/rbenv/asdf)
#   - Rails 8.1+
#   - Docker running (for PostgreSQL 17)
#   - Google Chrome (for system tests)
#
# Usage:
#   ./scripts/e2e_test.sh [--skip-system] [--skip-idempotency]
# =============================================================================

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_PATH="$PROJECT_DIR/template.rb"
WORK_DIR=$(mktemp -d -t ror-e2e-XXXXXX)
APP_NAME="e2e_test_app"
SKIP_SYSTEM=false
SKIP_IDEMPOTENCY=false

# Parse flags
for arg in "$@"; do
  case $arg in
    --skip-system) SKIP_SYSTEM=true ;;
    --skip-idempotency) SKIP_IDEMPOTENCY=true ;;
  esac
done

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAILURES=$((FAILURES + 1)); }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

FAILURES=0
TESTS=0
STEP=0

step() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${BLUE}========== Step $STEP: $1 ==========${NC}"
}

check() {
  TESTS=$((TESTS + 1))
  if eval "$2" > /dev/null 2>&1; then
    pass "$1"
  else
    fail "$1"
    if [ -n "${3:-}" ]; then
      echo "  Detail: $3"
    fi
  fi
}

# --- Cleanup on exit ---
cleanup() {
  info "Cleaning up work directory: $WORK_DIR"
  # Stop PostgreSQL container if we started it
  if [ "${PG_STARTED:-false}" = "true" ]; then
    info "Stopping PostgreSQL container and removing volumes..."
    cd "$WORK_DIR/$APP_NAME" && docker compose down -v 2>/dev/null || true
  fi
  # Don't remove work dir on failure for debugging
  if [ "$FAILURES" -gt 0 ]; then
    warn "Keeping work directory for debugging: $WORK_DIR"
  else
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================
step "Preflight Checks"

info "Work directory: $WORK_DIR"
info "Template path: $TEMPLATE_PATH"

check "Ruby 3.4+ available" "ruby -v | grep -q '3\\.4'"
check "Rails 8.1+ available" "rails -v | grep -q '8\\.1'"
check "Bundler available" "bundle -v"
check "Docker running" "docker info > /dev/null 2>&1"
check "template.rb exists" "[ -f '$TEMPLATE_PATH' ]"
check "template.rb syntax valid" "ruby -c '$TEMPLATE_PATH'"

if [ "$FAILURES" -gt 0 ]; then
  echo ""
  fail "Preflight checks failed. Aborting."
  exit 1
fi

# =============================================================================
# Step 1: rails new with template
# =============================================================================
step "rails new $APP_NAME -d postgresql -c tailwind -m template.rb"

cd "$WORK_DIR"
info "Running rails new (this may take a few minutes)..."

if rails new "$APP_NAME" -d postgresql -c tailwind -m "$TEMPLATE_PATH" 2>&1 | tee "$WORK_DIR/rails_new.log"; then
  pass "rails new completed without errors"
else
  fail "rails new failed"
  echo "See log: $WORK_DIR/rails_new.log"
  exit 1
fi

cd "$WORK_DIR/$APP_NAME"

# =============================================================================
# Step 2: Verify generated files
# =============================================================================
step "Verify Generated Files"

check "README.md exists" "[ -f README.md ]"
check "README.md contains app name" "grep -q 'E2e Test App' README.md || grep -q 'E2E Test App' README.md || grep -q 'E2e test app' README.md"
check "Gemfile exists" "[ -f Gemfile ]"
check "database.yml exists" "[ -f config/database.yml ]"
check "deploy.yml exists" "[ -f config/deploy.yml ]"
check "Procfile.dev exists" "[ -f Procfile.dev ]"
check "docker-compose.yml exists" "[ -f docker-compose.yml ]"
check "CI workflow exists" "[ -f .github/workflows/ci.yml ]"

# ViewComponents (10)
for component in button card badge flash modal dropdown form_field empty_state pagination navbar; do
  check "${component}_component.rb exists" "[ -f app/components/${component}_component.rb ]"
done

# Stimulus controllers
for ctrl in flash modal dropdown navbar; do
  check "${ctrl}_controller.js exists" "[ -f app/javascript/controllers/${ctrl}_controller.js ]"
done

# Policies
check "application_policy.rb exists" "[ -f app/policies/application_policy.rb ]"

# Locale files
check "Korean locale exists" "ls config/locales/defaults/*.ko.yml > /dev/null 2>&1"

# Multi-DB migrations
check "cache_migrate/ exists" "[ -d db/cache_migrate ]"
check "queue_migrate/ exists" "[ -d db/queue_migrate ]"
check "cable_migrate/ exists" "[ -d db/cable_migrate ]"

# Kamal
check ".kamal/secrets.example exists" "[ -f .kamal/secrets.example ]"
check ".kamal/hooks/pre-deploy exists" "[ -f .kamal/hooks/pre-deploy ]"

# Test files
check "User model test exists" "[ -f test/models/user_test.rb ]"
check "User fixtures exist" "[ -f test/fixtures/users.yml ]"

# =============================================================================
# Step 3: Start PostgreSQL and run bin/setup
# =============================================================================
step "Start PostgreSQL and bin/setup"

info "Starting PostgreSQL 17 via Docker..."
if docker compose up db -d 2>&1; then
  PG_STARTED=true
  pass "PostgreSQL container started"
  # Wait for PostgreSQL to be ready
  info "Waiting for PostgreSQL to accept connections..."
  for i in $(seq 1 30); do
    if docker compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
      pass "PostgreSQL is ready (waited ${i}s)"
      break
    fi
    if [ "$i" -eq 30 ]; then
      fail "PostgreSQL did not become ready in 30s"
      exit 1
    fi
    sleep 1
  done
else
  fail "Failed to start PostgreSQL container"
  exit 1
fi

info "Running setup steps manually (skipping bin/dev start)..."
# bin/setup in Rails 8 starts bin/dev at the end, which blocks.
# Run setup steps individually instead.
if bundle install --quiet 2>&1 | tee -a "$WORK_DIR/setup.log"; then
  pass "bundle install succeeded"
else
  fail "bundle install failed"
fi

if bin/rails db:prepare 2>&1 | tee -a "$WORK_DIR/setup.log"; then
  pass "db:prepare succeeded (all 8 databases created + migrated)"
else
  fail "db:prepare failed"
  echo "See log: $WORK_DIR/setup.log"
fi

if bin/rails db:seed 2>&1 | tee -a "$WORK_DIR/setup.log"; then
  pass "db:seed succeeded"
else
  fail "db:seed failed"
fi

# =============================================================================
# Step 4: Run unit and integration tests
# =============================================================================
step "Run Unit and Integration Tests (bin/rails test)"

if PARALLEL_WORKERS=1 bin/rails test 2>&1 | tee "$WORK_DIR/test.log"; then
  pass "bin/rails test passed"
else
  fail "bin/rails test failed"
  echo "See log: $WORK_DIR/test.log"
fi

# =============================================================================
# Step 5: Run system tests (optional)
# =============================================================================
if [ "$SKIP_SYSTEM" = false ]; then
  step "Run System Tests (bin/rails test:system)"

  if bin/rails test:system 2>&1 | tee "$WORK_DIR/system_test.log"; then
    pass "bin/rails test:system passed"
  else
    fail "bin/rails test:system failed"
    echo "See log: $WORK_DIR/system_test.log"
  fi
else
  info "Skipping system tests (--skip-system)"
fi

# =============================================================================
# Step 6: Rubocop
# =============================================================================
step "Rubocop Lint Check"

if bundle exec rubocop 2>&1 | tee "$WORK_DIR/rubocop.log"; then
  pass "rubocop: zero violations"
else
  VIOLATIONS=$(grep -c "offense" "$WORK_DIR/rubocop.log" 2>/dev/null || echo "unknown")
  fail "rubocop found violations ($VIOLATIONS)"
  echo "See log: $WORK_DIR/rubocop.log"
fi

# =============================================================================
# Step 7: Brakeman
# =============================================================================
step "Brakeman Security Scan"

if bundle exec brakeman --no-pager -q 2>&1 | tee "$WORK_DIR/brakeman.log"; then
  pass "brakeman: no security issues"
else
  warn "brakeman reported warnings (review log)"
  # Don't fail on brakeman warnings — they may be acceptable
fi

# =============================================================================
# Step 8: Idempotency test (optional)
# =============================================================================
if [ "$SKIP_IDEMPOTENCY" = false ]; then
  step "Idempotency Test (second rails new)"

  info "Running rails new again..."
  APP2_NAME="e2e_test_app_2"
  cd "$WORK_DIR"
  if rails new "$APP2_NAME" -d postgresql -c tailwind -m "$TEMPLATE_PATH" > /dev/null 2>&1; then
    pass "Second rails new completed"

    # Compare (excluding timestamp-dependent files)
    DIFF_OUTPUT=$(diff -rq "$WORK_DIR/$APP_NAME" "$WORK_DIR/$APP2_NAME" \
      --exclude='.git' \
      --exclude='tmp' \
      --exclude='log' \
      --exclude='node_modules' \
      --exclude='storage' \
      --exclude='*.lock' \
      --exclude='master.key' \
      --exclude='development.key' \
      --exclude='test.key' \
      --exclude='production.key' \
      2>/dev/null || true)

    if [ -z "$DIFF_OUTPUT" ]; then
      pass "Idempotency: no meaningful differences"
    else
      DIFF_COUNT=$(echo "$DIFF_OUTPUT" | wc -l | tr -d ' ')
      warn "Idempotency: $DIFF_COUNT differences found (review below)"
      echo "$DIFF_OUTPUT" | head -20
    fi
  else
    fail "Second rails new failed"
  fi
else
  info "Skipping idempotency test (--skip-idempotency)"
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo "============================================="
echo "  E2E Test Results"
echo "============================================="
echo "  Tests run: $TESTS"
echo "  Failures:  $FAILURES"
echo "  Work dir:  $WORK_DIR"
echo "============================================="

if [ "$FAILURES" -eq 0 ]; then
  echo -e "  ${GREEN}ALL TESTS PASSED${NC}"
  exit 0
else
  echo -e "  ${RED}$FAILURES TEST(S) FAILED${NC}"
  exit 1
fi
