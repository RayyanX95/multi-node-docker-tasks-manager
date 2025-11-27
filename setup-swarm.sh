#!/bin/bash

# Docker Swarm Multi-Node Setup Script
# This script automates the creation of a 3-node Docker Swarm cluster using Multipass

set -e

echo "🚀 Starting Docker Swarm Multi-Node Setup..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Create VMs
echo -e "${BLUE}Step 1: Creating Multipass VMs...${NC}"
multipass launch --name manager1 --cpus 2 --memory 2G --disk 10G
multipass launch --name worker1 --cpus 2 --memory 2G --disk 10G
multipass launch --name worker2 --cpus 2 --memory 2G --disk 10G

echo -e "${GREEN}✓ VMs created successfully${NC}"
echo ""

# Step 2: Install Docker on all nodes
echo -e "${BLUE}Step 2: Installing Docker on all nodes...${NC}"

DOCKER_INSTALL_SCRIPT='
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu
'

for node in manager1 worker1 worker2; do
    echo -e "${YELLOW}Installing Docker on $node...${NC}"
    multipass exec $node -- bash -c "$DOCKER_INSTALL_SCRIPT"
done

echo -e "${GREEN}✓ Docker installed on all nodes${NC}"
echo ""

# Step 3: Initialize Swarm on manager
echo -e "${BLUE}Step 3: Initializing Docker Swarm...${NC}"

MANAGER_IP=$(multipass info manager1 | grep IPv4 | awk '{print $2}')
echo -e "${YELLOW}Manager IP: $MANAGER_IP${NC}"

JOIN_TOKEN=$(multipass exec manager1 -- docker swarm init --advertise-addr $MANAGER_IP | grep "docker swarm join --token")

echo -e "${GREEN}✓ Swarm initialized${NC}"
echo ""

# Step 4: Join workers to swarm
echo -e "${BLUE}Step 4: Joining worker nodes to swarm...${NC}"

multipass exec worker1 -- $JOIN_TOKEN
multipass exec worker2 -- $JOIN_TOKEN

echo -e "${GREEN}✓ Workers joined successfully${NC}"
echo ""

# Step 5: Verify cluster
echo -e "${BLUE}Step 5: Verifying cluster...${NC}"
multipass exec manager1 -- docker node ls

echo ""
echo -e "${GREEN}✓ Docker Swarm cluster is ready!${NC}"
echo ""

# Step 6: Transfer stack file
echo -e "${BLUE}Step 6: Transferring stack file to manager...${NC}"
multipass transfer docker-stack.yml manager1:/home/ubuntu/

echo -e "${GREEN}✓ Stack file transferred${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Manager IP: $MANAGER_IP"
echo ""
echo "Next steps:"
echo "1. Deploy the stack:"
echo -e "   ${YELLOW}multipass shell manager1${NC}"
echo -e "   ${YELLOW}docker stack deploy -c docker-stack.yml myapp${NC}"
echo ""
echo "2. Access your application:"
echo -e "   Frontend: ${YELLOW}http://$MANAGER_IP:5173${NC}"
echo -e "   Backend:  ${YELLOW}http://$MANAGER_IP:4000${NC}"
echo ""
echo "3. Monitor services:"
echo -e "   ${YELLOW}docker service ls${NC}"
echo -e "   ${YELLOW}docker stack ps myapp${NC}"
echo ""
