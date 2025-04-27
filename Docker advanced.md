# More about Docker
To install docker follow the actual official installation guide:
https://docs.docker.com/engine/install/

* Docker engine -- the core of Docker, responsible for running containers, managing images, volumes and handling networking. The main part to have installed. 

* Docker Desktop -- useful GUI for managing Docker containers, images and volumes. It is not required to run Docker, but it is very helpful for development and debugging in a convenient and visual way.

* Docker Compose -- a tool for defining and running multi-container Docker applications. It allows you to define services, networks, and volumes in a single YAML file, making it easier to manage complex applications. 


## Docker images VS Docker containers

* Docker image -- a lightweight, standalone, and executable software package that includes everything needed to run a piece of software, including the code, runtime, libraries, environment variables, and configuration files. Images are read-only and can be used to create containers. Most software vendors provide Docker images for their applications, which can be pulled from [Docker Hub](https://hub.docker.com/) or other container registries. You may start a container from an image, and the container will run the software as defined in the image. 

Don't want to install _PostgreSQL_, _MySQL_, _Redis_, _Kafka_,  on your machine? No problem, just run it in a container from the official image. 

You may start your own [GitLab](https://hub.docker.com/r/gitlab/gitlab-ce), [Confluence](https://hub.docker.com/r/atlassian/confluence),  [Grafana](https://hub.docker.com/r/grafana/grafana) or [Jira](https://hub.docker.com/r/atlassian/jira-software)  service in a container.  

* Docker container -- a running instance of a Docker image. Containers are isolated from each other and the host system, but they can communicate with each other through defined channels. Each container has its own filesystem, processes, and network stack. Containers are created from images and can be started, stopped, moved, and deleted. They are designed to be ephemeral, meaning they can be easily created and destroyed as needed.


<details>
  <summary>How docker actually "isolate" everything under the hood? Click to read more</summary>

---

# 🛠️ Big Picture: How Docker Works

**Docker** is not magic.  
At its heart, **Docker** is just an orchestrator of **Linux kernel features**.  
It uses:

| Concept       | Purpose                   |
| -------------- | -------------------------- |
| **Namespaces** | Isolation: *what you can see* |
| **cgroups**     | Resource control: *how much you can use* |
| **UnionFS** (overlayfs) | Lightweight layered filesystem |
| **Capabilities** | Fine-grained privilege control |
| **seccomp**    | Syscall filtering for security |
| **AppArmor/SELinux** | Mandatory access control policies |

The kernel does almost all the heavy lifting.  
**Docker just makes it user-friendly.**

---

# 🔥 1. Namespaces: The core of Isolation

**Namespaces** hide system resources from a process.

Each **namespace type** isolates a specific resource:

| Namespace      | What it isolates                     |
| --------------- | ------------------------------------- |
| **PID**         | Process IDs (your process tree)       |
| **NET**         | Network interfaces (eth0, ports)      |
| **MNT**         | Mount points (filesystem)             |
| **UTS**         | Hostname and domain name              |
| **IPC**         | Interprocess communication (shared memory, semaphores) |
| **USER**        | User IDs and group IDs (root inside container ≠ root on host) |
| **CGROUP**      | Control group membership (resource limits) |

**How it works:**  
When you `docker run`, Docker **forks a new process** and attaches it to new namespaces, meaning:

- It sees **only its own processes** (PID namespace).
- It sees **its own filesystem** (MNT namespace).
- It thinks it has its **own hostname** (UTS namespace).
- It has **its own network stack** (NET namespace).
- It can have a **different UID map** (USER namespace).

⚡ Result:  
The process is in its own "universe", thinking it's the only one.

---

# 🚦 2. cgroups: Control Groups for Resource Management

**Control Groups (cgroups)** are about **how much you can use**, not what you can see.

They **limit** and **prioritize** resources like:

| Resource | Controlled by |
| -------- | -------------- |
| CPU      | CPU quotas, shares |
| RAM      | Memory limits, swapping behavior |
| IO       | Disk read/write bandwidth |
| PIDs     | Number of processes/threads |
| Network  | (advanced) traffic shaping |

**How it works:**  
Docker configures cgroups when it launches a container:

- Max 512 MB RAM
- Max 20% CPU time
- Max 5000 file descriptors
- Max 100 processes

If the container exceeds, the kernel **kills** processes or **throttles** them.

⚡ Result:  
One container can't starve others or the host.

---

# 🧠 3. Processes Inside a Container

When you `docker run`, Docker doesn't really "create" a container — it:

- Creates **namespaces** for isolation
- Applies **cgroups** for resource limits
- Sets up a **filesystem** (more later)
- Forks a **regular Linux process** inside this environment

Inside a container:

- **init process** (PID 1) is your application, like nginx.
- It manages its own child processes.
- If it crashes, the container usually stops.

**Important:**  
A container is **just a process on the host**, but it's heavily wrapped in isolation layers.

---

# 💾 4. Filesystem Isolation: UnionFS and OverlayFS

Docker uses a **copy-on-write** filesystem called **OverlayFS**.

- Your container's filesystem is **built on top of images**.
- Layers are **read-only** (base image: Ubuntu, nginx install).
- Your container gets a **read-write layer** on top.

When you write a file:

- It's **copied up** from lower layers.
- You modify your private copy.

**Mount namespace** ensures the container sees only its root filesystem (`/`), not the host's.

⚡ Result:  
- Fast container startup.
- Containers share common files to save space.
- Full filesystem isolation.

---

# 🧍‍♂️ 5. User Isolation: UID Mapping

Without user namespaces:  
- Inside container: `root` (UID 0) = Host `root`.

With **user namespaces**:  
- Inside container: `root` (UID 0) = Host UID 100000 (unprivileged)

This means even if a container gets root access internally, it's **non-root** on the host!

Not all Docker setups use **userns** yet by default, but it's increasingly important for security.

---

# 🖧 6. Network Isolation

Each container can have:

| Network mode | Meaning |
| ------------ | ------- |
| **bridge**   | Virtual Ethernet bridge (default) |
| **host**     | Shares host network directly |
| **none**     | No network at all |
| **overlay**  | Multi-host networking (Docker Swarm) |

In `bridge` mode:

- Docker creates a virtual Ethernet interface (`veth` pair).
- Connects container to Docker's bridge network (`docker0`).
- NATs outgoing traffic.

Each container gets **its own IP address**.  
Containers talk to each other via virtual switches.

---

# 🧹 7. Security: More Layers

Docker adds **extra protection**:

| Feature    | Role |
| ----------- | --- |
| **seccomp** | Filters allowed syscalls (e.g., block `ptrace`, `mount`) |
| **AppArmor/SELinux** | Confine access to files, sockets, network |
| **Capabilities** | Drop dangerous privileges (e.g., no raw sockets) |

Thus, even if a container escapes its namespace somehow, it's still extremely restricted by the kernel.

---

# ⚙️ 8. CPU, RAM, HDD Management: Practical View

**RAM**:

- Each container can be limited (e.g., `--memory=512m`).
- If it exceeds, it can be killed (OOM killer).

**CPU**:

- Control CPU shares (relative priority) and CPU quotas (hard limits).
- Example: `--cpus="0.5"` (half a core).

**HDD**:

- Disk I/O can be limited (`blkio` cgroup).
- Disk space isn't unlimited unless you configure quotas.
- Containers write to the copy-on-write layer (unless volumes are mounted).

---

# 🛡️ Summary: Why Docker Isolates Well

| Layer | Role |
| ---- | --- |
| Namespaces | Isolation of resources |
| Cgroups | Resource limitation |
| OverlayFS | Filesystem isolation |
| User namespaces | Root user separation |
| Seccomp/AppArmor | Reduce attack surface |
| Processes | Normal Linux processes inside |

Each container is **just a Linux process** —  
but **so isolated** it feels like its own machine.

---

# 🔥 Bonus Diagram

```
Host OS
│
├── Docker daemon
│   ├── Container 1
│   │    ├── PID namespace
│   │    ├── Network namespace
│   │    ├── MNT namespace
│   │    ├── Cgroups: CPU 20%, RAM 512MB
│   │    └── Filesystem (OverlayFS)
│   │
│   └── Container 2
│        ├── PID namespace
│        ├── Network namespace
│        ├── Cgroups: CPU 50%, RAM 2GB
│        └── Filesystem (OverlayFS)
```

---

# 📚 In case you want even **deeper**:

- Look into `clone(2)` syscall (`man clone`) — used to create new namespaces.
- Look into `unshare(2)` syscall — entering new namespaces.
- Study `pivot_root(2)` syscall — used for changing root filesystem.
- Read about `runc` — it's what Docker uses under the hood to create containers.
- Try creating a container *manually* using `unshare`, `chroot`, and `cgroups`.

---
 
</details>

## Docker layers concept -- how containers are built
Docker images are built in layers. Each layer represents a set of file changes or instructions. When you create a new image, Docker creates a new layer on top of the existing layers. This allows for efficient storage and sharing of images. Layers are immutable, meaning once created, they cannot be changed. Instead, new layers are created for any modifications. This is what makes Docker images lightweight and efficient. 

Click the **more** button below to read more about how Docker images are built and how layers work.

---
<details> 
  <summary>Tl; DR  How docker builds images and how layers work </summary>

# 🛠️ The Core Concept: Docker Images and Layers

In Docker, an **image** is made up of a **stack of layers**.  
Each **layer** represents a **filesystem change** (adding, modifying, deleting files).

**Layers are:**

| Feature | Description |
| ------- | ----------- |
| **Immutable** | Once created, a layer never changes |
| **Shared** | Different images can share layers |
| **Stacked** | Layers are combined to form a complete filesystem |
| **Content-addressed** | Identified by cryptographic hash (SHA256) |

---

# 📚 Analogy: **Layers are like a Photoshop file**

- Background layer (base OS like Ubuntu)
- Next layer (install Nginx)
- Next layer (add app files)
- Next layer (set environment variables)
- Final image = all layers stacked up.

When you modify something, **only the top layer changes**, lower ones are untouched.

---

# 📈 How Docker Builds an Image (Step-by-Step)

Docker uses a **Dockerfile** to define how to build an image.

Example:

```dockerfile
FROM ubuntu:20.04          # Step 1 - base image (layer 1)
RUN apt-get update         # Step 2 - filesystem change (layer 2)
RUN apt-get install -y nginx  # Step 3 - filesystem change (layer 3)
COPY . /app                # Step 4 - filesystem change (layer 4)
CMD ["nginx", "-g", "daemon off;"] # Step 5 - just metadata (container start command)
```

When you run `docker build .`, here's what happens:

| Step | Action | Result |
| ---- | ------ | ------ |
| 1 | `FROM ubuntu:20.04` | Pull base image layer |
| 2 | `RUN apt-get update` | Execute command → new layer (filesystem diff) |
| 3 | `RUN apt-get install nginx` | New layer (install files) |
| 4 | `COPY . /app` | New layer (copy your app files) |
| 5 | `CMD` | Just metadata — no new filesystem layer |

---

# 📦 How Layers Are Stored

- Layers are stored in `/var/lib/docker/overlay2/` (if using OverlayFS).
- Each layer is a **diff** (only what changed compared to the previous).
- Docker uses **OverlayFS** to **merge** layers when running a container.

🔵 **OverlayFS** merges:

- Lower layers (read-only)
- Top writable layer (copy-on-write)

The container sees a unified view: a full filesystem.

---

# 🧠 Important Properties of Layers:

| Property | Detail |
| -------- | ------ |
| **Caching** | If nothing changes in a Dockerfile step, Docker reuses the existing cached layer (speeds up builds massively) |
| **Efficiency** | Images share common layers — if 10 containers use the same Ubuntu base, they all share that layer (saves disk) |
| **Immutability** | Layers never change after creation — new changes create new layers |

---

# 🛠️ Building an Image Internally

Docker engine flow looks like:

1. Read the `Dockerfile` line-by-line.
2. For each instruction (`FROM`, `RUN`, `COPY`, etc):
    - Check if there is an existing cached layer.
    - If yes → reuse.
    - If no → execute instruction inside a temporary container, record filesystem changes.
3. Commit the changes into a new **read-only layer**.
4. Stack layers together.
5. Tag the top layer as the final image.

You can think of it like this:

```
ubuntu:20.04 (base layer)
  + apt-get update (new layer)
    + apt-get install nginx (new layer)
      + copy app files (new layer)
```

---

# 🎯 Where Efficiency Comes From

- If your `FROM` instruction and all subsequent steps are the same → Docker doesn't rebuild.
- Only when a file changes or an instruction is different does Docker invalidate the cache **from that point onward**.
- **Order of instructions matters!**

Bad Dockerfile:

```dockerfile
COPY . /app    # copying source code early → cache busts frequently
RUN apt-get install -y nginx
```

Better Dockerfile:

```dockerfile
RUN apt-get install -y nginx
COPY . /app    # copying app late → cache better preserved
```

---

# 🧩 Types of Layers

| Layer Type | Description |
| ---------- | ----------- |
| **Base layer** | Usually pulled from a registry (e.g., ubuntu, alpine) |
| **Intermediate layers** | Created by Dockerfile steps (`RUN`, `COPY`, `ADD`) |
| **Final image layer** | The manifest points to a stack of layers plus metadata (config, environment variables, entrypoint) |

---

# 📦 Inside an Image Manifest (Advanced)

An image is described by a **JSON manifest** like:

```json
{
  "schemaVersion": 2,
  "layers": [
    { "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip", "size": 324, "digest": "sha256:abcdef..." },
    { "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip", "size": 1243, "digest": "sha256:123456..." }
  ],
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "digest": "sha256:789abc..."
  }
}
```

- **Layers** → pointers to compressed filesystem diffs.
- **Config** → container settings (entrypoint, env vars, etc.)

---

# 🛡️ Summary:

| Concept | Meaning |
| ------- | ------- |
| Image | A stack of filesystem layers + config |
| Layer | Immutable snapshot of filesystem changes |
| Build | A process that generates layers based on Dockerfile |
| Container | A running instance of an image with a writable layer on top |

---

# ⚡ Bonus: Visual Diagram

```
[ubuntu:20.04 layer]  (read-only)
         ↓
[apt-get update layer]  (read-only)
         ↓
[install nginx layer]   (read-only)
         ↓
[copy app files layer]  (read-only)
         ↓
[writable container layer] (when running)
```

---
</details>


# Docker commands and practice

## Docker commands
To list all images:
```bash
docker images
```

To list all running containers:
```bash
docker ps
```

To list all containers even if they are not running:
```bash
docker ps -a
```

To list all volumes:
```bash
docker volume ls
```

To list all networks
```bash
docker network ls
```


To clear unused images:
```bash
docker image prune
```

To clear unused containers:
```bash
docker container prune
```

To clear unused volumes:
```bash
docker volume prune
```

To run container from existing image:
```bash
docker run -d --name <container_name> <image_name>
```

To execute command inside the container:
```bash
docker exec -it <container_name> <command>
```

`-it` means interactive terminal. This means that you will be able to interact with the container in the terminal. For example, if you want to run bash in the container, you can use:
```bash
docker exec -it <container_name> /bin/bash
```

>Actually it means you are going "inside" the container and you can run any command inside the container.
But since it is not a real linux terminal, you may found that a lot of commands and utilities are not available. For example, you may not be able to run `ls` command, or `cat` command. This is because the container is not a real linux terminal, it is just a process running inside the container.


Useful options to include in run command. When you run container you may want to include some options:
```bash
docker run -d --name <container_name> [list of options] <image_name>
```

To add port mapping:
```bash
-p <host_port>:<container_port>
```

This means host port will be mapped to container port. For example, if you want to run nginx on port 8080 on host and 80 on container, you should use:
```bash
docker run -d --name nginx -p 8080:80 nginx
```

To add volume mapping:
```bash
-v <host_path>:<container_path>
```

This means host path will be mapped to container path. For example, if you want to map `/home/user/data` on host to `/data` on container, you should use:
```bash
docker run -d --name nginx -v /home/user/data:/data nginx
```

Mapping volume is extremely usefull to keep data between container restarts.

This is how you can keep your database data between container restarts. You can map your database data folder to host folder, so when you restart the container, data will be kept on host and will be available in the container.
```bash
docker run -d --name postgres -v /home/user/data:/var/lib/postgresql/data postgres
```

Running the previous command will create a new folder `/home/user/data` on host and will map it to `/var/lib/postgresql/data` in the container. 

And after your container stops, you will be able to see the data in the `/home/user/data` folder on host. 

And during the container runs, you will be able to see the data in the `/var/lib/postgresql/data` folder in the container. Actually, it is just the same files, but they are mapped to different paths on host and inside the container.

This approach works with database files, with logs, with any data you want to keep between container restarts.


Option `-d` in run command means run container in "detached" mode. This means that container will run in the background and you will be able to use your terminal. If you want to run container in foreground, you can use -it option:
```bash
docker run -it --name <container_name> <image_name>
```
This means that you will be able to interact with the container in the terminal. For example, if you want to run bash in the container, you can use:
```bash
docker run -it --name <container_name> <image_name> /bin/bash
```

This will run bash in the container and you will be able to interact with it.

To add environment variables:
```bash
-e <env_var_name>=<env_var_value>
```
For example, if you want to run mongoDB container with specific username and password, you can use:

```bash
docker run -d --name mongo -e MONGO_INITDB_ROOT_USERNAME=<username> -e MONGO_INITDB_ROOT_PASSWORD=<password> mongo
```


To stop container:
```bash
docker stop <container_name>
```

Sometimes it is very usefull to create initial startup configuration for the container. Each time docker creates a container it runs a script called `entrypoint.sh`. You can create your own entrypoint script and run it when you create a container.

For example, you need your database has some initial data or tables. You can create a script that will run when you create a container and will create the tables or insert the data.

To run entrypoint script you can use:
```bash
docker run -d --name <container_name> --entrypoint <path_to_script> <image_name>
```

This is the example of entrypoint script for MongoDB, that creates some database and collections:

```bash
#!/bin/bash
# entrypoint.sh

# Start MongoDB service in the background
mongod --fork --logpath /var/log/mongod.log --config /etc/mongod.conf

# Wait for MongoDB to start
sleep 5

# Create initial database and collections
mongo <<EOF
use my_initial_db

db.createCollection("users")
db.createCollection("products")

db.users.insertMany([
  { name: "Alice", age: 30 },
  { name: "Bob", age: 25 }
])

db.products.insertOne({ name: "Laptop", price: 1200 })
EOF

# Keep the container running in foreground
mongod --config /etc/mongod.conf
```

## 📚 Running Containers with Dockerfile

Very often, to start a container, you need to specify a lot of parameters: environment variables, volumes (sometimes several), port mappings, container name, network, and more.  
Your `docker run` command may start looking like this:

```bash
docker run -d \
  --name my-postgres-db \
  --network my-app-network \
  -p 5432:5432 \
  -v /my/local/dbdata:/var/lib/postgresql/data \
  -v /my/local/init-scripts:/docker-entrypoint-initdb.d \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=supersecretpassword \
  -e POSTGRES_DB=myappdb \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.UTF-8" \
  postgres:15
```

---

### 📚 What's happening here?

| Part | Description |
| :--- | :--- |
| `-d` | Run detached (in background) |
| `--name my-postgres-db` | Name the container |
| `--network my-app-network` | Attach container to a user-defined Docker network |
| `-p 5432:5432` | Map host port 5432 to container port 5432 |
| `-v /my/local/dbdata:/var/lib/postgresql/data` | Mount volume for persistent database storage |
| `-v /my/local/init-scripts:/docker-entrypoint-initdb.d` | Mount initialization scripts for database setup |
| `-e POSTGRES_USER=admin` | Set DB username |
| `-e POSTGRES_PASSWORD=supersecretpassword` | Set DB password |
| `-e POSTGRES_DB=myappdb` | Set initial database name |
| `-e PGDATA=/var/lib/postgresql/data/pgdata` | Set custom data directory inside the container |
| `-e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.UTF-8"` | Extra arguments for database initialization |
| `postgres:15` | The image to run |

---

### 🎯 Why This is Hard to Maintain:

✅ Too many flags and arguments scattered everywhere.  
✅ Easy to **make a typo** (one wrong character — container fails to start).  
✅ Hard to **document** — no inline comments possible inside a `docker run` command.  
✅ Hard to **version control** — Bash commands are messy in Git.  
✅ Changes require **rewriting** or **copy-pasting** long commands manually.

That's why we use a **Dockerfile** to build a consistent image and simplify container creation.

---

## 🛠️ Writing a Dockerfile

A **Dockerfile** is a script that contains all the commands to assemble an image.  
It is a simple text file with instructions like `FROM`, `ENV`, `COPY`, `RUN`, etc.

Here is the previous command **rewritten** using a Dockerfile:

```dockerfile
# Dockerfile
FROM postgres:15

# Set environment variables
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=supersecretpassword
ENV POSTGRES_DB=myappdb
ENV PGDATA=/var/lib/postgresql/data/pgdata
ENV POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.UTF-8"

# Metadata about expected volume mounts (optional)
VOLUME ["/var/lib/postgresql/data", "/docker-entrypoint-initdb.d"]

# Expose database port
EXPOSE 5432
```

This Dockerfile:

- Creates an image based on `postgres:15`,
- Sets environment variables,
- Declares expected volumes,
- Exposes port 5432.

---

# 🚀 Building and Running the Container

First, you **build** the image:

```bash
docker build -t my-postgres-db .
```

> **Note:**  
> The `.` at the end means "use the current directory as the build context," where the `Dockerfile` must be located. It just points to the directory, where docker build command will look for the Dockerfile.

Once the image is built, you can **run** a container from it:

```bash
docker run -d \
  --name my-postgres-db \
  --network my-app-network \
  -p 5432:5432 \
  -v /my/local/dbdata:/var/lib/postgresql/data \
  -v /my/local/init-scripts:/docker-entrypoint-initdb.d \
  my-postgres-db
```

Notice that the command is now slightly shorter —  
you don't need to pass `-e` environment variables manually anymore, because they are already **baked into the image**.

---

## ⚡ However...

Even with a Dockerfile, **volume mounts**, **network**, **port mappings**, and **container name** still need to be passed manually when running the container.

These cannot be fully handled inside Dockerfile. You would need docker run or docker-compose still to:

- Actually map ports (-p 5432:5432)
- Mount local volumes (-v)
- Connect to specific network (--network)
- Assign container name (--name)

✅ This is by Docker design: Image ≠ Container settings.


This leads us to an even better solution for managing complex containers:

## 👉 Using `docker-compose.yml`

Instead of running long `docker run` commands every time, we can describe everything (build, environment, volumes, ports, network, etc.) in a simple YAML file — `docker-compose.yml`.

**Example:**

```yaml
# docker-compose.yml
version: "3.9"

services:
  db:
    build: .
    container_name: my-postgres-db
    networks:
      - my-app-network
    ports:
      - "5432:5432"
    volumes:
      - /my/local/dbdata:/var/lib/postgresql/data
      - /my/local/init-scripts:/docker-entrypoint-initdb.d

networks:
  my-app-network:
    driver: bridge
```
#### What this does:

```yaml
version: "3.9"
```
- 📄 **Compose file format version**.  
- This tells Docker which version of the Docker Compose **syntax** you are using.
- `3.9` is a **very common and modern version** that works with the latest Docker Engine.

---

```yaml
services:
```
- 🛠️ **Top-level section** that defines all the **containers (services)** you want to run.
- Each service is a container (or multiple containers) working together.

---

```yaml
  db:
```
- 🛢️ **Name of the service**.  
- In this case, you define a service called `db` (short for database).
- It will run a **PostgreSQL container**.

---

```yaml
    build: .
```
- 🔨 **Instruction to build a Docker image** from a `Dockerfile`.
- `.` means the **current directory** where the `docker-compose.yml` and `Dockerfile` are located.

---

```yaml
    container_name: my-postgres-db
```
- 🏷️ **Explicitly names the container** `my-postgres-db` instead of letting Docker auto-generate a random name.
- Useful for easier container management and when other services need to refer to this container by name.

---

```yaml
    networks:
      - my-app-network
```
- 🌐 **Connects the container to a custom user-defined network** called `my-app-network`.
- This makes it easier for containers to talk to each other **by name** (internal DNS).
- You can define more than one network if needed.

---

```yaml
    ports:
      - "5432:5432"
```
- 🌍 **Maps ports** from the container to the host machine.
- Format is `host:container`.
- Here, **host port `5432`** (Postgres default) is mapped to **container port `5432`**.
- This allows you to connect to the database using `localhost:5432` from outside.

> Note: But if you have your own PostgreSQL installed on the host machine and it is now running, this instructions WILL NOT work.
> Why? Because the port 5432 (default PostgreSQL port) is already bind to the your database on the host. 
> You will need to change the host port to something else, for example `- "5433:5432"`. Then you will have two different PostgreSQL instances running on your machine.

---

```yaml
    volumes:
      - /my/local/dbdata:/var/lib/postgresql/data
      - /my/local/init-scripts:/docker-entrypoint-initdb.d
```

- 💾 **Mounts local folders into the container**.
- The first volume `/my/local/dbdata:/var/lib/postgresql/data`:
  - Local folder `/my/local/dbdata` will **persist** database files.
  - Prevents data loss if container is recreated.
- The second volume `/my/local/init-scripts:/docker-entrypoint-initdb.d`:
  - Local folder `/my/local/init-scripts` contains **initial SQL scripts** that will run automatically when the database starts for the first time.

---

```yaml
networks:
```
- 🧩 **Top-level section** where you **define custom networks**.
- Networks are useful for **isolating services**, creating **private communication**, or just better organizing.

---

```yaml
  my-app-network:
    driver: bridge
```
- 📡 **Definition of the custom network** called `my-app-network`.
- `driver: bridge`:
  - Means it’s a **standard Docker local network** (the default one but user-defined).
  - Provides **container-to-container communication** inside the same bridge network.

---

# 🔥 In Short:

| Part | Purpose |
|:---|:---|
| `version` | Defines Docker Compose syntax version |
| `services` | Defines what containers to run |
| `db` | Database service |
| `build` | Build image from Dockerfile |
| `container_name` | Give the container a friendly name |
| `networks` | Attach service to networks |
| `ports` | Expose ports for external access |
| `volumes` | Mount local folders into container |
| `networks` (top) | Define custom networks |


---

Now, you can simply start everything with:

```bash
docker-compose up -d
```

✅ **No manual typing.**  
✅ **Version control-friendly.**  
✅ **Easier updates and teamwork.**

---

Another option to  build the container and run it in a single command is to use `docker-compose up --build -d`.

# 📢 Quick Recap:

| Concept | Where it goes |
| :--- | :--- |
| Base image and environment variables | Dockerfile |
| Port mapping, volumes, network, container name | `docker-compose.yml` or `docker run` |

##  📚 Using `.env` Files with Docker and Docker Compose

When you hardcode sensitive values like passwords, usernames, and database names directly into your `Dockerfile` or `docker-compose.yml`, it creates several problems:

❌ Security risk (credentials are exposed).  
❌ Harder maintenance (changing passwords requires editing files).  
❌ No separation of configuration from code.

A better way is to use an **`.env` file** — a simple text file where you keep environment variables.

---

# 📦 What is an `.env` File?

An `.env` file is a plain text file that contains **key-value pairs**:

```
# .env
POSTGRES_USER=admin
POSTGRES_PASSWORD=supersecretpassword
POSTGRES_DB=myappdb
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_INITDB_ARGS=--encoding=UTF8 --locale=en_US.UTF-8
```

✅ It's automatically recognized by Docker Compose (and can also be manually loaded with `docker run` if needed).  
✅ You can **exclude** `.env` from your Git repository (via `.gitignore`) for better security.

---

### 🛠️ How to Use `.env` in Dockerfile

If you want to pass variables from an `.env` file into a Dockerfile, you still need to **build-time ARG** and **runtime ENV**.

Example Dockerfile:

```dockerfile
# Dockerfile
FROM postgres:15

# Declare build-time variables (optional, depending on use case)
ARG POSTGRES_USER
ARG POSTGRES_PASSWORD
ARG POSTGRES_DB
ARG PGDATA
ARG POSTGRES_INITDB_ARGS

# Set environment variables inside the image
ENV POSTGRES_USER=$POSTGRES_USER
ENV POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENV POSTGRES_DB=$POSTGRES_DB
ENV PGDATA=$PGDATA
ENV POSTGRES_INITDB_ARGS=$POSTGRES_INITDB_ARGS

VOLUME ["/var/lib/postgresql/data", "/docker-entrypoint-initdb.d"]
EXPOSE 5432
```

When you build, you can pass variables automatically:

```bash
docker build --build-arg POSTGRES_USER --build-arg POSTGRES_PASSWORD --build-arg POSTGRES_DB --build-arg PGDATA --build-arg POSTGRES_INITDB_ARGS -t my-postgres-db .
```

Or you can use **docker-compose.yml** which picks `.env` automatically.

---

### 🛠️ How to Use `.env` in docker-compose.yml

Simplified `docker-compose.yml`:

```yaml
version: "3.9"

services:
  db:
    build: .
    container_name: my-postgres-db
    networks:
      - my-app-network
    ports:
      - "5432:5432"
    volumes:
      - /my/local/dbdata:/var/lib/postgresql/data
      - /my/local/init-scripts:/docker-entrypoint-initdb.d
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      PGDATA: ${PGDATA}
      POSTGRES_INITDB_ARGS: ${POSTGRES_INITDB_ARGS}

networks:
  my-app-network:
    driver: bridge
```

✅ Here, Docker Compose **automatically** substitutes `${VAR_NAME}` placeholders from the `.env` file.  
✅ No need to pass `--build-arg` manually.

---

### 🔥 Practical Workflow Summary

| Step | Command |
| :--- | :--- |
| Create `.env` file | (write your environment variables) |
| Build and start | `docker-compose up -d` |
| Update config | Just update `.env`, and restart containers (`docker-compose up -d`) |

---

### 🎯 Benefits of `.env` Files:

- ✅ **Security** — Keep secrets out of Git if `.env` is ignored.
- ✅ **Flexibility** — Easily switch configurations for dev, staging, production.
- ✅ **Readability** — Clean and short Dockerfiles and Compose files.
- ✅ **Best Practice** — Used in almost all modern Dockerized projects.

---

### 📢 Quick Recap:

| Where | What goes |
| :--- | :--- |
| `.env` file | Store secrets and config |
| `Dockerfile` | Base image and internal setup |
| `docker-compose.yml` | Full container orchestration |


## ⚙️ Using Multiple `.env` Files for Different Environments

In real-world projects, you usually have **different configurations** for production and local development:

- 🏢 **Production** — Real database, strict settings, secure passwords.
- 🛠️ **Development** — Maybe local database, easy password, extra debug settings.

You can handle this cleanly by having **two separate `.env` files**:

```bash
.env            # production settings (default file)
local.env       # development settings (overrides default)
```

---

# 📄 Example contents

### `.env` (Production)

```
POSTGRES_USER=admin
POSTGRES_PASSWORD=supersecureprodpassword
POSTGRES_DB=myappdb
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_INITDB_ARGS=--encoding=UTF8 --locale=en_US.UTF-8
```

### `local.env` (Development)

```
POSTGRES_USER=devadmin
POSTGRES_PASSWORD=devpassword
POSTGRES_DB=devdb
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_INITDB_ARGS=--encoding=UTF8 --locale=en_US.UTF-8
```

---

# 🛠️ How to Run with Different Environments

By default, Docker Compose automatically reads `.env` file in the current directory.

### 👉 To run in **production** (default `.env` file):

```bash
docker-compose up -d
```

No extra flags needed — `.env` is loaded automatically.

---

### 👉 To run in **development** (override with `local.env` file):

```bash
docker --env-file local.env compose up -d
```

- `--env-file local.env` tells Docker Compose to **use `local.env` instead of `.env`**.
- It completely replaces the environment variables.

> **Important:**  
> `--env-file` **must** appear before `compose` and `up` keywords!

---

### 🧠 Visual Flow:

| Use case | Command | Env file loaded |
|:---|:---|:---|
| Production run | `docker-compose up -d` | `.env` (default) |
| Development run | `docker --env-file local.env compose up -d` | `local.env` |

---

#### 🎯 Benefits:

✅ Clean separation between production and development.  
✅ No manual editing of files before running.  
✅ Safe for automation and CI/CD pipelines.  
✅ Easy to maintain secure secrets separately.

---

You can also **create multiple Docker Compose files** (`docker-compose.override.yml`) for even more flexibility, but using `.env` is usually enough for many projects.


# Docker for Professionals

## 🔒 Managing Sensitive Data with Docker Secrets

In production, **storing passwords, API keys, or certificates inside Docker images or `.env` files is insecure**.  
Docker has a built-in solution for this — **Docker Secrets**.

**Docker Secrets** allow you to securely store sensitive information **outside the image**, **outside the environment variables**, and **only available at runtime** to the container.

---

## 🧠 How Docker Secrets Work

- Secrets are managed **separately** from the container's filesystem.
- Containers **read secrets from special in-memory files** mounted into `/run/secrets/<secret_name>`.
- Secrets are **encrypted** in transit and at rest.
- You need to be using **Docker Swarm** mode to use secrets officially (but there are workarounds for standalone too — we'll touch that later).

---

## 📜 Basic Workflow

1. **Create a secret** (store some data in Docker securely).
2. **Assign the secret** to a service (container).
3. **Read the secret** inside the container as a file.

---

## 📄 Example: Setting Up a Database Password with Docker Secrets

## 1. Create a Secret

```bash
echo "supersecureprodpassword" | docker secret create postgres_password -
```
- `postgres_password` — the name of the secret.
- `-` — read from standard input (stdin).

Now Docker securely stores this secret.

> But be warned, once you create the secret, you can not see it in a plain text, as you can see it in an `.env` file. Click to expand and read advanced details about how it works and why it is designed this way.

<details>
<summary>How it works exactly</summary>

---

# 🔍 After a Docker Secret is created:

- **`docker secret ls`** shows **only the secret names and IDs**, not the content.
- **`docker secret inspect <secret>`** shows **metadata** (like creation date, secret ID, labels) — **NOT** the secret value itself.
- **You can never "docker secret get" or "docker secret view" to reveal the raw value.**

**The only way to "see" the secret again is:**
- Inside a running container that has access to that secret (as a file under `/run/secrets/`).
- Or by reading the original file from where you initially created the secret (outside Docker, if you still have it).

If you lose the original plain-text source (the file or command you used to create it), **the secret becomes unrecoverable** — you would have to **delete and recreate** it.

---

# 🧠 Important concepts:

| Behavior | Details |
|:---|:---|
| Can you list secrets? | ✅ Yes, `docker secret ls` (names only) |
| Can you see the plain content later? | ❌ No, for security reasons |
| Where is secret available? | Only inside the container (mounted file, runtime only) |
| Is it stored encrypted? | ✅ Yes, in Swarm's internal Raft store |
| How to change a secret? | You have to delete and recreate it |

---

# 🛡️ Why Docker Does This:

- Prevent **accidental leaks** (no "oops" moments from inspecting secrets).
- Prevent secrets from being stored in container logs, `docker inspect` outputs, or API calls.
- Meet **security standards** (PCI-DSS, HIPAA, etc.).

---

# 🚨 If you need to update a secret:

You **cannot update** a secret in place.
You must:
1. Delete the old secret:
   ```bash
   docker secret rm <secret_name>
   ```
2. Create a new secret with the same or new name:
   ```bash
   echo "newpassword" | docker secret create <secret_name> -
   ```
3. Redeploy your service to pick up the new secret.

---

# 🔥 In short:
> **Docker Secrets are "write-once, access-at-runtime-only" secure objects.**

---
</details>

## 2. Update `docker-compose.yml` (Swarm style)

```yaml
version: "3.9"

services:
  db:
    image: postgres:15
    container_name: my-postgres-db
    networks:
      - my-app-network
    ports:
      - "5432:5432"
    secrets:
      - postgres_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password

secrets:
  postgres_password:
    external: true

networks:
  my-app-network:
    driver: bridge
```

✅ Here’s what happens:
- Instead of passing the password directly, we tell Postgres to **read it from a file** `/run/secrets/postgres_password`.
- This file is automatically mounted and managed by Docker.

✅ Notice the special environment variable:
- `POSTGRES_PASSWORD_FILE` is used instead of `POSTGRES_PASSWORD`.
- Some official images (like Postgres) **support the `_FILE` convention** natively!

---

## 3. Deploy with Docker Swarm

Docker Secrets **require Swarm mode**, so you need to initialize it first:

```bash
docker swarm init
```

Then deploy:

```bash
docker stack deploy -c docker-compose.yml myapp
```

(`docker stack deploy` automatically understands the `secrets:` section.)

---

### 🧨 If You're NOT Using Swarm?

Docker Secrets officially work only with Swarm, **but** if you still want secret-like behavior without Swarm:

- You can **bind-mount** files manually to `/run/secrets/`.
- This is **not encrypted by Docker**, but still better than environment variables.

Example:

```bash
docker run -d \
  --name my-postgres-db \
  --network my-app-network \
  -p 5432:5432 \
  -v /my/local/dbdata:/var/lib/postgresql/data \
  -v /my/local/init-scripts:/docker-entrypoint-initdb.d \
  -v /my/secrets/postgres_password:/run/secrets/postgres_password:ro \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password \
  postgres:15
```

- `-v /my/secrets/postgres_password:/run/secrets/postgres_password:ro`
  - Mounts a local file into container.
  - `:ro` means "read-only" (extra security).

---

### 🎯 Why Use Docker Secrets?

| Without Secrets | With Docker Secrets |
|:---|:---|
| Environment variables are visible in `docker inspect` | Secrets are **hidden** and encrypted |
| Easy to leak in logs or snapshots | Safe at rest and in transit |
| Hard to rotate securely | Easy to rotate without rebuilding images |
| Risky for compliance (PCI-DSS, GDPR) | Compliance-ready storage of credentials |

---

# 📦 Quick Summary:

- Use `docker secret create` to store secrets.
- Use `secrets:` block in Compose files.
- In apps, use environment variable `<VAR>_FILE` or directly read the secret file `/run/secrets/<secret_name>`.
- Production-grade security, built into Docker.

---

#### 🚀 Bonus: Commands Cheat Sheet

| Action | Command |
|:---|:---|
| Create a secret | `echo "myvalue" | docker secret create secret_name -` |
| List secrets | `docker secret ls` |
| Inspect a secret | `docker secret inspect secret_name` |
| Remove a secret | `docker secret rm secret_name` |

---

**Secrets are per-Swarm**, not global per host.  
If you remove the Swarm, all associated secrets will be deleted too — **plan your secrets management carefully!**
