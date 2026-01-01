#!/bin/bash

# Detect database schema changes in staged files
# Returns exit code 0 if schema changes detected, 1 otherwise

# Check for migration files
if git diff --cached --name-only | grep -q "migrations/.*\.sql"; then
    echo "🗄️ DATABASE MIGRATION DETECTED"
    exit 0
fi

# Check for model changes
if git diff --cached --name-only | grep -q "models\.py\|database\.py"; then
    echo "🗄️ DATABASE MODEL CHANGE DETECTED"
    exit 0
fi

# Check for ALTER TABLE in staged changes
if git diff --cached | grep -qiE "ALTER TABLE|ADD COLUMN|DROP COLUMN|CREATE TABLE|DROP TABLE"; then
    echo "🗄️ DATABASE SCHEMA CHANGE DETECTED (SQL command)"
    exit 0
fi

# Check for query modifications (WHERE clauses)
if git diff --cached --name-only | grep -q "routers/.*\.py"; then
    if git diff --cached | grep -E "\.filter\(|\.where\(|WHERE" | grep -v "^-" | grep -q .; then
        echo "🔍 DATABASE QUERY MODIFICATION DETECTED"
        exit 0
    fi
fi

exit 1  # No schema changes detected
