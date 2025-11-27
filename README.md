# Task Manager Application

A modern, full-stack Task Manager application built with React, Node.js, and PostgreSQL, containerized with Docker.

## Project Structure

- **Frontend**: React + Vite application with a modern, responsive UI.
- **Backend**: Node.js + Express REST API.
- **Database**: PostgreSQL.

## Docker Networking Mechanism

This project uses a custom Docker bridge network to facilitate secure and easy communication between the backend and the database containers.

### How it works:

1.  **Custom Network (`tasks-net`)**: We create a dedicated bridge network.
2.  **Service Discovery**: Docker's embedded DNS server allows containers on the same custom network to resolve each other's IP addresses by container name.
3.  **Connection**:
    -   The Database container is named `tasks-db`.
    -   The Backend container connects to the database using `host: 'tasks-db'`.
    -   This eliminates the need to manage IP addresses manually.

## Getting Started

### 1. Create the Network

Create the custom bridge network for the application:

```bash
docker network create tasks-net
```

### 2. Start the Database

Run the PostgreSQL container attached to the network:

```bash
docker run -d \
  --name tasks-db \
  --network tasks-net \
  -e POSTGRES_PASSWORD=apppass \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_DB=appdb \
  -v tasks-data:/var/lib/postgresql/data \
  postgres:16-alpine
```

### 3. Start the Backend

Build and run the backend API. The backend is configured to connect to `tasks-db` via the `POSTGRES_HOST` environment variable.

```bash
# Build the image
cd backend
docker build -t tasks-be .

# Run the container
cd ..
docker run -d \
  --name tasks-be \
  --network tasks-net \
  -p 4000:4000 \
  -e POSTGRES_HOST=tasks-db \
  tasks-be
```

### 4. Run the Frontend

The frontend runs locally and proxies requests to the backend at `http://localhost:4000`.

```bash
cd frontend
npm install
npm run dev
```

Open your browser at `http://localhost:5173` to use the application.

## Docker Swarm Multi-Node Deployment

For production deployment on a Docker Swarm cluster with multiple nodes:

### Quick Start (Automated):

```bash
# Setup entire cluster automatically
./setup-swarm.sh

# Deploy the stack
multipass shell manager1
docker stack deploy -c docker-stack.yml myapp
```

### Manual Setup:

See [SWARM_DEPLOYMENT.md](./SWARM_DEPLOYMENT.md) for detailed step-by-step instructions.

### Cleanup:

```bash
./cleanup-swarm.sh
```

---

## API Endpoints

-   `GET /api/tasks`: Retrieve all tasks.
-   `POST /api/tasks`: Create a new task.
