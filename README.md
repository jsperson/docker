# Docker Container Setup Scripts

Scripts to automate Docker container creation and configuration for development environments.

## Overview

This repository contains three main scripts:

1. **setup-docker-container.sh** - Automated container setup script (run inside container)
2. **run-docker-container-sample.sh** - Sample script to create/start/connect to containers (run on host)
3. **codex_startup.sh** - Bootstrap script for Codex authentication in containers

## Quick Start

### 1. On Your Host Machine

Clone this repository to your host:
```bash
git clone https://github.com/jsperson/docker.git ~/source/docker
cd ~/source/docker
```

Copy the sample run script and customize it:
```bash
cp run-docker-container-sample.sh ~/run-my-container.sh
chmod +x ~/run-my-container.sh
```

Edit the variables in your copy:
```bash
# Edit these variables as needed
CONTAINER_NAME="claude_developer"    # Name your container
IMAGE_NAME="ubuntu:latest"           # Base image
USER_IN_CONTAINER="developer"        # Username to create
PORTS="8080 3000"                    # Ports to expose
```

### 2. Create and Start Your Container

Run your customized script:
```bash
~/run-my-container.sh
```

On first run, this will:
- Create a new container
- Mount your host home directory to `~/host` in the container
- Expose the specified ports
- Connect you as **root** to run the setup script

### 3. Run Setup Script Inside Container

Once connected as root, run the setup script:
```bash
bash /home/developer/host/source/docker/setup-docker-container.sh
```

This will:
- Update system packages
- Install essential tools (curl, wget, git, vim, build-essential, etc.)
- Create the developer user with sudo privileges
- Install Node.js (LTS version)
- Install Claude Code and Codex via npm
- Configure git defaults
- Create `~/source` and `~/bin` directories
- Clone this docker repository to `~/source/docker`
- Set up useful bash aliases
- Clean up package cache

### 4. Reconnect as Developer User

Exit the container and run your script again:
```bash
exit
~/run-my-container.sh
```

Subsequent runs will connect you as the **developer** user in `/home/developer`.

## Script Details

### setup-docker-container.sh

**Location**: Run inside the container as root

**Customization**: Set environment variables before running:
```bash
DEVELOPER_USER=myuser DEVELOPER_PASSWORD=mypass bash setup-docker-container.sh
```

**Default values**:
- User: `developer`
- Password: `developer`
- Node.js: LTS version

**Installed packages**:
- System: curl, wget, sudo, git, vim, nano, build-essential
- Utilities: unzip, zip, htop, tree, jq, less, man-db
- Development: Node.js, npm, Claude Code, Codex

### run-docker-container-sample.sh

**Location**: Run on your host machine

**Behavior**:
- **First run**: Creates container, connects as root for setup
- **Subsequent runs**: Starts container (if stopped), connects as developer user

**Port mapping format**:
```bash
PORTS="8080"              # Maps 8080:8080
PORTS="8080:80"           # Maps host 8080 to container 80
PORTS="8080 3000 5432"    # Multiple ports
```

### codex_startup.sh

**Location**: Available at `~/source/docker/codex_startup.sh` after setup

**Purpose**: Bootstrap Codex authentication in containers by mounting host `.codex` directory

**Usage**: Reference this script when configuring Codex in your containers

## Customization Examples

### Different Username
```bash
# Edit run script
USER_IN_CONTAINER="myuser"

# Then in container, run:
DEVELOPER_USER=myuser bash setup-docker-container.sh
```

### Additional Ports
```bash
# Edit run script
PORTS="8080 3000 5432 6379 9200"
```

### Different Base Image
```bash
# Edit run script
IMAGE_NAME="ubuntu:22.04"
```

## Directory Structure

After setup, your container will have:

```
/home/developer/
├── host/              # Mounted from your host home directory
│   └── source/
│       └── docker/    # This repository
├── source/            # Working directory (docker repo cloned here too)
│   └── docker/
├── bin/               # For custom scripts
└── .bash_aliases      # Useful shell aliases
```

## Troubleshooting

### Container won't start
```bash
# Check container status
docker ps -a

# View logs
docker logs claude_developer

# Force remove and recreate
docker rm -f claude_developer
~/run-my-container.sh
```

### Developer user doesn't exist
Run the setup script again as root:
```bash
docker exec -it claude_developer bash
bash /home/developer/host/source/docker/setup-docker-container.sh
```

### Port already in use
Edit your run script and change the port mapping:
```bash
PORTS="8081:8080 3001:3000"  # Use different host ports
```

## Additional Tools

After setup, you can install additional tools as needed:
```bash
# Python
sudo apt install -y python3 python3-pip python3-venv

# Modern CLI tools
sudo apt install -y ripgrep fd-find bat fzf

# tmux for session management
sudo apt install -y tmux

# SSH client and keys
sudo apt install -y openssh-client
ssh-keygen -t ed25519 -C "developer@container"
```
