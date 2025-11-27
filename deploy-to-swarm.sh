#!/bin/bash

# Deploy application to Docker Swarm cluster

set -e

echo "🚀 Deploying application to Docker Swarm..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if manager1 exists
if ! multipass list | grep -q "manager1"; then
    echo -e "${RED}Error: manager1 VM not found!${NC}"
    echo "Please run ./setup-swarm.sh first"
    exit 1
fi

# Get manager IP
MANAGER_IP=$(multipass info manager1 | grep IPv4 | awk '{print $2}')

# Transfer stack file
echo -e "${BLUE}Transferring files to manager...${NC}"
multipass exec manager1 -- mkdir -p /home/ubuntu/backend/db
multipass transfer docker-stack.yml manager1:/home/ubuntu/

# Transfer init.sql if it exists
if [ -f "backend/db/init.sql" ]; then
    echo -e "${YELLOW}Transferring database init script...${NC}"
    multipass transfer backend/db/init.sql manager1:/home/ubuntu/backend/db/
else
    echo -e "${YELLOW}Warning: backend/db/init.sql not found, skipping...${NC}"
fi

# Pre-pull images to avoid "No such image" errors
echo -e "${BLUE}Pre-pulling required images...${NC}"
echo -e "${YELLOW}Pulling postgres:16-alpine...${NC}"
multipass exec manager1 -- docker pull postgres:16-alpine
echo -e "${YELLOW}Pulling rayyanx95/tasks-be...${NC}"
multipass exec manager1 -- docker pull rayyanx95/tasks-be
echo -e "${YELLOW}Pulling rayyanx95/tasks-fe...${NC}"
multipass exec manager1 -- docker pull rayyanx95/tasks-fe

# Deploy stack
echo -e "${BLUE}Deploying stack...${NC}"
multipass exec manager1 -- docker stack deploy -c docker-stack.yml myapp

echo ""
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 5

# Show service status
echo ""
echo -e "${BLUE}Service Status:${NC}"
multipass exec manager1 -- docker stack services myapp

echo ""
echo -e "${BLUE}Service Tasks:${NC}"
multipass exec manager1 -- docker stack ps myapp

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Access your application:"
echo -e "  Frontend: ${YELLOW}http://$MANAGER_IP:5173${NC}"
echo -e "  Backend:  ${YELLOW}http://$MANAGER_IP:4000/api/tasks${NC}"
echo ""
echo "Useful commands:"
echo -e "  View logs:    ${YELLOW}multipass exec manager1 -- docker service logs myapp_backend${NC}"
echo -e "  Scale up:     ${YELLOW}multipass exec manager1 -- docker service scale myapp_backend=3${NC}"
echo -e "  Update image: ${YELLOW}multipass exec manager1 -- docker service update --image rayyanx95/tasks-be:latest myapp_backend${NC}"
echo -e "  Remove stack: ${YELLOW}multipass exec manager1 -- docker stack rm myapp${NC}"
echo ""
