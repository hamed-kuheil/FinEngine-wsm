#!/usr/bin/env bash
# =============================================================================
# build_extension.sh — Package the Chrome Extension for Distribution
#
# This script:
#   1. Verifies the Wasm artifacts exist (build_wasm.sh must run first)
#   2. Validates the manifest.json version field
#   3. Removes development-only files from the package
#   4. Creates a production-ready .zip in dist/
#
# Usage:
#   ./build/build_extension.sh [--bump-patch | --bump-minor]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

EXTENSION_DIR="${REPO_ROOT}/extension-ui"
DIST_DIR="${REPO_ROOT}/dist"
MANIFEST="${EXTENSION_DIR}/manifest.json"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Read Version from manifest.json ──────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}[ERROR] python3 required for JSON parsing${RESET}"; exit 1
fi

VERSION=$(python3 -c "import json; print(json.load(open('${MANIFEST}'))['version'])")
echo -e "${CYAN}${BOLD}[FinEngine] Packaging extension v${VERSION}...${RESET}"

# ── Verify Wasm artifacts present ────────────────────────────────────────────
if [ ! -f "${EXTENSION_DIR}/wasm/finengine.wasm" ] || \
   [ ! -f "${EXTENSION_DIR}/wasm/finengine.js" ]; then
    echo -e "${RED}[ERROR] Wasm artifacts not found in extension-ui/wasm/${RESET}"
    echo -e "  Run: ./build/build_wasm.sh --release"
    exit 1
fi
echo -e "${GREEN}[OK] Wasm artifacts verified${RESET}"

# ── Create Package ────────────────────────────────────────────────────────────
mkdir -p "${DIST_DIR}"
OUTPUT="${DIST_DIR}/finengine-wasm-v${VERSION}.zip"

# Remove old package if it exists
[ -f "${OUTPUT}" ] && rm "${OUTPUT}"

cd "${EXTENSION_DIR}"
zip -r "${OUTPUT}" . \
    --exclude "*.DS_Store" \
    --exclude "*.map" \
    --exclude "*/.git/*" \
    --exclude "*/node_modules/*" \
    --exclude "*/__pycache__/*" \
    --exclude "*.test.js" \
    -q

echo -e "${GREEN}${BOLD}[FinEngine] Package ready: dist/finengine-wasm-v${VERSION}.zip${RESET}"
SIZE=$(du -sh "${OUTPUT}" | cut -f1)
echo -e "  Size: ${SIZE}"
