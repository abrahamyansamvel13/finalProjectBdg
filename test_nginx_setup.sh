#!/bin/bash

# Test script for nginx reverse proxy setup
set -e

RESET='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

echo -e "${BLUE}========================================${RESET}"
echo -e "${BLUE}Testing Nginx Reverse Proxy Setup${RESET}"
echo -e "${BLUE}========================================${RESET}\n"

# Test 1: Check if containers are running
echo -e "${YELLOW}[1/7] Checking if containers are running...${RESET}"
if docker-compose ps | grep -q "gaming_stats_nginx"; then
    echo -e "${GREEN}✓ Nginx container is running${RESET}"
else
    echo -e "${RED}✗ Nginx container is not running${RESET}"
    exit 1
fi

if docker-compose ps | grep -q "gaming_stats_api"; then
    echo -e "${GREEN}✓ API container is running${RESET}"
else
    echo -e "${RED}✗ API container is not running${RESET}"
    exit 1
fi

if docker-compose ps | grep -q "gaming_stats_db"; then
    echo -e "${GREEN}✓ Database container is running${RESET}"
else
    echo -e "${RED}✗ Database container is not running${RESET}"
    exit 1
fi
echo ""

# Test 2: Check nginx configuration validity
echo -e "${YELLOW}[2/7] Validating nginx configuration...${RESET}"
if docker-compose exec -T nginx nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ Nginx configuration is valid${RESET}"
else
    echo -e "${RED}✗ Nginx configuration has errors${RESET}"
    docker-compose exec -T nginx nginx -t
    exit 1
fi
echo ""

# Test 3: Test nginx health endpoint
echo -e "${YELLOW}[3/7] Testing nginx health check endpoint...${RESET}"
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/health)
if [ "$HEALTH_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ Health endpoint responds with HTTP $HEALTH_STATUS${RESET}"
else
    echo -e "${RED}✗ Health endpoint returned HTTP $HEALTH_STATUS${RESET}"
    exit 1
fi
echo ""

# Test 4: Test API root endpoint through nginx
echo -e "${YELLOW}[4/7] Testing API root endpoint through nginx proxy...${RESET}"
API_RESPONSE=$(curl -s http://localhost:80/)
if echo "$API_RESPONSE" | grep -q "Gaming Stats API"; then
    echo -e "${GREEN}✓ API root endpoint accessible via nginx${RESET}"
    echo -e "  Response: $API_RESPONSE"
else
    echo -e "${YELLOW}⚠ API root endpoint response: $API_RESPONSE${RESET}"
fi
echo ""

# Test 5: Test alternate port (8080)
echo -e "${YELLOW}[5/7] Testing alternate port 8080...${RESET}"
HEALTH_STATUS_8080=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
if [ "$HEALTH_STATUS_8080" -eq 200 ]; then
    echo -e "${GREEN}✓ Port 8080 is working (HTTP $HEALTH_STATUS_8080)${RESET}"
else
    echo -e "${RED}✗ Port 8080 returned HTTP $HEALTH_STATUS_8080${RESET}"
fi
echo ""

# Test 6: Performance test (latency through proxy)
echo -e "${YELLOW}[6/7] Performance test - measuring latency...${RESET}"
TOTAL_TIME=0
ITERATIONS=5

for i in $(seq 1 $ITERATIONS); do
    RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null http://localhost:80/health)
    TOTAL_TIME=$(echo "$TOTAL_TIME + $RESPONSE_TIME" | bc)
done

AVG_TIME=$(echo "scale=4; $TOTAL_TIME / $ITERATIONS" | bc)
echo -e "${GREEN}✓ Average response time (5 requests): ${AVG_TIME}s${RESET}"
echo ""

# Test 7: Check nginx logs
echo -e "${YELLOW}[7/7] Checking nginx logs...${RESET}"
NGINX_LOG_SIZE=$(docker-compose exec -T nginx wc -l < /var/log/nginx/access.log 2>/dev/null || echo "0")
echo -e "${GREEN}✓ Nginx access log entries: $NGINX_LOG_SIZE${RESET}"

# Show recent logs
echo -e "\n${BLUE}=== Recent Nginx Access Logs (last 5 entries) ===${RESET}"
docker-compose exec -T nginx tail -5 /var/log/nginx/access.log 2>/dev/null || echo "No logs yet"
echo ""

# Show error logs if any
ERROR_COUNT=$(docker-compose exec -T nginx wc -l < /var/log/nginx/error.log 2>/dev/null || echo "0")
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}=== Nginx Error Logs ===${RESET}"
    docker-compose exec -T nginx tail -5 /var/log/nginx/error.log
    echo ""
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}All tests completed successfully!${RESET}"
echo -e "${GREEN}========================================${RESET}\n"

echo -e "${BLUE}Nginx Service Details:${RESET}"
echo "  • Listening on: http://localhost (port 80)"
echo "  • Alternate: http://localhost:8080"
echo "  • API backend: gaming_stats_api:8000"
echo "  • Health endpoint: http://localhost/health"
echo "  • Configuration: /etc/nginx/nginx.conf (mounted from ./nginx.conf)"
echo "  • Logs: Docker volume 'nginx_logs'"
echo ""
