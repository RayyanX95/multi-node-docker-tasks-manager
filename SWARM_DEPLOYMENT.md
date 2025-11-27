# Docker Swarm Multi-Node Deployment Guide

This guide walks you through deploying the Task Manager application to a Docker Swarm cluster using Multipass VMs.

## Prerequisites

- Multipass installed on your machine
- Docker images pushed to Docker Hub:
  - `rayyanx95/tasks-be`
  - `rayyanx95/tasks-fe`

## Architecture

We'll create a 3-node Docker Swarm cluster:
- **1 Manager Node** (manager1) - Runs the database and orchestrates the cluster
- **2 Worker Nodes** (worker1, worker2) - Run backend and frontend replicas

---

## Step 1: Create Multipass VMs

Create three Ubuntu VMs with Docker pre-installed:

```bash
# Create manager node
multipass launch --name manager1 --cpus 2 --memory 2G --disk 10G

# Create worker nodes
multipass launch --name worker1 --cpus 2 --memory 2G --disk 10G
multipass launch --name worker2 --cpus 2 --memory 2G --disk 10G
```

Verify VMs are running:
```bash
multipass list
```

---

## Step 2: Install Docker on All Nodes

Run these commands on **each VM** (manager1, worker1, worker2):

```bash
# SSH into each VM
multipass shell manager1  # Then repeat for worker1 and worker2

# Inside the VM, install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Exit and re-enter the shell for group changes to take effect
exit
```

---

## Step 3: Initialize Docker Swarm

### On Manager Node:

```bash
# SSH into manager
multipass shell manager1

# Get the manager's IP address
ip addr show enp0s2 | grep "inet " | awk '{print $2}' | cut -d/ -f1

# Initialize Swarm (replace <MANAGER_IP> with actual IP)
docker swarm init --advertise-addr <MANAGER_IP>
```

**Important:** Copy the `docker swarm join` command that appears. It will look like:
```bash
docker swarm join --token SWMTKN-1-xxxxx <MANAGER_IP>:2377
```

---

## Step 4: Join Worker Nodes to Swarm

### On Each Worker Node:

```bash
# SSH into worker1
multipass shell worker1

# Paste the join command from Step 3
docker swarm join --token SWMTKN-1-xxxxx <MANAGER_IP>:2377

# Exit and repeat for worker2
exit
multipass shell worker2
docker swarm join --token SWMTKN-1-xxxxx <MANAGER_IP>:2377
```

### Verify Cluster:

Back on the manager node:
```bash
multipass shell manager1
docker node ls
```

You should see all 3 nodes listed.

---

## Step 5: Deploy the Stack

### Copy Stack File to Manager:

From your **host machine**:
```bash
multipass transfer docker-stack.yml manager1:/home/ubuntu/multinode-tasks/
```

### Deploy the Stack:

On the **manager node**:
```bash
multipass shell manager1

# Deploy the stack
docker stack deploy -c docker-stack.yml myapp

# Verify deployment
docker stack services myapp
docker stack ps myapp
```

---

## Step 6: Access the Application

### Get Manager IP:

```bash
multipass info manager1 | grep IPv4
```

### Access Services:

- **Frontend**: `http://<MANAGER_IP>` # It will redirect to port 80
- **Backend API**: `http://<MANAGER_IP>:4000/api/tasks`
- **Database**: `<MANAGER_IP>:5432` (for direct DB access)

---

## Useful Commands

### Monitor Services:

```bash
# List all services
docker service ls

# View service logs
docker service logs myapp_backend
docker service logs myapp_frontend
docker service logs myapp_db

# Scale services
docker service scale myapp_backend=3
docker service scale myapp_frontend=4

# Inspect a service
docker service inspect myapp_backend
```

### Update Services:

```bash
# Update backend image
docker service update --image rayyanx95/tasks-be:latest myapp_backend

# Update frontend image
docker service update --image rayyanx95/tasks-fe:latest myapp_frontend
```

### Remove Stack:

```bash
docker stack rm myapp
```

### Leave Swarm (if needed):

```bash
# On worker nodes
docker swarm leave

# On manager node (force)
docker swarm leave --force
```

---

## Troubleshooting

### Check Node Status:
```bash
docker node ls
```

### Check Service Replicas:
```bash
docker service ps myapp_backend --no-trunc
```

### View Container Logs:
```bash
# Find container ID
docker ps

# View logs
docker logs <container_id>
```

### Network Issues:
```bash
# List networks
docker network ls

# Inspect overlay network
docker network inspect myapp_tasks-net
```

### Database Connection Issues:

If backend can't connect to database:
```bash
# Check if DB is running
docker service ps myapp_db

# Check DB logs
docker service logs myapp_db

# Verify network connectivity
docker exec -it <backend_container_id> ping db
```

---

## Clean Up

To completely remove everything:

```bash
# Remove stack
docker stack rm myapp

# Leave swarm on all nodes
docker swarm leave --force  # On manager
docker swarm leave          # On workers

# Delete VMs
multipass delete manager1 worker1 worker2
multipass purge
```

---

## Production Considerations

1. **Secrets Management**: Use Docker secrets for sensitive data:
   ```bash
   echo "apppass" | docker secret create postgres_password -
   ```

2. **Volume Backups**: Regularly backup the `db_data` volume

3. **Health Checks**: Add health checks to your Dockerfiles

4. **Resource Limits**: Add resource constraints in stack file:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

5. **Monitoring**: Consider adding Prometheus + Grafana for monitoring

6. **Load Balancer**: Use Traefik or Nginx for production load balancing
