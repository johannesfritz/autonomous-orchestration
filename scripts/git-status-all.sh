#!/bin/bash
# Show git status for all repos (auto-discovery)
# Shows uncommitted changes, unpushed commits, and sync status

cd "$(dirname "$0")/.."
BASE_DIR="$(pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
CLEAN=0
DIRTY=0
UNPUSHED=0
NO_REMOTE=0

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Git status for all repositories in jf-private            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Auto-discover all git repos
REPOS=$(find "$BASE_DIR" -name ".git" -type d 2>/dev/null | sort)

for gitdir in $REPOS; do
    repo=$(dirname "$gitdir")
    repo_name="${repo#$BASE_DIR/}"

    # Get status
    STATUS=$(git -C "$repo" status --porcelain 2>/dev/null)

    # Check for remote
    HAS_REMOTE=true
    if ! git -C "$repo" remote get-url origin &>/dev/null; then
        HAS_REMOTE=false
        ((NO_REMOTE++))
    fi

    # Check for unpushed commits
    AHEAD=0
    if [ "$HAS_REMOTE" = true ]; then
        git -C "$repo" fetch origin 2>/dev/null || true
        AHEAD=$(git -C "$repo" rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    fi

    # Determine display
    if [ -z "$STATUS" ] && [ "$AHEAD" = "0" ]; then
        # Clean - just show green checkmark
        if [ "$HAS_REMOTE" = false ]; then
            echo -e "${YELLOW}○ $repo_name ${NC}(no remote)"
        else
            echo -e "${GREEN}✓ $repo_name${NC}"
        fi
        ((CLEAN++))
    else
        # Dirty or has unpushed commits
        echo ""
        echo -e "${BLUE}═══ $repo_name ═══${NC}"

        if [ -n "$STATUS" ]; then
            echo -e "${YELLOW}Uncommitted changes:${NC}"
            echo "$STATUS" | head -20
            LINES=$(echo "$STATUS" | wc -l)
            if [ "$LINES" -gt 20 ]; then
                echo -e "${YELLOW}  ... and $((LINES - 20)) more files${NC}"
            fi
            ((DIRTY++))
        fi

        if [ "$AHEAD" != "0" ]; then
            echo -e "${CYAN}Unpushed commits: $AHEAD${NC}"
            git -C "$repo" log --oneline @{u}..HEAD 2>/dev/null | head -5
            if [ "$AHEAD" -gt 5 ]; then
                echo -e "${CYAN}  ... and $((AHEAD - 5)) more commits${NC}"
            fi
            ((UNPUSHED++))
        fi
    fi
done

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Clean:     $CLEAN${NC}"
echo -e "${YELLOW}Dirty:     $DIRTY${NC}"
echo -e "${CYAN}Unpushed:  $UNPUSHED${NC}"
echo -e "${YELLOW}No remote: $NO_REMOTE${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

if [ $DIRTY -gt 0 ] || [ $UNPUSHED -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Tip: Run ./scripts/push-all.sh to push unpushed commits${NC}"
fi
