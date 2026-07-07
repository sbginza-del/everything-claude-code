#!/usr/bin/env bash
# install.sh — Legacy shell entrypoint for the ECC installer.
#
# This wrapper resolves the real repo/package root when invoked through a
# symlinked npm bin, then delegates to the Node-based installer runtime.

set -euo pipefail

SCRIPT_PATH="$0"
while [ -L "$SCRIPT_PATH" ]; do
    link_dir="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$link_dir/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# ── Prerequisite: Claude Code CLI ──────────────────────────────────────────
if [ "${ECC_SKIP_CLAUDE_INSTALL:-}" != "1" ]; then
    if ! command -v claude >/dev/null 2>&1; then
        echo "[ECC] Claude Code CLI not found."
        if ! command -v npm >/dev/null 2>&1; then
            echo "[ECC] ERROR: npm is required to install Claude Code but was not found in PATH." >&2
            echo "[ECC]        Install Node.js (https://nodejs.org) and re-run this script." >&2
            exit 1
        fi
        echo "[ECC] Installing @anthropic-ai/claude-code globally..."
        if ! npm install -g @anthropic-ai/claude-code; then
            echo "[ECC] ERROR: 'npm install -g @anthropic-ai/claude-code' failed." >&2
            echo "[ECC]        If this is a permissions error, try:" >&2
            echo "[ECC]          sudo npm install -g @anthropic-ai/claude-code" >&2
            echo "[ECC]        Or configure a user-writable npm prefix:" >&2
            echo "[ECC]          https://docs.npmjs.com/resolving-eacces-permissions-errors" >&2
            exit 1
        fi
        echo "[ECC] Claude Code installed successfully."
    else
        echo "[ECC] Claude Code CLI already installed, skipping."
    fi
fi

# Auto-install Node dependencies when running from a git clone
if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
    echo "[ECC] Installing dependencies..."
    (cd "$SCRIPT_DIR" && npm install --no-audit --no-fund --loglevel=error)
fi

# On MSYS2/Git Bash, convert the POSIX path to a Windows path so Node.js
# (a native Windows binary) receives a valid path instead of a doubled one
# like G:\g\projects\... that results from Git Bash's auto path conversion.
if command -v cygpath &>/dev/null; then
    NODE_SCRIPT="$(cygpath -w "$SCRIPT_DIR/scripts/install-apply.js")"
else
    NODE_SCRIPT="$SCRIPT_DIR/scripts/install-apply.js"
fi

exec node "$NODE_SCRIPT" "$@"
