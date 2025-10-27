#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Codex bootstrap…"

# === CONFIG ===
MOUNTED_CODEX_HOME="${HOME}/host/.codex"   # your host's .codex inside container
LOCAL_CODEX_HOME="${HOME}/.codex"           # canonical location many tools expect

# Optional: set USE_API_KEY=1 to force API-key auth (OPENAI_API_KEY must be set)
USE_API_KEY="${USE_API_KEY:-0}"

# === 0) Basic sanity ===
if ! command -v codex >/dev/null 2>&1; then
  echo "[ERROR] 'codex' CLI not found in PATH." ; exit 1
fi
echo "[INFO] codex version: $(codex --version || echo 'unknown')"
echo "[INFO] container UTC time: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# === 1) Handle API-key mode (optional) ===
if [ "$USE_API_KEY" = "1" ]; then
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "[ERROR] USE_API_KEY=1 but OPENAI_API_KEY is empty."
    exit 1
  fi
  echo "[INFO] Using API-key auth via OPENAI_API_KEY (auth.json ignored)."
  # Keep CODEX_HOME unset in this branch to avoid confusion
else
  # === 2) File-based auth from the mounted host path ===
  if [ ! -f "${MOUNTED_CODEX_HOME}/auth.json" ]; then
    echo "[ERROR] No auth.json at ${MOUNTED_CODEX_HOME}/auth.json"
    echo "        Make sure you ran 'codex login' on the host and mounted \$HOME -> ~/hosts."
    exit 1
  fi

  # Ensure perms (not strictly required but avoids warnings)
  chmod 600 "${MOUNTED_CODEX_HOME}/auth.json" || true

  # Export CODEX_HOME so Codex looks there
  export CODEX_HOME="${MOUNTED_CODEX_HOME}"
  echo "[INFO] CODEX_HOME=${CODEX_HOME}"

  # Also create a ~/.codex symlink -> mounted path (defensive)
  if [ -e "${LOCAL_CODEX_HOME}" ] && [ ! -L "${LOCAL_CODEX_HOME}" ]; then
    # If a real directory/file exists, leave it (could be another token source)
    echo "[INFO] ${LOCAL_CODEX_HOME} exists (not a symlink). Leaving as-is."
  else
    rm -f "${LOCAL_CODEX_HOME}" 2>/dev/null || true
    ln -s "${MOUNTED_CODEX_HOME}" "${LOCAL_CODEX_HOME}"
    echo "[INFO] Symlinked ${LOCAL_CODEX_HOME} -> ${MOUNTED_CODEX_HOME}"
  fi

  # Guard against env overriding file auth
  if [ -n "${OPENAI_API_KEY:-}" ]; then
    echo "[WARN] OPENAI_API_KEY is set; Codex may prefer API-key auth over auth.json."
    echo "      If you intend to use the file token, unset it: 'unset OPENAI_API_KEY'."
  fi

  # Minimal visibility without leaking secrets
  echo "[INFO] Found token file. Details:"
  ls -l "${MOUNTED_CODEX_HOME}/auth.json" || true
fi

# === 3) Quick auth probe ===
# Try both paths: some builds prefer endpoints as commands, others flags
echo "[INFO] Probing Codex status…"
if ! codex /status 2>/tmp/codex_status.err; then
  STATUS_ERR="$(tr -d '\r' </tmp/codex_status.err | tail -n 3 || true)"
  echo "[WARN] 'codex /status' non-zero. Tail of error:"
  echo "$STATUS_ERR"
  # Try a lightweight whoami if present
  if codex /whoami >/dev/null 2>&1; then
    codex /whoami || true
  fi
fi

# === 4) Final hint if still 401 ===
# (We can’t programmatically detect, but we can suggest next steps.)
echo "[INFO] If you still see 401s when running Codex commands:"
echo "  - If using file auth: refresh the token on host -> 'codex login' (then retry)."
echo "  - Ensure container clock ≈ host clock (restart container if skewed)."
echo "  - Confirm you're the same user inside the container that owns \$HOME."
echo "  - Try API-key mode: 'export OPENAI_API_KEY=sk-...; export USE_API_KEY=1'."

# === 5) Hand off to user command (default: bash) ===
exec "$@"
