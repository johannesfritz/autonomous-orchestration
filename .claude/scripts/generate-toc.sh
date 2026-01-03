#!/bin/bash
# .claude/scripts/generate-toc.sh
# Manual TOC generation for all documentation files

set -e

echo "Generating TOCs for all markdown documentation..."

# Use doctoc with update-only mode
npx doctoc . \
  --update-only \
  --maxlevel 3 \
  --github \
  --notitle

echo "✅ TOC generation complete!"
echo ""
echo "Updated files:"
git status --short | grep "\.md$" || echo "  No changes (TOCs already up-to-date)"
