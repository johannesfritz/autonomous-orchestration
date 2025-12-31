#!/bin/bash
# Query Stellaris feedback database via SSH
# Usage: ./stellaris-feedback-query.sh [status] [limit]
#
# Parameters:
#   status - Filter by status (default: "open")
#            Options: open, acknowledged, planned, completed, closed
#   limit  - Max records to return (default: 50)
#
# Examples:
#   ./stellaris-feedback-query.sh                    # Get all open feedback (default)
#   ./stellaris-feedback-query.sh open 10            # Get last 10 open items
#   ./stellaris-feedback-query.sh acknowledged 25    # Get acknowledged items

# Input validation and defaults
STATUS=${1:-open}
LIMIT=${2:-50}

# Validate status parameter (prevent SQL injection)
case "$STATUS" in
  open|acknowledged|planned|completed|closed)
    # Valid status
    ;;
  *)
    echo "Error: Invalid status '$STATUS'. Must be one of: open, acknowledged, planned, completed, closed" >&2
    exit 1
    ;;
esac

# Validate limit parameter (must be positive integer)
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -lt 1 ] || [ "$LIMIT" -gt 1000 ]; then
  echo "Error: Invalid limit '$LIMIT'. Must be a positive integer between 1 and 1000" >&2
  exit 2
fi

# Execute SSH query with validated parameters
ssh village "sqlite3 -json /var/lib/stellaris/data/stellaris.db \
  'SELECT id, user_id, feedback_category, feedback_type, title, description, page_route, status, created_at \
   FROM user_feedback WHERE status = \"$STATUS\" ORDER BY created_at DESC LIMIT $LIMIT'"

# Capture exit code
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "Error: SSH query failed with exit code $EXIT_CODE" >&2
  echo "Troubleshooting steps:" >&2
  echo "  1. Test SSH connection: ssh village 'echo Connection successful'" >&2
  echo "  2. Check database exists: ssh village 'ls -la /var/lib/stellaris/data/stellaris.db'" >&2
  echo "  3. Verify SQLite JSON support: ssh village 'sqlite3 -version'" >&2
  exit $EXIT_CODE
fi

exit 0
