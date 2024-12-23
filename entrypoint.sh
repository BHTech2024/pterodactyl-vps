#!/bin/bash

# Sleep for 2 seconds to ensure container is ready
sleep 2

# Change to the container directory, or exit if it fails
if [ -d "/home/container" ]; then
    cd /home/container || { echo "Failed to change directory to /home/container"; exit 1; }
else
    echo "Directory /home/container does not exist"
    exit 1
fi

# Parse the startup command safely
if [ -z "${STARTUP}" ]; then
    echo "STARTUP variable is not set"
    exit 1
fi

MODIFIED_STARTUP=$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")

# Make internal Docker IP address available to processes
INTERNAL_IP=$(ip route get 1 | awk '{print $NF;exit}')
if [[ -z "${INTERNAL_IP}" ]]; then
    echo "Failed to retrieve internal IP address"
    exit 1
fi
export INTERNAL_IP

# Check if installation is required
INSTALL_FLAG="$HOME/.installed"
if [ ! -f "${INSTALL_FLAG}" ]; then
    echo "Running installation script"
    /usr/local/bin/proot \
        --rootfs="/" \
        -0 -w "/root" \
        -b /dev -b /sys -b /proc -b /etc/resolv.conf \
        --kill-on-exit \
        /bin/bash "/install.sh" || { echo "Installation failed"; exit 1; }
    touch "${INSTALL_FLAG}"
else
    echo "Installation already completed"
fi

# Check if the helper script exists and is executable
if [ -x "/helper.sh" ]; then
    echo "Running helper script"
    bash /helper.sh
else
    echo "/helper.sh not found or not executable"
    exit 1
fi
