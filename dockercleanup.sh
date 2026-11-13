#!/bin/bash

# ==========================================================
# UNIVERSAL DOCKER CLEANUP
# Ubuntu / WSL Ubuntu
#
# RUNNING CONTAINERS:
#   Preserve running containers and their dependencies.  
#
# NO RUNNING CONTAINERS:
#   Remove ALL containers, images, networks, volumes,
#   and build caches.
#
# Docker installation and daemon remain installed.
# ==========================================================

set -Eeuo pipefail

echo ""
echo "=========================================="
echo "       UNIVERSAL DOCKER CLEANUP"
echo "=========================================="
echo ""

# Verify Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    exit 1
fi

if ! sudo docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running."
    exit 1
fi

# Get running containers
RUNNING=$(sudo docker ps -q)

echo "Current Docker containers:"
sudo docker ps -a

echo ""

if [[ -n "$RUNNING" ]]; then

    echo "Running containers detected."
    echo "These containers will be preserved."
    echo "All stopped containers and unused resources will be removed."

else

    echo "NO RUNNING CONTAINERS DETECTED."
    echo "ALL Docker containers and resources will be removed."

fi

echo ""
read -r -p "Type CLEANUP to continue: " confirmation

if [[ "$confirmation" != "CLEANUP" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""

if [[ -n "$RUNNING" ]]; then

    # Preserve running containers
    echo "Removing stopped containers..."
    sudo docker container prune -f

    echo "Removing unused images..."
    sudo docker image prune -a -f

    echo "Removing unused networks..."
    sudo docker network prune -f

    echo "Removing unused volumes..."
    sudo docker volume prune -a -f

else

    # Nothing running: remove everything
    echo "Removing ALL containers..."
    sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true

    echo "Removing ALL images..."
    sudo docker rmi -f $(sudo docker images -aq | sort -u) 2>/dev/null || true

    echo "Removing ALL volumes..."
    sudo docker volume rm $(sudo docker volume ls -q) 2>/dev/null || true

    echo "Removing ALL custom networks..."
    for network in $(sudo docker network ls -q); do
        name=$(sudo docker network inspect \
            --format '{{.Name}}' "$network")

        if [[ "$name" != "bridge" && \
              "$name" != "host" && \
              "$name" != "none" ]]; then
            sudo docker network rm "$network" 2>/dev/null || true
        fi
    done

fi

# Clear build caches in either case
echo ""
echo "Removing Docker build cache..."
sudo docker builder prune -a -f

if sudo docker buildx version >/dev/null 2>&1; then
    echo "Removing Buildx cache..."
    sudo docker buildx prune -a -f
fi

echo ""
echo "=========================================="
echo "          CLEANUP COMPLETE"
echo "=========================================="

echo ""
echo "Remaining containers:"
sudo docker ps -a

echo ""
echo "Remaining images:"
sudo docker images

echo ""
echo "Remaining networks:"
sudo docker network ls

echo ""
echo "Remaining volumes:"
sudo docker volume ls

echo ""
echo "Docker disk usage:"
sudo docker system df

echo ""
echo "Docker installation was not removed."
echo "=========================================="
