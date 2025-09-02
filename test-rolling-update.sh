#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get minikube IP
MINIKUBE_IP=$(minikube ip)
echo -e "${BLUE}=== Rolling Update Test Script ===${NC}"
echo "Minikube IP: $MINIKUBE_IP"
echo "Service URL: http://$MINIKUBE_IP:30000/"
echo ""

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment_name=$1
    echo -e "${YELLOW}Waiting for deployment $deployment_name to be ready...${NC}"
    kubectl -n app-dev rollout status deployment/$deployment_name --timeout=300s
    echo -e "${GREEN}✅ Deployment $deployment_name is ready${NC}"
}

# Function to check if all pods are from same replicaset (deployment complete)
check_deployment_complete() {
    local replica_sets=$(kubectl -n app-dev get pods --no-headers | awk '{print $1}' | sed 's/.*-\([^-]*\)-[^-]*$/\1/' | sort | uniq | wc -l)
    [ "$replica_sets" -eq 1 ]
}

# Cleanup existing resources
echo -e "${RED}🧹 Cleaning up existing resources...${NC}"
kubectl -n app-dev delete all --all --ignore-not-found=true
sleep 2

# Deploy v1
echo -e "${BLUE}🚀 Deploying v1 (user-service)...${NC}"
kubectl -n app-dev apply -f k8s/base/deployment-v1.yaml
kubectl -n app-dev apply -f k8s/base/service-nodeport.yaml

wait_for_deployment "user-service"

# Test v1 service
echo -e "${BLUE}🧪 Testing v1 service (5 requests)...${NC}"
for i in {1..5}; do
    response=$(curl --no-keepalive -s http://$MINIKUBE_IP:30000/ 2>/dev/null || echo '{"service":"connection-failed","version":"unknown"}')
    service_info=$(echo $response | jq -r '.service + " v" + .version' 2>/dev/null || echo "Parse error")
    echo "Request $i: $service_info"
    sleep 0.5
done

echo ""
echo -e "${YELLOW}⚡ Starting Rolling Update to v2 (payment-service)...${NC}"
kubectl -n app-dev apply -f k8s/base/deployment-v2.yaml

echo -e "${BLUE}👀 Monitoring Rolling Update (will auto-stop when complete)...${NC}"
echo ""

# Monitor rolling update
request_count=0
while true; do
    # Check if rollout is complete
    if check_deployment_complete; then
        # Wait a bit more to ensure stability
        sleep 2
        if check_deployment_complete; then
            echo -e "${GREEN}🎉 Rolling update completed! All pods are from the same replica set.${NC}"
            break
        fi
    fi
    
    # Show pod status
    echo -e "${YELLOW}--- Pod Status ($(date +%H:%M:%S)) ---${NC}"
    kubectl -n app-dev get pods --no-headers | awk '{print $1 " " $2 " " $3}' | head -10
    
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

# Final verification
echo -e "${BLUE}🔍 Final state verification...${NC}"
kubectl -n app-dev get all

echo ""
echo -e "${BLUE}🧪 Testing final v2 service (5 requests)...${NC}"
for i in {1..5}; do
    response=$(curl --no-keepalive -s http://$MINIKUBE_IP:30000/ 2>/dev/null || echo '{"service":"connection-failed","version":"unknown"}')
    service_info=$(echo $response | jq -r '.service + " v" + .version' 2>/dev/null || echo "Parse error")
    echo "Request $i: $service_info"
    sleep 0.5
done

echo ""
echo -e "${RED}🧹 Cleaning up all resources...${NC}"
kubectl -n app-dev delete all --all

echo -e "${GREEN}✅ Rolling update test completed successfully!${NC}"