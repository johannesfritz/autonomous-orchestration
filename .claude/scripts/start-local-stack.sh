#!/bin/bash
# start-local-stack.sh - Start backend and frontend servers for UAT
#
# Usage:
#   ./start-local-stack.sh [project]
#
# Projects: hotel-de-ville (default), stellaris
#
# Options:
#   --check    Only check if services are running
#   --stop     Stop running services
#   --restart  Restart services

set -e

PROJECT="${1:-hotel-de-ville}"
ACTION="${2:-start}"

# Project paths
REPO_ROOT="/home/user/jf-private"
case "$PROJECT" in
    hotel-de-ville)
        BACKEND_DIR="$REPO_ROOT/hotel-de-ville/backend"
        FRONTEND_DIR="$REPO_ROOT/hotel-de-ville/frontend"
        BACKEND_PORT=8000
        FRONTEND_PORT=5173
        BACKEND_HEALTH="http://localhost:$BACKEND_PORT/api/health"
        ;;
    stellaris)
        BACKEND_DIR="$REPO_ROOT/stellaris/backend"
        FRONTEND_DIR="$REPO_ROOT/stellaris/frontend"
        BACKEND_PORT=8002
        FRONTEND_PORT=5174
        BACKEND_HEALTH="http://localhost:$BACKEND_PORT/api/health"
        ;;
    *)
        echo "❌ Unknown project: $PROJECT"
        echo "Available: hotel-de-ville, stellaris"
        exit 1
        ;;
esac

PID_DIR="/tmp/uat-pids"
mkdir -p "$PID_DIR"

BACKEND_PID_FILE="$PID_DIR/${PROJECT}-backend.pid"
FRONTEND_PID_FILE="$PID_DIR/${PROJECT}-frontend.pid"
BACKEND_LOG="/tmp/${PROJECT}-backend.log"
FRONTEND_LOG="/tmp/${PROJECT}-frontend.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_qdrant() {
    if curl -s http://localhost:6333/health 2>/dev/null | grep -q "ok"; then
        echo -e "${GREEN}✅ Qdrant running${NC}"
        return 0
    else
        echo -e "${RED}❌ Qdrant not running${NC}"
        echo "   Start with: docker run -p 6333:6333 qdrant/qdrant"
        return 1
    fi
}

check_backend() {
    if curl -s "$BACKEND_HEALTH" 2>/dev/null | grep -q "healthy"; then
        echo -e "${GREEN}✅ Backend running on port $BACKEND_PORT${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Backend not running${NC}"
        return 1
    fi
}

check_frontend() {
    if curl -s "http://localhost:$FRONTEND_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend running on port $FRONTEND_PORT${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Frontend not running${NC}"
        return 1
    fi
}

start_backend() {
    if check_backend; then
        return 0
    fi

    echo "🚀 Starting backend..."
    cd "$BACKEND_DIR"

    # Activate virtual environment
    if [ -d ".venv" ]; then
        source .venv/bin/activate
    elif [ -d "venv" ]; then
        source venv/bin/activate
    else
        echo -e "${RED}❌ No virtual environment found in $BACKEND_DIR${NC}"
        echo "   Create with: python -m venv .venv && pip install -r requirements.txt"
        return 1
    fi

    # Start backend
    nohup uvicorn main:app --host 0.0.0.0 --port $BACKEND_PORT > "$BACKEND_LOG" 2>&1 &
    echo $! > "$BACKEND_PID_FILE"

    # Wait for backend to be ready
    echo -n "   Waiting for backend"
    for i in {1..30}; do
        if curl -s "$BACKEND_HEALTH" 2>/dev/null | grep -q "healthy"; then
            echo ""
            echo -e "${GREEN}✅ Backend ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done

    echo ""
    echo -e "${RED}❌ Backend failed to start within 30 seconds${NC}"
    echo "   Check logs: tail -f $BACKEND_LOG"
    return 1
}

start_frontend() {
    if check_frontend; then
        return 0
    fi

    echo "🚀 Starting frontend..."
    cd "$FRONTEND_DIR"

    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        echo "   Installing npm dependencies..."
        npm install
    fi

    # Start frontend
    nohup npm run dev > "$FRONTEND_LOG" 2>&1 &
    echo $! > "$FRONTEND_PID_FILE"

    # Wait for frontend to be ready
    echo -n "   Waiting for frontend"
    for i in {1..30}; do
        if curl -s "http://localhost:$FRONTEND_PORT" > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}✅ Frontend ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done

    echo ""
    echo -e "${RED}❌ Frontend failed to start within 30 seconds${NC}"
    echo "   Check logs: tail -f $FRONTEND_LOG"
    return 1
}

stop_backend() {
    if [ -f "$BACKEND_PID_FILE" ]; then
        PID=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "🛑 Stopping backend (PID: $PID)..."
            kill "$PID"
            rm "$BACKEND_PID_FILE"
        else
            rm "$BACKEND_PID_FILE"
        fi
    fi

    # Also try to find by port
    PIDS=$(lsof -ti:$BACKEND_PORT 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        echo "🛑 Killing processes on port $BACKEND_PORT..."
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Backend stopped${NC}"
}

stop_frontend() {
    if [ -f "$FRONTEND_PID_FILE" ]; then
        PID=$(cat "$FRONTEND_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "🛑 Stopping frontend (PID: $PID)..."
            kill "$PID"
            rm "$FRONTEND_PID_FILE"
        else
            rm "$FRONTEND_PID_FILE"
        fi
    fi

    # Also try to find by port
    PIDS=$(lsof -ti:$FRONTEND_PORT 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        echo "🛑 Killing processes on port $FRONTEND_PORT..."
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Frontend stopped${NC}"
}

# Main logic
case "$ACTION" in
    --check)
        echo "═══════════════════════════════════════"
        echo "Checking $PROJECT stack status..."
        echo "═══════════════════════════════════════"
        check_qdrant
        check_backend
        check_frontend
        ;;

    --stop)
        echo "═══════════════════════════════════════"
        echo "Stopping $PROJECT stack..."
        echo "═══════════════════════════════════════"
        stop_backend
        stop_frontend
        ;;

    --restart)
        echo "═══════════════════════════════════════"
        echo "Restarting $PROJECT stack..."
        echo "═══════════════════════════════════════"
        stop_backend
        stop_frontend
        sleep 2
        check_qdrant || exit 1
        start_backend
        start_frontend
        ;;

    start|*)
        echo "═══════════════════════════════════════"
        echo "Starting $PROJECT local stack..."
        echo "═══════════════════════════════════════"

        # Check prerequisites
        if ! check_qdrant; then
            echo ""
            echo "Qdrant is required. Start it first:"
            echo "  docker run -d -p 6333:6333 qdrant/qdrant"
            exit 1
        fi

        # Start services
        start_backend
        start_frontend

        echo ""
        echo "═══════════════════════════════════════"
        echo -e "${GREEN}Stack ready for UAT!${NC}"
        echo "═══════════════════════════════════════"
        echo ""
        echo "Frontend: http://localhost:$FRONTEND_PORT"
        echo "Backend:  http://localhost:$BACKEND_PORT"
        echo ""
        echo "Logs:"
        echo "  Backend:  tail -f $BACKEND_LOG"
        echo "  Frontend: tail -f $FRONTEND_LOG"
        echo ""
        echo "To stop: $0 $PROJECT --stop"
        ;;
esac
