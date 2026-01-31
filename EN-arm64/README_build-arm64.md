# `xiaozhi-esp32-server:server-arm64` Docker Image Build Guide for arm64 Architecture

## Optionally Install the Prerequisites

1. **Docker Installation** (if not already installed):

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# add the user to docker group to avoid having to use sudo for docker-commands
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

2. **Docker Compose Installation** (if not already installed):

```bash
sudo apt update
sudo apt install docker-compose-plugin
```

## Build the `xiaozhi-esp32-server:server-arm64` Docker Image

```bash
# This needs to be run from the project's root directory
./EN-arm64/build-arm64.sh
```

This builds both the server-base-arm64 and server-arm64 images similar to option 2 below.

## Next steps for the Deployment

**Continue with [docs/Deployment_en.md chapter 1.1.1](./docs/Deployment_en.md) in the Project's `main/xiaozhi-server` directory.**

At Step 1.1.3.1, you need to use the file `docker-compose-arm64.yml` instead of `docker-compose.yml

After Step 1.1.3.2 The directory structure of `xiaozhi-server` should be:

```
xiaozhi-server
  ├─ docker-compose-arm64.yml
  ├─ data
    ├─ .config.yaml
  ├─ models
     ├─ SenseVoiceSmall
       ├─ model.pt
```

Now configure the Project filesaccoding to chapter 2.

then run the Docker Compose command with the ARM64-specific file:

```bash
docker compose -f docker-compose-arm64.yml up -d
```

Then continue in the document and check the logs,...
