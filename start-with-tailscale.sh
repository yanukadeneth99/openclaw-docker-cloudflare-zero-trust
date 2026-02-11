#!/bin/bash
set -e

# Define socket path in a user-writable location
TS_SOCKET="/home/node/.tailscale/tailscaled.sock"
TS_STATE="/home/node/.tailscale/tailscaled.state"

# Start tailscaled in the background
# running in userspace networking mode since we are non-root
echo "Starting tailscaled..."
/usr/sbin/tailscaled \
    --tun=userspace-networking \
    --socket="${TS_SOCKET}" \
    --state="${TS_STATE}" &

# Wait for the socket to be created
echo "Waiting for tailscaled socket..."
until [ -S "${TS_SOCKET}" ]; do
    sleep 0.1
done

# Authenticate via tailscale up
if [ -n "${TS_AUTHKEY}" ]; then
    echo "Authenticating with Tailscale..."
    /usr/bin/tailscale --socket="${TS_SOCKET}" up \
        --authkey="${TS_AUTHKEY}" \
        --hostname="${TS_HOSTNAME:-openclaw-gateway}"
fi

# Execute the passed command (CMD from Dockerfile)
echo "Starting application..."
exec "$@"
