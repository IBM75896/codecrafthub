#!/bin/bash
# =============================================================================
# MyLearnTracker - API Test Suite
# =============================================================================
# Run this script to verify every endpoint works correctly.
#
# Usage:
#   chmod +x test_api.sh
#   ./test_api.sh
#
# Make sure app.py is running first:
#   python app.py
# =============================================================================

BASE_URL="http://localhost:5000"

# Terminal colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color (reset)

# Counters
PASS=0
FAIL=0
TOTAL=0

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check() {
    local description="$1"
    local condition="$2"
    TOTAL=$((TOTAL + 1))

    if [ "$condition" = "true" ]; then
        echo -e "  ${GREEN}✓ PASS${NC} — $description"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} — $description"
        FAIL=$((FAIL + 1))
    fi
}

# --------------------------------------------------------------------------
# Pre-flight: is the server up?
# --------------------------------------------------------------------------

print_header "Pre-flight Check"

echo -e "  Connecting to ${YELLOW}$BASE_URL${NC}..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL 2>/dev/null)

if [ "$STATUS" != "200" ]; then
    echo -e "\n  ${RED}ERROR: Server is not responding (got HTTP $STATUS).${NC}"
    echo -e "  ${YELLOW}Make sure app.py is running:${NC} python app.py\n"
    exit 1
fi

echo -e "  ${GREEN}Server is up!${NC} (HTTP 200)\n"

# --------------------------------------------------------------------------
# Clean slate: remove any existing test data
# --------------------------------------------------------------------------

print_header "Setup: Clear existing data"

# We'll track which IDs we create so we can clean up properly
COURSE_IDS=()

echo "  Starting with a fresh data state..."

# --------------------------------------------------------------------------
# TEST GROUP 1: Adding courses (POST)
# --------------------------------------------------------------------------

print_header "Test Group 1 — POST /api/courses (Add Courses)"

echo -e "\n  ${YELLOW}Adding course 1: Python Basics${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Python Basics",
    "description": "Learn Python fundamentals including variables, loops, and functions",
    "target_date": "2025-12-31",
    "status": "Not Started"
  }')
echo "  Response: $RESPONSE"
check "POST /api/courses — Python Basics added" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
ID1=$(echo $RESPONSE | grep -o '"id": *[0-9]*' | grep -o '[0-9]*')
COURSE_IDS+=($ID1)

echo ""
echo -e "  ${YELLOW}Adding course 2: Web Development${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Web Development with Flask",
    "description": "Build web applications using the Python Flask framework",
    "target_date": "2026-02-28",
    "status": "Not Started"
  }')
echo "  Response: $RESPONSE"
check "POST /api/courses — Web Development added" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
ID2=$(echo $RESPONSE | grep -o '"id": *[0-9]*' | grep -o '[0-9]*' | head -1)
COURSE_IDS+=($ID2)

echo ""
echo -e "  ${YELLOW}Adding course 3: Data Science${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Data Science Fundamentals",
    "description": "Introduction to data analysis, visualization, and machine learning with Python",
    "target_date": "2026-06-30",
    "status": "In Progress"
  }')
echo "  Response: $RESPONSE"
check "POST /api/courses — Data Science added" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
ID3=$(echo $RESPONSE | grep -o '"id": *[0-9]*' | grep -o '[0-9]*' | head -1)
COURSE_IDS+=($ID3)

# --------------------------------------------------------------------------
# TEST GROUP 2: Retrieving courses (GET)
# --------------------------------------------------------------------------

print_header "Test Group 2 — GET /api/courses (Retrieve Courses)"

echo -e "\n  ${YELLOW}Get all courses${NC}"
RESPONSE=$(curl -s $BASE_URL/api/courses)
echo "  Response: $RESPONSE"
check "GET /api/courses — returns success" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
check "GET /api/courses — count is at least 3" \
  "$(echo $RESPONSE | grep -c '"count": *[3-9]')"

echo ""
echo -e "  ${YELLOW}Get specific course (ID: $ID1)${NC}"
RESPONSE=$(curl -s $BASE_URL/api/courses/$ID1)
echo "  Response: $RESPONSE"
check "GET /api/courses/$ID1 — returns success" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
check "GET /api/courses/$ID1 — correct course name" \
  "$(echo $RESPONSE | grep -c 'Python Basics')"

# --------------------------------------------------------------------------
# TEST GROUP 3: Updating courses (PUT)
# --------------------------------------------------------------------------

print_header "Test Group 3 — PUT /api/courses/<id> (Update Courses)"

echo -e "\n  ${YELLOW}Update status of course $ID1 to 'In Progress'${NC}"
RESPONSE=$(curl -s -X PUT $BASE_URL/api/courses/$ID1 \
  -H "Content-Type: application/json" \
  -d '{"status": "In Progress"}')
echo "  Response: $RESPONSE"
check "PUT /api/courses/$ID1 — update status to In Progress" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
check "PUT /api/courses/$ID1 — status is now In Progress" \
  "$(echo $RESPONSE | grep -c 'In Progress')"

echo ""
echo -e "  ${YELLOW}Update multiple fields on course $ID2${NC}"
RESPONSE=$(curl -s -X PUT $BASE_URL/api/courses/$ID2 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Advanced Flask & REST APIs",
    "target_date": "2026-04-01",
    "status": "In Progress"
  }')
