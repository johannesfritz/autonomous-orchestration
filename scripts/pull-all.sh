#!/bin/bash
# Pull latest changes for all repos (auto-discovery)
# Handles divergent branches gracefully

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
UPDATED=0
UP_TO_DATE=0
MERGED=0
FAILED=0
NO_REMOTE=0

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Pulling all repositories in jf-private                    ║${NC}"
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

    echo -e "${BLUE}Pulling $repo_name...${NC}"

    # Fetch first to check status
    git -C "$repo" fetch origin 2>/dev/null || true

    # Try fast-forward first
    if git -C "$repo" pull --ff-only 2>/dev/null; then
        # Check if anything changed
        if [ "$(git -C "$repo" rev-parse HEAD)" != "$(git -C "$repo" rev-parse @{u} 2>/dev/null || echo 'none')" ] 2>/dev/null; then
            echo -e "${GREEN}✓ $repo_name updated (fast-forward)${NC}"
            ((UPDATED++))
        else
            echo -e "${GREEN}✓ $repo_name (already up to date)${NC}"
            ((UP_TO_DATE++))
        fi
    # If fast-forward fails, try merge (handles divergent branches)
    elif git -C "$repo" pull --no-rebase 2>/dev/null; then
        echo -e "${YELLOW}✓ $repo_name updated (merged divergent branches)${NC}"
        ((MERGED++))
    else
        echo -e "${RED}✗ $repo_name (pull failed - may need manual resolution)${NC}"
        ((FAILED++))
    fi
done

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Updated:      $UPDATED${NC}"
echo -e "${YELLOW}Merged:       $MERGED${NC}"
echo -e "${BLUE}Up to date:   $UP_TO_DATE${NC}"
echo -e "${YELLOW}No remote:    $NO_REMOTE${NC}"
echo -e "${RED}Failed:       $FAILED${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some repos need manual attention!${NC}"
    exit 1
fi

echo -e "${GREEN}Done!${NC}"
