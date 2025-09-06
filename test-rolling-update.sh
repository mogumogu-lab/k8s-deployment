#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo -e "${BLUE}=== Rolling Update Monitor ===${NC}"
echo "Minikube IP: $MINIKUBE_IP"
echo "Service URL: http://$MINIKUBE_IP:30000/"
echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
echo ""

# Trap Ctrl+C for graceful exit
trap 'echo -e "\n${GREEN}Monitoring stopped by user${NC}"; exit 0' INT

# Monitor rolling update
request_count=0
while true; do
    # Show pod status
    echo -e "${YELLOW}--- Pod Status ($(date +%H:%M:%S)) ---${NC}"
    kubectl -n app-dev get pods --no-headers 2>/dev/null | awk '{print $1 " " $2 " " $3}' | head -10 || echo "No pods found in app-dev namespace"
    
    echo "--- Service Responses ---"
    
    # Send 3 requests to see load distribution
    v1_count=0
    v2_count=0
    for i in {1..3}; do
        request_count=$((request_count + 1))
        response=$(curl --no-keepalive -s http://$MINIKUBE_IP:30000/ 2>/dev/null || echo '{"service":"connection-failed","version":"unknown"}')
        
        if echo $response | grep -q "user-service"; then
            v1_count=$((v1_count + 1))
            echo -e "Request $request_count: ${BLUE}user-service v1.0.0${NC}"
        elif echo $response | grep -q "payment-service"; then
            v2_count=$((v2_count + 1))
            echo -e "Request $request_count: ${GREEN}payment-service v1.0.0${NC}"
        else
            echo -e "Request $request_count: ${RED}Connection failed${NC}"
        fi
    done
    
    if [ $v1_count -gt 0 ] && [ $v2_count -gt 0 ]; then
        echo -e "${YELLOW}🔄 Traffic distribution: v1=$v1_count, v2=$v2_count (Mixed!)${NC}"
    fi
    
    echo "----------------------------------------"
    sleep 2
done