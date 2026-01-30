#!/bin/bash
# Push all repos to their remotes (auto-discovery)
# Only pushes repos with unpushed commits

set -e

cd "$(dirname "$0")/.."
BASE_DIR="$(pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
PUSHED=0
NOTHING_TO_PUSH=0
NO_REMOTE=0
FAILED=0

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Pushing all repositories in jf-private                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Auto-discover all git repos
REPOS=$(find "$BASE_DIR" -name ".git" -type d 2>/dev/null | sort)

for gitdir in $REPOS; do
    repo=$(dirname "$gitdir")
    repo_name="${repo#$BASE_DIR/}"

    # Skip if no remote configured
    if ! git -C "$repo" remote get-url origin &>/dev/null; then
        echo -e "${YELLOW}○ $repo_name (no remote)${NC}"
        ((NO_REMOTE++))
        continue
    fi

    # Check if there are unpushed commits
    LOCAL=$(git -C "$repo" rev-parse HEAD 2>/dev/null)
    REMOTE=$(git -C "$repo" rev-parse @{u} 2>/dev/null || echo "none")

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo -e "${BLUE}○ $repo_name (nothing to push)${NC}"
        ((NOTHING_TO_PUSH++))
        continue
    fi

    # Check if we're ahead of remote
    AHEAD=$(git -C "$repo" rev-list --count @{u}..HEAD 2>/dev/null || echo "0")

    if [ "$AHEAD" = "0" ]; then
        echo -e "${BLUE}○ $repo_name (nothing to push)${NC}"
        ((NOTHING_TO_PUSH++))
        continue
    fi

    echo -e "${BLUE}Pushing $repo_name ($AHEAD commits ahead)...${NC}"

    if git -C "$repo" push 2>/dev/null; then
        echo -e "${GREEN}✓ $repo_name pushed${NC}"
        ((PUSHED++))
    else
        echo -e "${RED}✗ $repo_name (push failed)${NC}"
        ((FAILED++))
    fi
done

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Pushed:           $PUSHED${NC}"
echo -e "${BLUE}Nothing to push:  $NOTHING_TO_PUSH${NC}"
echo -e "${YELLOW}No remote:        $NO_REMOTE${NC}"
echo -e "${RED}Failed:           $FAILED${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some pushes failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Done!${NC}"
