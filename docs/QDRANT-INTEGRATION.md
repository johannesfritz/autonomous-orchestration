# Qdrant Integration for Institutional Memory

**Purpose:** Use Qdrant vector database as institutional memory to maintain consistency and build on past work.

---

## Overview

Qdrant stores semantic embeddings of all documentation, development plans, and atomic notes. This enables:
- **Consistency**: Agents search past decisions before making new ones
- **Learning**: Build on past work instead of rediscovering patterns
- **Alignment**: Verify new proposals align with established architecture

**Note:** The Qdrant database itself is NOT part of this repository. This document describes integration patterns and protocols for use in any project that implements this orchestration system.

---

## Architecture

### Dual Embedding Strategy

Each document/note has TWO embeddings (OpenAI text-embedding-3-large, 3072 dimensions):

| Embedding | Purpose | Usage |
|-----------|---------|-------|
| **bluf_embedding** | High-precision semantic matching | Re-ranking search results |
| **content_embedding** | High-recall context matching | Initial broad search |

**Retrieval pattern:**
1. Query → content_embedding search (broad recall)
2. Results → re-rank by bluf_embedding similarity (precision)
3. Top results → return to agent

### Versioning Schema

All Qdrant points include versioning metadata:

```python
{
    "version": 1,                    # Integer version number
    "is_current": true,              # Is this the active version?
    "is_deleted": false,             # Soft delete flag
    "file_exists": true,             # Does source file still exist?
    "git_commit_sha": "abc123...",   # Git commit that created this version
    "superseded_at": null            # When newer version was created
}
```

**Critical filter:** ALL queries must filter for active documents:
```python
filter = Filter(must=[
    FieldCondition(key="is_current", match=MatchValue(value=True)),
    FieldCondition(key="is_deleted", match=MatchValue(value=False)),
    FieldCondition(key="file_exists", match=MatchValue(value=True))
])
```

---

## Search Collections

| Collection | Content | When to Use |
|------------|---------|-------------|
| **jf_private** | Knowledge base (projects, decisions, notes, plans) | Default - finding past work, decisions, patterns |
| **jf_docs** | Technical documentation (APIs, libraries, tools) | Looking up technical references, library usage |
| **documentation** | CLAUDE.md files, rules, protocols, completed plans | Searching for configuration patterns |

---

## Sync Automation

Documentation stays indexed automatically via three-layer automation:

### Layer 1: Git Hook (Local Development)

**Trigger:** After every `git commit` that modifies documentation files

**Hook:** `.claude/hooks/post-commit-sync-docs.sh`

**Behavior:**
- Detects if commit touched CLAUDE.md, .claude/rules/, .claude/protocols/, or completed plans
- If Qdrant running locally (localhost:6333): Re-indexes changed files in background
- If Qdrant not running: Skips (production will index on merge)

**Configuration:** `.claude/settings.json` → PostToolUse hook for `Bash(git commit *)`

### Layer 2: CI/CD (Production Authority)

**Trigger:** Push to main branch OR weekly Sunday 2 AM UTC

**Workflow:** `.github/workflows/sync-docs.yml`

**Steps:**
1. Detect documentation file changes (paths filter)
2. Checkout code, setup Python 3.11
3. Install dependencies
4. Run `python3 .claude/scripts/index-documentation.py`
5. Upload to production Qdrant (QDRANT_URL from GitHub secrets)

**Required GitHub Secrets:**
- `OPENAI_API_KEY` - For embeddings
- `QDRANT_URL` - Production Qdrant endpoint
- `QDRANT_API_KEY` - Qdrant authentication (if applicable)

### Layer 3: Weekly Cron (Fallback)

**Schedule:** Every Sunday at 2 AM UTC

**Purpose:** Ensures consistency even if webhook-based triggers miss changes

---

## Integration with Agents

### Mandatory Search Protocol

Product Management agents MUST search Qdrant before making decisions:

