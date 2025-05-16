#!/bin/bash
set -e

echo "[$(date)] Starting container initialization..."

# Set timezone if requested
if [ "$SET_CONTAINER_TIMEZONE" = "true" ]; then
    if [ -z "$CONTAINER_TIMEZONE" ]; then
        CONTAINER_TIMEZONE="UTC"
    fi
    echo "[$(date)] Setting timezone to $CONTAINER_TIMEZONE"
    ln -sf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime
    echo $CONTAINER_TIMEZONE > /etc/timezone
fi

echo "[$(date)] Creating necessary directories..."
# Create necessary directories
mkdir -p /var/lib/asterisk
mkdir -p /var/spool/asterisk
mkdir -p /var/log/asterisk
mkdir -p /var/run/asterisk
mkdir -p /etc/asterisk

echo "[$(date)] Setting permissions..."
# Set permissions based on ASTERISK_USER
if [ "$ASTERISK_USER" = "root" ]; then
    echo "[$(date)] Running as root user"
    # If running as root, ensure proper permissions
    chown -R root:root /var/lib/asterisk
    chown -R root:root /var/spool/asterisk
    chown -R root:root /var/log/asterisk
    chown -R root:root /var/run/asterisk
    chown -R root:root /etc/asterisk
else
    echo "[$(date)] Running as asterisk user"
    # If running as asterisk user
    chown -R asterisk:asterisk /var/lib/asterisk
    chown -R asterisk:asterisk /var/spool/asterisk
    chown -R asterisk:asterisk /var/log/asterisk
    chown -R asterisk:asterisk /var/run/asterisk
    chown -R asterisk:asterisk /etc/asterisk
fi

echo "[$(date)] Setting directory permissions..."
# Ensure proper permissions for mounted volumes
chmod -R 755 /var/lib/asterisk
chmod -R 755 /var/spool/asterisk
chmod -R 755 /var/log/asterisk
chmod -R 755 /var/run/asterisk
chmod -R 755 /etc/asterisk

echo "[$(date)] Container initialization complete."

# Check if Asterisk is installed
if ! command -v asterisk &> /dev/null; then
    echo "[$(date)] ERROR: Asterisk is not installed!"
    exit 1
fi

# If no arguments were passed, run Asterisk in foreground mode
if [ $# -eq 0 ]; then
    echo "[$(date)] No command provided, starting Asterisk in foreground mode..."
    # Check if Asterisk is already running
    if pgrep asterisk > /dev/null; then
        echo "[$(date)] Asterisk is already running, stopping it first..."
        asterisk -rx "core stop now"
        sleep 2
    fi
    echo "[$(date)] Starting Asterisk..."
    exec asterisk -f
else
    # Execute the command passed to the script
    echo "[$(date)] Executing provided command: $@"
    exec "$@"
fi 