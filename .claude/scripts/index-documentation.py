#!/usr/bin/env python3
"""
Documentation Indexing Script

Parses CLAUDE.md files and completed plans, generates embeddings,
and stores them in Qdrant "documentation" collection for semantic search.

NOTE: This script intentionally uses direct imports to avoid loading
the full shadow-api Settings class, which requires env vars not needed
for indexing (like ANTHROPIC_API_KEY).
"""

import argparse
import asyncio
import importlib.util
import os
import subprocess
import sys
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional

from dotenv import load_dotenv

# Setup paths and environment
REPO_ROOT = Path(__file__).parent.parent.parent.resolve()

# Load environment variables
env_file = REPO_ROOT / "shadow-api" / ".env"
if env_file.exists():
    load_dotenv(env_file)

# =============================================================================
# Direct imports to avoid loading app.services.__init__.py
# which triggers Settings validation requiring ANTHROPIC_API_KEY etc.
# =============================================================================

def _load_module_directly(module_name: str, file_path: Path):
    """Load a Python module directly without triggering __init__.py."""
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module from {file_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module

# Load the models first (no dependencies)
try:
    models_path = REPO_ROOT / "shadow-api" / "app" / "models" / "documentation_section.py"
    documentation_section_module = _load_module_directly("app.models.documentation_section", models_path)
    DocumentationSection = documentation_section_module.DocumentationSection
except Exception as e:
    print(f"Error loading documentation_section: {e}")
    sys.exit(1)

# Load the parser (depends only on models)
try:
    parser_path = REPO_ROOT / "shadow-api" / "app" / "services" / "documentation_parser.py"
    documentation_parser_module = _load_module_directly("app.services.documentation_parser", parser_path)
    DocumentationParser = documentation_parser_module.DocumentationParser
except Exception as e:
    print(f"Error loading documentation_parser: {e}")
    sys.exit(1)

# Import Qdrant and OpenAI directly (no app.* dependencies)
try:
    from qdrant_client import QdrantClient
    from qdrant_client.models import Distance, VectorParams, PointStruct
    import openai
except ImportError as e:
    print(f"Error importing required modules: {e}")
    print("Make sure shadow-api dependencies are installed:")
    print("  cd shadow-api && pip install -r requirements.txt")
    sys.exit(1)


def get_qdrant_client() -> QdrantClient:
    """Create Qdrant client from environment variables."""
    qdrant_url = os.getenv("QDRANT_URL", "http://localhost:6333")
    qdrant_api_key = os.getenv("QDRANT_API_KEY")

    if qdrant_api_key:
        return QdrantClient(url=qdrant_url, api_key=qdrant_api_key)
    else:
        return QdrantClient(url=qdrant_url)


async def ensure_documentation_collection(client: QdrantClient) -> None:
    """Ensure the documentation collection exists with proper configuration."""
    collection_name = "documentation"
    embedding_dimensions = 3072  # text-embedding-3-large

    collections = client.get_collections()
    exists = any(c.name == collection_name for c in collections.collections)

    if not exists:
        print(f"Creating collection: {collection_name}")
        client.create_collection(
            collection_name=collection_name,
            vectors_config={
                "bluf": VectorParams(
                    size=embedding_dimensions,
                    distance=Distance.COSINE,
                ),
                "content": VectorParams(
                    size=embedding_dimensions,
                    distance=Distance.COSINE,
                ),
            },
        )


def get_changed_files(since_commit: Optional[str] = None) -> List[Path]:
    """
    Get list of documentation files that changed since a specific commit or time.

    Args:
        since_commit: Git commit SHA or None for last 24 hours

    Returns:
        List of changed file paths
    """
    try:
        if since_commit:
            cmd = ["git", "diff", "--name-only", f"{since_commit}..HEAD"]
        else:
            # Get files modified in last 24 hours
            since_time = datetime.now() - timedelta(hours=24)
            since_str = since_time.strftime("%Y-%m-%d %H:%M:%S")
            cmd = ["git", "log", "--name-only", "--pretty=format:", f"--since={since_str}"]

        result = subprocess.run(
            cmd,
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=True
        )

        # Filter for documentation files only
        doc_patterns = [
            "CLAUDE.md",
            ".claude/rules/",
            ".claude/protocols/",
            "00 Inbox/plans/completed/",
        ]

        changed_files = []
        for line in result.stdout.splitlines():
            line = line.strip()
            if not line:
                continue

            # Check if file matches documentation patterns
            if any(pattern in line for pattern in doc_patterns):
                file_path = REPO_ROOT / line
                if file_path.exists() and file_path.suffix == ".md":
                    changed_files.append(file_path)

        return list(set(changed_files))  # Remove duplicates

    except subprocess.CalledProcessError:
        # If git command fails, return empty list (will index all)
        return []


def get_embedding(text: str) -> List[float]:
    """
    Generate embedding using OpenAI API.

    Args:
        text: Text to embed

    Returns:
        3072-dimensional embedding vector
    """
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("OPENAI_API_KEY environment variable not set")

    client = openai.OpenAI(api_key=api_key)
    response = client.embeddings.create(
        model="text-embedding-3-large",
        input=text
    )
    return response.data[0].embedding


async def index_documentation(incremental: bool = False, since_commit: Optional[str] = None):
    """
    Main indexing function.

    Args:
        incremental: If True, only index changed files
        since_commit: Optional git commit SHA to compare against
    """
    print("Documentation Indexing")
    print("=" * 60)

    # Verify environment
    required_vars = ["OPENAI_API_KEY", "QDRANT_URL"]
    missing = [var for var in required_vars if not os.getenv(var)]
    if missing:
        print(f"Error: Missing environment variables: {', '.join(missing)}")
        print("\nRequired variables:")
        print("  OPENAI_API_KEY - OpenAI API key for embeddings")
        print("  QDRANT_URL - Qdrant server URL (default: http://localhost:6333)")
        sys.exit(1)

    # Initialize services
    parser = DocumentationParser(REPO_ROOT)
    qdrant_client = get_qdrant_client()

    # Ensure documentation collection exists
    await ensure_documentation_collection(qdrant_client)
    print(f"Collection: documentation")
    print(f"Qdrant URL: {os.getenv('QDRANT_URL', 'http://localhost:6333')}")

    # Incremental mode handling
    if incremental:
        print(f"Mode: Incremental (changed files only)")
        changed_files = get_changed_files(since_commit)
        if changed_files:
            files_to_index = changed_files
            print(f"Changed files detected: {len(files_to_index)}")
        else:
            print("No changed documentation files detected - skipping indexing")
            return
    else:
        print("Mode: Full re-index")
        files_to_index = []

        # Add documentation files
        for file_path in parser.DOCUMENTATION_FILES:
            full_path = REPO_ROOT / file_path
            if full_path.exists():
                files_to_index.append(full_path)

        # Add completed plans
        plans_dir = REPO_ROOT / parser.COMPLETED_PLANS_DIR
        if plans_dir.exists():
            for plan_file in plans_dir.glob("*.md"):
                files_to_index.append(plan_file)

    print()

    total_files = len(files_to_index)
    total_sections = 0

    print(f"Indexing {total_files} files...")
    print()

    # Process each file
    all_points = []
    for idx, file_path in enumerate(files_to_index, 1):
        try:
            # Parse file
            sections = await parser.parse_file(file_path)

            # Generate embeddings and create points
            for section in sections:
                # Generate dual embeddings
                bluf_embedding = get_embedding(section.bluf)
                content_embedding = get_embedding(section.body)

                # Create Qdrant point
                point = PointStruct(
                    id=str(uuid.uuid4()),
                    vector={
                        "bluf": bluf_embedding,
                        "content": content_embedding
                    },
                    payload={
                        "title": section.title,
                        "file_path": section.source_file,  # Already relative path string
                        "bluf": section.bluf,
                        "content": section.body,
                        "tags": section.tags,
                        "header_level": section.header_level,
                        "section_position": section.section_position,
                        "source_type": section.source_type,
                    }
                )
                all_points.append(point)

            total_sections += len(sections)
            relative_path = file_path.relative_to(REPO_ROOT)
            print(f"[{idx}/{total_files}] {relative_path} - {len(sections)} sections")

        except Exception as e:
            print(f"[{idx}/{total_files}] ERROR: {file_path.name} - {e}")
            continue

    # Upload to Qdrant in batches
    print()
    print("Uploading to Qdrant...")
    batch_size = 100
    for i in range(0, len(all_points), batch_size):
        batch = all_points[i:i + batch_size]
        qdrant_client.upsert(
            collection_name="documentation",
            points=batch
        )
        print(f"  Uploaded {min(i + batch_size, len(all_points))}/{len(all_points)} sections")

    # Summary
    print()
    print("=" * 60)
    print("Summary:")
    print(f"  Files indexed: {total_files}")
    print(f"  Sections indexed: {total_sections}")
    print(f"  Collection: documentation")
    print(f"  Status: Ready for search")
    print("=" * 60)


if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser(
        description="Index documentation files into Qdrant for semantic search"
    )
    arg_parser.add_argument(
        "--incremental",
        action="store_true",
        help="Index only changed files (default: full re-index)"
    )
    arg_parser.add_argument(
        "--since-commit",
        type=str,
        help="Git commit SHA to compare against (default: last 24 hours)"
    )

    args = arg_parser.parse_args()

    try:
        asyncio.run(index_documentation(
            incremental=args.incremental,
            since_commit=args.since_commit
        ))
    except KeyboardInterrupt:
        print("\nIndexing cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nFatal error: {e}")
        sys.exit(1)
