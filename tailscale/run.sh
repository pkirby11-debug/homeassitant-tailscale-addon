#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

ACCEPT_DNS=$(jq --raw-output '.accept_dns // true' $CONFIG_PATH)
ACCEPT_ROUTES=$(jq --raw-output '.accept_routes // false' $CONFIG_PATH)
ADVERTISE_ROUTES=$(jq --raw-output '.advertise_routes // ""' $CONFIG_PATH)
SNAT_SUBNETS=$(jq --raw-output '.snat_subnets // true' $CONFIG_PATH)
LOGIN_SERVER=$(jq --raw-output '.login_server // ""' $CONFIG_PATH)
EXTRA_ARGS=$(jq --raw-output '.extra_args // ""' $CONFIG_PATH)

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 0666 /dev/net/tun
fi

mkdir -p /data/tailscale

echo "Starting tailscaled daemon..."
tailscaled --state=/data/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock > /var/log/tailscaled.log 2>&1 &

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

if [ -n "$ADVERTISE_ROUTES" ]; then
    UP_FLAGS="$UP_FLAGS --advertise-routes=$ADVERTISE_ROUTES"
fi

if [ "$SNAT_SUBNETS" = "false" ]; then
    UP_FLAGS="$UP_FLAGS --snat-subnets=false"
fi

if [ -n "$LOGIN_SERVER" ]; then
    UP_FLAGS="$UP_FLAGS --login-server=$LOGIN_SERVER"
fi

if [ -n "$EXTRA_ARGS" ]; then
    UP_FLAGS="$UP_FLAGS $EXTRA_ARGS"
fi

echo "Running tailscale up with flags: $UP_FLAGS"
tailscale --socket=/var/run/tailscale/tailscaled.sock up $UP_FLAGS || true

echo "Tailscale is ready. Tailscaled logs below:"
exec tail -f /var/log/tailscaled.log
