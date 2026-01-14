# ARM64 Deployment Guide for Jetson Orin NX

This guide will help you deploy the xiaozhi-esp32-server project on your Jetson Orin NX 16GB with Ubuntu 22.04 and Jetpack 6.2.1.

## Prerequisites

1. **Docker Installation** (if not already installed):
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

2. **Docker Compose Installation** (if not already installed):
```bash
sudo apt update
sudo apt install docker-compose-plugin
```

## Quick Start

### Option 1: Using the Build Script (Recommended)

1. **Run the ARM64 build script**:
```bash
./build-arm64.sh
```

### Option 2: Manual Build

1. **Build the base image**:
```bash
docker build --platform linux/arm64 -t xiaozhi-esp32-server:server-base-arm64 -f ./Dockerfile-server-base-arm64 .
```

2. **Build the server image**:
```bash
docker build --platform linux/arm64 -t xiaozhi-esp32-server:server-arm64 -f ./Dockerfile-server-arm64 .
```

### Option 3: Using Docker Compose

1. **Deploy with Docker Compose**:
```bash
docker compose -f docker-compose-arm64.yml up -d
```

## Configuration

### Port Configuration
- **HTTP Server**: Port 8003
- **WebSocket Server**: Port 8000

### Memory Management for Jetson Orin NX
The configuration limits container memory usage to 8GB to ensure system stability:
- Memory limit: 8GB
- Memory reservation: 1GB

### GPU Support (Optional)
If you need GPU acceleration:

1. **Install NVIDIA Container Toolkit**:
```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

2. **Enable GPU support in Docker Compose** (uncomment the lines in docker-compose-arm64.yml):
```yaml
runtime: nvidia
environment:
  - NVIDIA_VISIBLE_DEVICES=all
  - NVIDIA_DRIVER_CAPABILITIES=compute,utility
```

## Differences from x64 Version

### Architecture-Specific Changes
1. **Base Image**: Uses `python:3.10-slim` with ARM64 compatibility
2. **PyTorch**: Uses CPU-only PyTorch builds optimized for ARM64
3. **Build Tools**: Added additional build dependencies for ARM64 compilation
4. **Memory Limits**: Configured for Jetson Orin NX 16GB memory constraints

### Dependencies Handled
- **PyTorch**: Automatically installs ARM64-compatible version
- **System Libraries**: All libraries (libopus0, ffmpeg, etc.) work on ARM64
- **Python Packages**: All packages in requirements.txt are ARM64-compatible

## Troubleshooting

### Common Issues

1. **Out of Memory during Build**:
```bash
# Increase swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

2. **PyTorch Installation Issues**:
The Dockerfile automatically handles ARM64 PyTorch installation. If you encounter issues, you can manually install:
```bash
pip install torch==2.2.2+cpu torchaudio==2.2.2+cpu -f https://download.pytorch.org/whl/torch_stable.html
```

3. **Permission Issues**:
```bash
sudo chown -R $USER:$USER /home/andi/Projects/xiaozhi-esp32-server
```

### Monitoring

1. **Check container status**:
```bash
docker ps
docker logs xiaozhi-server
```

2. **Monitor resource usage**:
```bash
docker stats xiaozhi-server
```

3. **Health check**:
```bash
curl http://localhost:8003/health
```

## Performance Optimization for Jetson

### CPU Optimization
```bash
# Set CPU governor to performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Memory Optimization
```bash
# Increase swap if needed (already handled above)
# Monitor memory usage
sudo iotop -a
free -h
```

### Jetpack-Specific Optimizations
The deployment is optimized for Jetpack 6.2.1 with proper memory management and dependency handling.

## Accessing the Application

Once deployed, the application will be available at:
- HTTP API: `http://your-jetson-ip:8003`
- WebSocket: `ws://your-jetson-ip:8000`

## Stopping the Service

```bash
# If using Docker Compose
docker compose -f docker-compose-arm64.yml down

# If using direct Docker run
docker stop xiaozhi-server
docker rm xiaozhi-server
```

## Log Management

Logs are automatically rotated (max 100MB per file, 3 files retained). You can access logs via:
```bash
docker logs xiaozhi-server -f
```

For persistent logs, they are mounted to `./logs` directory on the host.