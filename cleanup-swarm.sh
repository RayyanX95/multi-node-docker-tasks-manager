#!/bin/bash

# Cleanup script for Docker Swarm cluster

set -e

echo "🧹 Cleaning up Docker Swarm cluster..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if VMs exist
if ! multipass list | grep -q "manager1"; then
    echo -e "${YELLOW}No VMs found. Nothing to clean up.${NC}"
    exit 0
fi

# Ask for confirmation
echo -e "${RED}WARNING: This will delete all VMs and data!${NC}"
read -p "Are you sure? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Remove stack (if deployed)
echo -e "${YELLOW}Removing stack (if exists)...${NC}"
multipass exec manager1 -- docker stack rm myapp 2>/dev/null || true
sleep 5

# Leave swarm on workers
echo -e "${YELLOW}Removing workers from swarm...${NC}"
multipass exec worker1 -- docker swarm leave 2>/dev/null || true
multipass exec worker2 -- docker swarm leave 2>/dev/null || true

# Leave swarm on manager
echo -e "${YELLOW}Removing manager from swarm...${NC}"
multipass exec manager1 -- docker swarm leave --force 2>/dev/null || true

# Stop VMs
echo -e "${YELLOW}Stopping VMs...${NC}"
multipass stop manager1 worker1 worker2 2>/dev/null || true

# Delete VMs
echo -e "${YELLOW}Deleting VMs...${NC}"
multipass delete manager1 worker1 worker2 2>/dev/null || true

# Purge deleted VMs
echo -e "${YELLOW}Purging VMs...${NC}"
multipass purge

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""
