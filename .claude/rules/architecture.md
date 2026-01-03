# Core Concepts (Shared Across Both Systems)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [FRIDAY Pipeline (6-Stage Content Processing)](#friday-pipeline-6-stage-content-processing)
- [Atomic Note Schema (Universal)](#atomic-note-schema-universal)
- [Dual Embedding Strategy](#dual-embedding-strategy)
- [Versioning Payload Schema (Qdrant)](#versioning-payload-schema-qdrant)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## FRIDAY Pipeline (6-Stage Content Processing)

Both systems use the FRIDAY pipeline to transform raw content into atomic notes:

1. **Stage 1: Cleanup** - Whisper transcription → structured text (new intake only)
2. **Stage 2: Structure** - Extract decisions, points, participants, follow-ups
3. **Stage 3: Clarify** - Generate questions for user (can skip)
4. **Stage 4: Atomize** - Break into single-topic atomic notes with BLUF
5. **Stage 5: Refine** - Polish BLUF, verify tags, add metadata
6. **Stage 6a: Embed & Store** - Generate dual embeddings → Qdrant
7. **Stage 6b: Write & Commit** - Summary document → Git (new intake only)

**Key principle**: Existing markdown files skip Stage 1 and Stage 6b. They're already clean and the original file IS the summary document.

## Atomic Note Schema (Universal)

Every atomic note stored in Qdrant follows this schema:

```python
{
    "title": "Concise descriptive title",
    "id": "YYYY-MM-DD-NNN",        # Timestamp-based ID
    "bluf": "1-2 sentence summary", # CRITICAL for retrieval
    "body": "200-400 words",        # Single topic, complete thought
    "tags": ["tag1", "tag2"],       # Consistent taxonomy
    "priority": "high|medium|low",
    "topic_cluster": "Category",
    "cross_references": ["2024-01-15-001"],
    "source_file": "path/in/repo.md",
    "source_type": "existing_doc|voice_intake|meeting_notes|raw_text"
}
```

## Dual Embedding Strategy

Each atomic note has TWO embeddings (OpenAI text-embedding-3-large, 3072 dimensions):
- **bluf_embedding** - High-precision semantic matching
- **content_embedding** - High-recall context matching

**Retrieval pattern**: Query → content embedding search → BLUF re-ranking

## Versioning Payload Schema (Qdrant)

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

**Critical filtering**: Queries must filter for `is_current=true AND is_deleted=false AND file_exists=true` to get active notes only.
