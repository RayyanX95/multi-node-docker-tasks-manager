# Docker Swarm Quick Reference

## 🚀 Quick Start Commands

```bash
# 1. Setup cluster (automated)
./setup-swarm.sh

# 2. Deploy application
./deploy-to-swarm.sh

# 3. Cleanup everything
./cleanup-swarm.sh
```

---

## 📋 Common Operations

### Cluster Management

```bash
# List all nodes
multipass exec manager1 -- docker node ls

# Inspect a node
multipass exec manager1 -- docker node inspect worker1

# Promote worker to manager
multipass exec manager1 -- docker node promote worker1

# Drain a node (stop scheduling tasks)
multipass exec manager1 -- docker node update --availability drain worker1
```

### Service Management

```bash
# List services
multipass exec manager1 -- docker service ls

# View service details
multipass exec manager1 -- docker service ps myapp_backend

# View service logs
multipass exec manager1 -- docker service logs -f myapp_backend

# Scale a service
multipass exec manager1 -- docker service scale myapp_backend=5

# Update service image
multipass exec manager1 -- docker service update --image rayyanx95/tasks-be:v2 myapp_backend

# Rollback a service
multipass exec manager1 -- docker service rollback myapp_backend
```

### Stack Management

```bash
# Deploy stack
multipass exec manager1 -- docker stack deploy -c docker-stack.yml myapp

# List stacks
multipass exec manager1 -- docker stack ls

# List stack services
multipass exec manager1 -- docker stack services myapp

# List stack tasks
multipass exec manager1 -- docker stack ps myapp

# Remove stack
multipass exec manager1 -- docker stack rm myapp
```

### Monitoring

```bash
# Watch service status (updates every 2 seconds)
watch -n 2 'multipass exec manager1 -- docker service ls'

# View resource usage
multipass exec manager1 -- docker stats

# Check node resource usage
multipass exec manager1 -- docker node ps $(docker node ls -q)
```

---

## 🔧 Multipass VM Management

```bash
# List VMs
multipass list

# Get VM info
multipass info manager1

# SSH into VM
multipass shell manager1

# Execute command on VM
multipass exec manager1 -- <command>

# Transfer files to VM
multipass transfer <local-file> manager1:/home/ubuntu/

# Transfer files from VM
multipass transfer manager1:/home/ubuntu/<file> .

# Stop VMs
multipass stop manager1 worker1 worker2

# Start VMs
multipass start manager1 worker1 worker2

# Restart VMs
multipass restart manager1 worker1 worker2

# Delete VMs
multipass delete manager1 worker1 worker2
multipass purge
```

---

## 🐛 Troubleshooting

### Check Service Health

```bash
# View service tasks with errors
multipass exec manager1 -- docker service ps --filter "desired-state=running" myapp_backend

# View failed tasks
multipass exec manager1 -- docker service ps --filter "desired-state=shutdown" myapp_backend

# Inspect service
multipass exec manager1 -- docker service inspect myapp_backend
```

### Network Debugging

```bash
# List networks
multipass exec manager1 -- docker network ls

# Inspect overlay network
multipass exec manager1 -- docker network inspect myapp_tasks-net

# Test connectivity between services
multipass exec manager1 -- docker exec $(docker ps -q -f name=myapp_backend) ping db
```

### Container Logs

```bash
# Find container ID
multipass exec manager1 -- docker ps

# View container logs
multipass exec manager1 -- docker logs <container-id>

# Follow logs
multipass exec manager1 -- docker logs -f <container-id>
```

### Force Service Update

```bash
# Force recreate all tasks
multipass exec manager1 -- docker service update --force myapp_backend
```

---

## 📊 Useful Filters

```bash
# List only running services
multipass exec manager1 -- docker service ls --filter "mode=replicated"

# List services with specific label
multipass exec manager1 -- docker service ls --filter "label=com.docker.stack.namespace=myapp"

# Show only service IDs
multipass exec manager1 -- docker service ls -q
```

---

## 🔐 Secrets Management (Production)

```bash
# Create a secret
echo "mypassword" | multipass exec manager1 -- docker secret create db_password -

# List secrets
multipass exec manager1 -- docker secret ls

# Use secret in service
multipass exec manager1 -- docker service update \
  --secret-add db_password \
  myapp_backend

# Remove secret
multipass exec manager1 -- docker secret rm db_password
```

---

## 📈 Scaling Strategies

```bash
# Scale backend to 3 replicas
multipass exec manager1 -- docker service scale myapp_backend=3

# Scale multiple services
multipass exec manager1 -- docker service scale myapp_backend=3 myapp_frontend=4

# Auto-scale based on CPU (requires additional setup)
# This is more complex and requires orchestration tools like Kubernetes
```

---

## 🔄 Rolling Updates

```bash
# Update with custom parallelism
multipass exec manager1 -- docker service update \
  --update-parallelism 2 \
  --update-delay 10s \
  --image rayyanx95/tasks-be:v2 \
  myapp_backend

# Update with rollback on failure
multipass exec manager1 -- docker service update \
  --update-failure-action rollback \
  --image rayyanx95/tasks-be:v2 \
  myapp_backend
```

---

## 💡 Pro Tips

1. **Always test updates on a single replica first**
   ```bash
   multipass exec manager1 -- docker service update --replicas 1 myapp_backend
   # Test the service
   multipass exec manager1 -- docker service scale myapp_backend=3
   ```

2. **Use health checks in Dockerfile**
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=3s \
     CMD curl -f http://localhost:4000/health || exit 1
   ```

3. **Monitor logs during deployment**
   ```bash
   multipass exec manager1 -- docker service logs -f myapp_backend
   ```

4. **Keep images small** - Use multi-stage builds and alpine base images

5. **Use placement constraints** for stateful services like databases
   ```yaml
   deploy:
     placement:
       constraints:
         - node.role == manager
   ```

---

## 📚 Additional Resources

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy Reference](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Multipass Documentation](https://multipass.run/docs)
