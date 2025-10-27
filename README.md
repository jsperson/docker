# Docker Container Setup Scripts

Scripts to automate Docker container creation and configuration for development environments with Claude Code and Codex.

## Overview

This repository contains three main scripts:

1. **setup-docker-container.sh** - Automated container setup script (run inside container as root)
2. **run-docker-container-sample.sh** - Interactive script to create and manage containers (run on host)
3. **codex_startup.sh** - Bootstrap script for Codex authentication in containers

## Quick Start

### 1. On Your Host Machine

Clone this repository to your host:
```bash
git clone https://github.com/jsperson/docker.git ~/source/docker
cd ~/source/docker
```

### 2. Create and Start Your Container

Run the interactive script:
```bash
./run-docker-container-sample.sh
```

When prompted, enter a container name (e.g., `myproject`). The script will:
- Generate a custom run script: `run-docker-myproject.sh`
- Create the container with that name
- Mount your host home directory to `~/host` in the container
- Expose ports 3000 and 8000 by default
- Connect you as **root** for initial setup

### 3. Run Setup Script Inside Container

Once connected as root, run the setup script:
```bash
bash /home/developer/host/source/docker/setup-docker-container.sh
```

The setup script will install and configure everything automatically. A log file is created at `/tmp/setup-docker-container-TIMESTAMP.log` for troubleshooting.

**What gets installed:**
- System packages: curl, wget, sudo, git, vim, nano, build-essential, ca-certificates
- Utilities: unzip, zip, htop, tree, jq, less, man-db
- Node.js (LTS version) and npm
- Claude Code (command: `claude`)
- Codex (command: `codex`)

**What gets configured:**
- Developer user with passwordless sudo
- Git defaults (main branch, no rebase, credential storage)
- Directory structure: `~/source`, `~/bin`
- Docker repository cloned to `~/source/docker`
- Bash aliases for common commands
- `~/bin/claude_danger.sh` - Launches Claude with `--dangerously-skip-permissions`
- `~/codex_startup.sh` - Codex bootstrap script (700 permissions)
- `~/claude_danger.sh` - Claude danger script (700 permissions)

### 4. Reconnect as Developer User

Exit the container and run your generated script again:
```bash
exit
./run-docker-myproject.sh
```

Subsequent runs will connect you as the **developer** user in `/home/developer`.

## Script Details

### run-docker-container-sample.sh

**Location**: Run on your host machine

**Behavior**:
- Prompts for container name
- Generates a custom run script with that name
- If the script already exists, it runs the existing script
- First container creation connects as root for setup
- Subsequent connections use the developer user

**Generated files**: `run-docker-{name}.sh` for each container

**Port mapping**:
- Ports without `:` map to themselves (e.g., `3000` → `3000:3000`)
- Ports with `:` map as specified (e.g., `8080:80`)
- Default: `3000 8000`

**To customize**: Edit the generated run script to change ports, image, or other settings

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

**Logging**: All output is logged to `/tmp/setup-docker-container-TIMESTAMP.log`

**Scripts created**:
- `~/bin/claude_danger.sh` (700) - Launch Claude with permissions bypass
- `~/codex_startup.sh` (700) - Codex authentication bootstrap
- `~/claude_danger.sh` (700) - Copy of danger script in home

**Git configuration**:
- Credentials stored in `~/.git-credentials` (plaintext, use tokens not passwords)
- Default branch: main
- Pull rebase: false

### codex_startup.sh

**Location**: Available at `~/codex_startup.sh` and `~/source/docker/codex_startup.sh` after setup

**Purpose**: Bootstrap Codex authentication in containers by mounting host `.codex` directory

**Permissions**: 700 (owner execute only)

**Usage**: Reference this script when configuring Codex in your containers

## Usage Examples

### Creating Multiple Containers

```bash
# Create first container
./run-docker-container-sample.sh
# Enter: project1

# Create second container
./run-docker-container-sample.sh
# Enter: project2

# Later, reconnect to first container
./run-docker-project1.sh

# Reconnect to second container
./run-docker-project2.sh
```

### Launching Claude Code

Inside the container as developer user:
```bash
# Normal mode
claude

# Bypass permissions (for containers)
~/claude_danger.sh

# Or from bin
~/bin/claude_danger.sh
```

### Customizing Port Mappings

Edit your generated run script to change the `PORTS` variable:
```bash
# Same port on host and container
PORTS="3000 8000 5432"

# Different ports (host:container)
PORTS="3000 8080:80 5432"

# Mix and match
PORTS="3000:3001 8000 9200:9200"
```

## Directory Structure

After setup, your container will have:

```
/home/developer/
├── host/                    # Mounted from your host home directory
│   └── source/
│       └── docker/          # This repository (on host)
├── source/                  # Working directory in container
│   └── docker/              # Docker repo cloned here too
├── bin/                     # Custom scripts
│   └── claude_danger.sh     # Claude with permissions bypass (700)
├── codex_startup.sh         # Codex bootstrap (700)
├── claude_danger.sh         # Claude danger script (700)
└── .bash_aliases            # Useful shell aliases
```

## Troubleshooting

### Container won't start
```bash
# Check container status
docker ps -a

# View logs
docker logs {container-name}

# Force remove and recreate
docker rm -f {container-name}
./run-docker-{container-name}.sh
```

### View setup logs
```bash
# Inside container
ls -lt /tmp/setup-docker-container-*.log
cat /tmp/setup-docker-container-TIMESTAMP.log
```

### Developer user doesn't exist
Run the setup script again as root:
```bash
docker exec -it {container-name} bash
bash /home/developer/host/source/docker/setup-docker-container.sh
```

### Port already in use
Edit your generated run script and change the `PORTS` variable:
```bash
PORTS="3001 8001"  # Use different ports
```

Then remove and recreate the container:
```bash
docker rm -f {container-name}
./run-docker-{container-name}.sh
```

### Git credentials not saving
The setup script configures `git config credential.helper store`, which saves credentials to `~/.git-credentials` in plaintext. Use personal access tokens, not passwords:
```bash
# First git operation will prompt for credentials
git push
# Username: your-username
# Password: ghp_yourtokenhere
# Subsequent operations will use stored credentials
```

### Claude Code command not found
The package `@anthropic-ai/claude-code` installs as `claude`, not `claude-code`:
```bash
# Correct
claude

# Incorrect
claude-code  # This won't work
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

# SSH client and keys for GitHub
sudo apt install -y openssh-client
ssh-keygen -t ed25519 -C "developer@container"
```

## Security Notes

- The `claude_danger.sh` and `codex_startup.sh` scripts have 700 permissions (owner-only access)
- Git credentials are stored in plaintext in `~/.git-credentials` - use personal access tokens
- The developer user has passwordless sudo access - only use in trusted environments
- The `--dangerously-skip-permissions` flag bypasses security checks - only use in containers

## Files in This Repository

- `setup-docker-container.sh` - Main setup script (run in container)
- `run-docker-container-sample.sh` - Interactive container launcher (run on host)
- `codex_startup.sh` - Codex authentication bootstrap script
- `SetupContainerToRunClaude.txt` - Original notes and reference
- `README.md` - This file
