# Custom Auto-Updating Tailscale Home Assistant Add-on

This repository provides an automatically updated Tailscale add-on for Home Assistant OS (including Home Assistant Green).

## Features
- **Auto-Updating Upstream**: GitHub Actions checks for new Tailscale releases daily and updates this repository automatically.
- **Home Assistant Green Support**: Built for `aarch64` (ARM64), `amd64`, `armhf`, and `armv7`.
- **Persistent State**: Preserves login credentials and state across Home Assistant restarts.

## Installation in Home Assistant

1. In Home Assistant, go to **Settings** -> **Add-ons**.
2. Click **Add-on Store** in the bottom right.
3. Click the 3 dots (⋮) in the top right -> **Repositories**.
4. Add your GitHub repository URL: `https://github.com/pkirby11-debug/homeassitant-tailscale-addon`
5. Click **Add**, close the dialog, and refresh the store page.
6. Install **Tailscale (Auto-Updating)** from the store list!
