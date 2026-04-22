#!/bin/bash
set -e

# sbx (Docker Sandboxes) mounts host directories at their original host path
# inside the sandbox VM — e.g. /Users/alice/.aws — rather than at the
# container user's $HOME (/home/agent). This means the AWS CLI and kilo
# cannot find credentials or config in the expected locations.
#
# This entrypoint detects those mounts and symlinks them into $HOME before
# handing off to the agent command.
#
# Detection strategies (tried in order):
#   1. Parse /proc/mounts for virtiofs entries  — works in sbx sandboxes
#   2. Filesystem scan fallback                 — works with plain Docker volumes

AGENT_HOME="/home/agent"
KILOCODE_CONFIG_MOUNT=""

# Strategy 1: virtiofs mounts (sbx sandbox environment)
if grep -q virtiofs /proc/mounts 2>/dev/null; then
    while read -r _ mountpoint _ _; do
        case "$mountpoint" in
            */.config/kilo) KILOCODE_CONFIG_MOUNT="$mountpoint" ;;
        esac
    done < <(grep virtiofs /proc/mounts)
fi

if [[ -z "$KILOCODE_CONFIG_MOUNT" ]]; then
    KILOCODE_CONFIG_MOUNT=$(find / -maxdepth 5 -mindepth 4 -type d \
        -name "kilocode" -path "*/.config/kilo" \
        ! -path "${AGENT_HOME}/*" 2>/dev/null | head -1)
fi

# Symlink ~/.config/kilo
if [[ -n "$KILOCODE_CONFIG_MOUNT" ]]; then
    rm -rf "${AGENT_HOME}/.config/kilo"
    mkdir -p "${AGENT_HOME}/.config"
    ln -s "$KILOCODE_CONFIG_MOUNT" "${AGENT_HOME}/.config/kilo"
fi

exec "$@"