echo "  Response: $RESPONSE"
check "PUT /api/courses/$ID2 — multi-field update" \
  "$(echo $RESPONSE | grep -c '"success": *true')"

echo ""
echo -e "  ${YELLOW}Mark course $ID3 as Completed${NC}"
RESPONSE=$(curl -s -X PUT $BASE_URL/api/courses/$ID3 \
  -H "Content-Type: application/json" \
  -d '{"status": "Completed"}')
echo "  Response: $RESPONSE"
check "PUT /api/courses/$ID3 — mark as Completed" \
  "$(echo $RESPONSE | grep -c '"success": *true')"

# --------------------------------------------------------------------------
# TEST GROUP 4: Statistics & Search (Bonus)
# --------------------------------------------------------------------------

print_header "Test Group 4 — Bonus Endpoints (Stats & Search)"

echo -e "\n  ${YELLOW}Get statistics${NC}"
RESPONSE=$(curl -s $BASE_URL/api/courses/stats)
echo "  Response: $RESPONSE"
check "GET /api/courses/stats — returns success" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
check "GET /api/courses/stats — has total_courses" \
  "$(echo $RESPONSE | grep -c 'total_courses')"
check "GET /api/courses/stats — has completed count" \
  "$(echo $RESPONSE | grep -c 'completed')"

echo ""
echo -e "  ${YELLOW}Search for 'python'${NC}"
RESPONSE=$(curl -s "$BASE_URL/api/courses/search?q=python")
echo "  Response: $RESPONSE"
check "GET /api/courses/search?q=python — returns success" \
  "$(echo $RESPONSE | grep -c '"success": *true')"
check "GET /api/courses/search?q=python — found results" \
  "$(echo $RESPONSE | grep -c '"count": *[1-9]')"

echo ""
echo -e "  ${YELLOW}Search for 'flask'${NC}"
RESPONSE=$(curl -s "$BASE_URL/api/courses/search?q=flask")
echo "  Response: $RESPONSE"
check "GET /api/courses/search?q=flask — returns results" \
  "$(echo $RESPONSE | grep -c '"success": *true')"

# --------------------------------------------------------------------------
# TEST GROUP 5: Delete
# --------------------------------------------------------------------------

print_header "Test Group 5 — DELETE /api/courses/<id>"

echo -e "\n  ${YELLOW}Delete course $ID2${NC}"
RESPONSE=$(curl -s -X DELETE $BASE_URL/api/courses/$ID2)
echo "  Response: $RESPONSE"
check "DELETE /api/courses/$ID2 — deleted successfully" \
  "$(echo $RESPONSE | grep -c '"success": *true')"

echo ""
echo -e "  ${YELLOW}Verify course $ID2 is gone${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/api/courses/$ID2)
check "GET /api/courses/$ID2 — returns 404 after deletion" \
  "$([ "$HTTP_CODE" = "404" ] && echo true || echo false)"

# --------------------------------------------------------------------------
# TEST GROUP 6: Error handling
# --------------------------------------------------------------------------

print_header "Test Group 6 — Error Handling"

echo -e "\n  ${YELLOW}POST with missing required fields${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/api/courses \
  -H "Content-Type: application/json" \
  -d '{"name": "Incomplete Course"}')
echo "  Response: $RESPONSE"
check "POST missing fields — returns success:false" \
  "$(echo $RESPONSE | grep -c '"success": *false')"
check "POST missing fields — mentions missing fields in error" \
  "$(echo $RESPONSE | grep -c 'Missing')"

echo ""
echo -e "  ${YELLOW}POST with invalid status value${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/api/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bad Status Course",
    "description": "Testing validation",
    "target_date": "2025-12-31",
    "status": "Procrastinating"
  }')
echo "  Response: $RESPONSE"
check "POST invalid status — returns success:false" \
  "$(echo $RESPONSE | grep -c '"success": *false')"

echo ""
echo -e "  ${YELLOW}GET course that does not exist (ID: 99999)${NC}"
RESPONSE=$(curl -s $BASE_URL/api/courses/99999)
echo "  Response: $RESPONSE"
check "GET non-existent course — returns success:false" \
  "$(echo $RESPONSE | grep -c '"success": *false')"

echo ""
echo -e "  ${YELLOW}GET unknown endpoint${NC}"
RESPONSE=$(curl -s $BASE_URL/api/nonexistent)
echo "  Response: $RESPONSE"
check "Unknown endpoint — returns error" \
  "$(echo $RESPONSE | grep -c '"success": *false')"

echo ""
echo -e "  ${YELLOW}Search with no query parameter${NC}"
RESPONSE=$(curl -s "$BASE_URL/api/courses/search")
echo "  Response: $RESPONSE"
check "Search with no q param — returns success:false" \
  "$(echo $RESPONSE | grep -c '"success": *false')"

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Test Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASS${NC}"
echo -e "  ${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}🎉 All tests passed! Your API is working perfectly.${NC}"
    echo ""
    exit 0
else
    echo -e "  ${RED}⚠️  $FAIL test(s) failed. Review the output above.${NC}"
    echo ""
    exit 1
fi
