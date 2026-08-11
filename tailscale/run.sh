#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

ACCEPT_DNS=$(jq --raw-output '.accept_dns // true' $CONFIG_PATH)
ACCEPT_ROUTES=$(jq --raw-output '.accept_routes // true' $CONFIG_PATH)
ADVERTISE_EXIT_NODE=$(jq --raw-output '.advertise_exit_node // false' $CONFIG_PATH)
ADVERTISE_CONNECTOR=$(jq --raw-output '.advertise_connector // false' $CONFIG_PATH)
ALWAYS_USE_DERP=$(jq --raw-output '.always_use_derp // false' $CONFIG_PATH)
LOGIN_SERVER=$(jq --raw-output '.login_server // "https://controlplane.tailscale.com"' $CONFIG_PATH)
SNAT_SUBNET_ROUTES=$(jq --raw-output '.snat_subnet_routes // true' $CONFIG_PATH)
STATEFUL_FILTERING=$(jq --raw-output '.stateful_filtering // false' $CONFIG_PATH)
USERSPACE_NETWORKING=$(jq --raw-output '.userspace_networking // false' $CONFIG_PATH)
EXIT_NODE=$(jq --raw-output '.exit_node // ""' $CONFIG_PATH)
EXTRA_ARGS=$(jq --raw-output '.extra_args // ""' $CONFIG_PATH)

# Parse array options
ADVERTISE_ROUTES=$(jq -r '.advertise_routes // [] | join(",")' $CONFIG_PATH)
TAGS=$(jq -r '.tags // [] | join(",")' $CONFIG_PATH)

# Create network TUN device if needed
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 0666 /dev/net/tun
fi

mkdir -p /data/tailscale

# Handle DERP environment variable
if [ "$ALWAYS_USE_DERP" = "true" ]; then
    export TS_DEBUG_ALWAYS_USE_DERP=true
fi

TAILSCALED_ARGS="--state=/data/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock"

if [ "$USERSPACE_NETWORKING" = "true" ]; then
    TAILSCALED_ARGS="$TAILSCALED_ARGS --tun=userspace-networking"
fi

echo "Starting tailscaled daemon..."
tailscaled $TAILSCALED_ARGS > /var/log/tailscaled.log 2>&1 &

echo "Waiting for tailscaled socket..."
for i in $(seq 1 30); do
    if [ -S /var/run/tailscale/tailscaled.sock ]; then
        break
    fi
    sleep 1
done

UP_FLAGS="--reset"

if [ "$ACCEPT_DNS" = "true" ]; then
    UP_FLAGS="$UP_FLAGS --accept-dns=true"
else
    UP_FLAGS="$UP_FLAGS --accept-dns=false"
fi

if [ "$ACCEPT_ROUTES" = "true" ]; then
    UP_FLAGS="$UP_FLAGS --accept-routes=true"
else
    UP_FLAGS="$UP_FLAGS --accept-routes=false"
fi

if [ "$ADVERTISE_EXIT_NODE" = "true" ]; then
    UP_FLAGS="$UP_FLAGS --advertise-exit-node=true"
fi

if [ "$ADVERTISE_CONNECTOR" = "true" ]; then
    UP_FLAGS="$UP_FLAGS --advertise-connector=true"
fi

if [ -n "$ADVERTISE_ROUTES" ]; then
    UP_FLAGS="$UP_FLAGS --advertise-routes=$ADVERTISE_ROUTES"
fi

if [ "$SNAT_SUBNET_ROUTES" = "false" ]; then
    UP_FLAGS="$UP_FLAGS --snat-subnets=false"
fi

if [ "$STATEFUL_FILTERING" = "true" ]; then
    UP_FLAGS="$UP_FLAGS --stateful-filtering=true"
fi

if [ -n "$EXIT_NODE" ]; then
    UP_FLAGS="$UP_FLAGS --exit-node=$EXIT_NODE"
fi

if [ -n "$TAGS" ]; then
    UP_FLAGS="$UP_FLAGS --advertise-tags=$TAGS"
fi

if [ -n "$LOGIN_SERVER" ] && [ "$LOGIN_SERVER" != "https://controlplane.tailscale.com" ]; then
    UP_FLAGS="$UP_FLAGS --login-server=$LOGIN_SERVER"
fi

if [ -n "$EXTRA_ARGS" ]; then
    UP_FLAGS="$UP_FLAGS $EXTRA_ARGS"
fi

echo "Running tailscale up with flags: $UP_FLAGS"
tailscale --socket=/var/run/tailscale/tailscaled.sock up $UP_FLAGS || true

echo "Starting Tailscale Web UI for Home Assistant Ingress on port 8088..."
tailscale --socket=/var/run/tailscale/tailscaled.sock web --listen 0.0.0.0:8088 &

echo "Tailscale is ready. Tailing logs below:"
exec tail -f /var/log/tailscaled.log