| Agent | Search Before | Query Pattern |
|-------|---------------|---------------|
| **Product Manager** | Feature proposals | Similar feature requests, past prioritization |
| **Technical PM** | Development plans | Similar past plans, complexity estimates |
| **Solutions Architect** | ADR creation | Related ADRs, architectural patterns |

**Enforcement:** SubagentStart hooks remind agents to search. SubagentStop hooks verify search was documented.

### Search Protocol

From `.claude/protocols/semantic-search-protocol.md`:

1. **Formulate query** - Natural language, specific to your task
2. **Search relevant collection** - `jf_private` for past work, `jf_docs` for references
3. **Review top results** - Usually top 5-10 results are sufficient
4. **Document findings** - Summarize what you found and how it informs your decision
5. **Cite alignment** - Reference specific past decisions/patterns you're aligning with

### Example Search Workflow

**Task:** Create development plan for dark mode toggle

**Product Manager search:**
```
Query: "dark mode toggle user request feature"
Collection: jf_private
Results: 8 users requested this, past ICE score methodology found
Action: Document validation, cite past prioritization patterns
```

**Technical PM search:**
```
Query: "CSS theme variables state management react"
Collection: jf_private
Results: Similar theming work done in Plan-2025-008
Action: Reference past complexity estimate, cite reusable patterns
```

**Solutions Architect search:**
```
Query: "theming architecture ADR"
Collection: documentation
Results: No existing ADR for theming
Action: Create new ADR, document search performed
```

---

## Indexing Scripts

### index-documentation.py

**Location:** `.claude/scripts/index-documentation.py`

**Purpose:** Index all CLAUDE.md files, rules, protocols, and completed plans

**Usage:**
```bash
# Full re-index
python3 .claude/scripts/index-documentation.py

# Incremental (changed files only)
python3 .claude/scripts/index-documentation.py --incremental

# Since specific commit
python3 .claude/scripts/index-documentation.py --incremental --since-commit abc123
```

### search-documentation.py

**Location:** `.claude/scripts/search-documentation.py`

**Purpose:** Search indexed documentation from command line

**Usage:**
```bash
# Search documentation
python3 .claude/scripts/search-documentation.py "query here"

# Search specific collection
python3 .claude/scripts/search-documentation.py "query here" --collection documentation
```

---

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/sync-docs` | Re-index all documentation for semantic search |
| `/search-docs [query]` | Search documentation using natural language |
| `/search-docs --docs [query]` | Search only CLAUDE.md and rules |
| `/search-docs --plans [query]` | Search only completed plans |

---

## Environment Variables

Required for Qdrant integration:

```bash
# Qdrant connection
QDRANT_URL=http://localhost:6333    # Local development
QDRANT_API_KEY=                      # Optional, only for Qdrant Cloud

# Embeddings
OPENAI_API_KEY=sk-...                # For text-embedding-3-large
```

---

## Best Practices

### When to Search

**Always search before:**
- Creating new development plans
- Making architectural decisions
- Proposing new features
- Estimating complexity
- Creating ADRs

**Skip search for:**
- Simple bug fixes with clear scope
- Routine maintenance tasks
- Documentation typo fixes

### Quality Indicators

**Good search:**
- Specific query terms
- Multiple related searches
- Documented findings
- Cited past decisions

**Poor search:**
- Generic queries ("how to do X")
- Single search without refinement
- No documentation of findings
- No alignment analysis

---

## Troubleshooting

### Common Issues

**"Qdrant not running"**
- Start local Qdrant: `docker run -p 6333:6333 qdrant/qdrant`
- Or skip local indexing (production will index on merge)

**"Empty search results"**
- Verify collection exists
- Check versioning filters
- Try broader query terms

**"Stale results"**
- Run `/sync-docs` to re-index
- Check git sync status

**"High latency"**
- Use incremental indexing
- Check Qdrant resource usage

---

## Further Reading

- `.claude/protocols/institutional-memory-protocol.md` - Mandatory search requirements
- `.claude/protocols/semantic-search-protocol.md` - Search best practices
- `.claude/rules/architecture.md` - Versioning schema details
