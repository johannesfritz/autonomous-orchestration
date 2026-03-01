#!/usr/bin/env python3
"""
Documentation Search Script

Semantic search across documentation using Qdrant vector database.
Supports filtering by documentation type and displays top results.
"""

import argparse
import os
import sys
from pathlib import Path
from typing import List, Dict, Any

from dotenv import load_dotenv

# Setup paths and environment
REPO_ROOT = Path(__file__).parent.parent.parent.resolve()
sys.path.insert(0, str(REPO_ROOT / "shadow-api"))

# Load environment variables
env_file = REPO_ROOT / "shadow-api" / ".env"
if env_file.exists():
    load_dotenv(env_file)

# Import after path setup
try:
    from app.services.qdrant_collections import get_qdrant_collections_service
    from qdrant_client.models import Filter, FieldCondition, MatchValue
    import openai
except ImportError as e:
    print(f"Error importing required modules: {e}")
    print("Make sure shadow-api dependencies are installed:")
    print("  cd shadow-api && pip install -r requirements.txt")
    sys.exit(1)


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


def search_documentation(query: str, mode: str = "all", limit: int = 10) -> List[Dict[str, Any]]:
    """
    Search documentation using semantic search.
    
    Args:
        query: Search query (natural language)
        mode: Search mode (docs|plans|all)
        limit: Maximum number of results
        
    Returns:
        List of search results with scores and metadata
    """
    # Verify environment
    if not os.getenv("OPENAI_API_KEY"):
        raise ValueError("OPENAI_API_KEY environment variable not set")
    if not os.getenv("QDRANT_URL"):
        raise ValueError("QDRANT_URL environment variable not set")
    
    # Initialize Qdrant client
    qdrant_service = get_qdrant_collections_service()
    
    # Check if collection exists
    if not qdrant_service.collection_exists("documentation"):
        print("Error: Documentation collection not found")
        print("Run /sync-docs to index documentation first")
        sys.exit(1)
    
    # Generate query embedding
    query_embedding = get_embedding(query)
    
    # Build filter based on mode
    search_filter = None
    if mode == "docs":
        # Only CLAUDE.md and .claude/rules/*.md files
        search_filter = Filter(
            should=[
                FieldCondition(key="file_path", match=MatchValue(value="CLAUDE.md")),
                FieldCondition(key="file_path", match=MatchValue(value=".claude/rules/")),
                FieldCondition(key="file_path", match=MatchValue(value=".claude/protocols/")),
                FieldCondition(key="file_path", match=MatchValue(value="deployment/CLAUDE.md")),
                FieldCondition(key="file_path", match=MatchValue(value="shadow-api/CLAUDE.md")),
                FieldCondition(key="file_path", match=MatchValue(value="hotel-de-ville/CLAUDE.md")),
            ]
        )
    elif mode == "plans":
        # Only completed plans
        search_filter = Filter(
            must=[
                FieldCondition(key="file_path", match=MatchValue(value="inbox/plans/completed/"))
            ]
        )
    
    # Search using content embedding (high recall)
    search_results = qdrant_service.client.search(
        collection_name="documentation",
        query_vector=("content", query_embedding),
        query_filter=search_filter,
        limit=limit * 2,  # Get more for reranking
        with_payload=True
    )
    
    # Rerank using BLUF embedding (high precision)
    bluf_scores = qdrant_service.client.search(
        collection_name="documentation",
        query_vector=("bluf", query_embedding),
        query_filter=search_filter,
        limit=limit * 2,
        with_payload=True
    )
    
    # Combine scores (weighted average: 60% content, 40% BLUF)
    combined_scores = {}
    for result in search_results:
        combined_scores[result.id] = result.score * 0.6
    
    for result in bluf_scores:
        if result.id in combined_scores:
            combined_scores[result.id] += result.score * 0.4
        else:
            combined_scores[result.id] = result.score * 0.4
    
    # Get top results
    top_ids = sorted(combined_scores.keys(), key=lambda x: combined_scores[x], reverse=True)[:limit]
    
    # Format results
    results = []
    for result in search_results:
        if result.id in top_ids:
            results.append({
                "score": combined_scores[result.id] * 100,  # Convert to 0-100 scale
                "file_path": result.payload["file_path"],
                "title": result.payload["title"],
                "bluf": result.payload["bluf"],
                "content": result.payload["content"],
            })
    
    # Sort by score
    results.sort(key=lambda x: x["score"], reverse=True)
    
    return results


def display_results(query: str, results: List[Dict[str, Any]], mode: str):
    """
    Display search results in formatted output.
    
    Args:
        query: Original search query
        results: Search results
        mode: Search mode used
    """
    mode_labels = {
        "docs": "documentation files",
        "plans": "completed plans",
        "all": "all sources"
    }
    
    print(f"Top {len(results)} results for \"{query}\" ({mode_labels[mode]}):")
    print()
    
    if not results:
        print("No results found.")
        print()
        print("Suggestions:")
        print("  - Try broader search terms")
        print("  - Check if documentation is indexed (/sync-docs)")
        print("  - Try different search mode (--docs, --plans, --all)")
        return
    
    for result in results:
        score = int(result["score"])
        file_path = result["file_path"]
        title = result["title"]
        snippet = result["bluf"][:100] + "..." if len(result["bluf"]) > 100 else result["bluf"]
        
        print(f"[{score}] {file_path} - {title}")
        print(f"      {snippet}")
        print()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Search documentation semantically")
    parser.add_argument("query", help="Search query (natural language)")
    parser.add_argument(
        "--mode",
        choices=["docs", "plans", "all"],
        default="all",
        help="Search mode: docs (CLAUDE.md only), plans (completed plans), all (default)"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Maximum number of results (default: 10)"
    )
    
    args = parser.parse_args()
    
    try:
        # Search
        results = search_documentation(args.query, args.mode, args.limit)
        
        # Display
        display_results(args.query, results, args.mode)
        
    except KeyboardInterrupt:
        print("\nSearch cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
