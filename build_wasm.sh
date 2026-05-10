#!/usr/bin/env bash
# =============================================================================
# build_wasm.sh — Emscripten Compilation Script for FinEngine-Wasm
#
# Prerequisites:
#   - Emscripten SDK (emsdk) installed and activated:
#       git clone https://github.com/emscripten-core/emsdk.git
#       cd emsdk && ./emsdk install latest && ./emsdk activate latest
#       source ./emsdk_env.sh
#   - Crypto++ sources present at: backend-cpp/third_party/cryptopp/
#       git submodule add https://github.com/weidai11/cryptopp.git backend-cpp/third_party/cryptopp
#
# Usage:
#   chmod +x build/build_wasm.sh
#   ./build/build_wasm.sh [--debug | --release]
#
# Output:
#   wasm-build/finengine.wasm
#   wasm-build/finengine.js
# =============================================================================

set -euo pipefail  # Exit on error, undefined variable, or pipe failure
IFS=$'\n\t'        # Strict word splitting

# ── Terminal Colors ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Project Paths (relative to repo root) ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CPP_SRC="${REPO_ROOT}/backend-cpp/src"
CRYPTOPP_DIR="${REPO_ROOT}/backend-cpp/third_party/cryptopp"
WASM_OUT="${REPO_ROOT}/wasm-build"
EXTENSION_WASM_DIR="${REPO_ROOT}/extension-ui/wasm"

# ── Build Mode ─────────────────────────────────────────────────────────────────
BUILD_MODE="${1:---release}"  # Default to release build

# ── Validate Environment ───────────────────────────────────────────────────────
validate_environment() {
    echo -e "${CYAN}${BOLD}[FinEngine-Wasm] Validating build environment...${RESET}"

    if ! command -v emcc &>/dev/null; then
        echo -e "${RED}[ERROR] emcc not found. Please activate the Emscripten SDK:${RESET}"
        echo -e "  source /path/to/emsdk/emsdk_env.sh"
        exit 1
    fi

    EMCC_VERSION=$(emcc --version | head -n1)
    echo -e "${GREEN}[OK] Emscripten: ${EMCC_VERSION}${RESET}"

    if [ ! -d "${CRYPTOPP_DIR}" ]; then
        echo -e "${RED}[ERROR] Crypto++ not found at: ${CRYPTOPP_DIR}${RESET}"
        echo -e "  Run: git submodule update --init --recursive"
        exit 1
    fi
    echo -e "${GREEN}[OK] Crypto++ found at: ${CRYPTOPP_DIR}${RESET}"

    if [ ! -f "${CPP_SRC}/wasm_bindings.cpp" ]; then
        echo -e "${RED}[ERROR] Source files missing in: ${CPP_SRC}${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[OK] C++ source files found${RESET}"
}

# ── Build Crypto++ as Static Library for Wasm ─────────────────────────────────
# Crypto++ must be cross-compiled for the Wasm target.
# We only compile the subset of files needed for AES-256-GCM.
build_cryptopp() {
    echo -e "\n${CYAN}${BOLD}[FinEngine-Wasm] Compiling Crypto++ for Wasm target...${RESET}"

    local CRYPTOPP_BUILD="${WASM_OUT}/cryptopp_obj"
    mkdir -p "${CRYPTOPP_BUILD}"

    # Crypto++ files required for AES-256-GCM + SHA-256 + HKDF
    local CRYPTOPP_SOURCES=(
        "aes.cpp"
        "algebra.cpp"
        "algparam.cpp"
        "allocate.cpp"
        "asn.cpp"
        "authenc.cpp"        # Authenticated encryption (GCM base)
        "base64.cpp"
        "basecode.cpp"
        "cpu.cpp"
        "cryptlib.cpp"
        "default.cpp"
        "des.cpp"
        "filters.cpp"
        "fips140.cpp"
        "gcm.cpp"            # GCM mode
        "gfpcrypt.cpp"
        "hex.cpp"
        "hkdf.cpp"           # HKDF key derivation
        "integer.cpp"
        "iterhash.cpp"
        "misc.cpp"
        "modes.cpp"
        "mqueue.cpp"
        "nbtheory.cpp"
        "osrng.cpp"
        "pkcspad.cpp"
        "pubkey.cpp"
        "queue.cpp"
        "randpool.cpp"
        "rijndael.cpp"       # AES (Rijndael) implementation
        "rijndael-simd.cpp"
        "secblock.cpp"
        "sha.cpp"            # SHA-256 for key derivation
        "sha3.cpp"
        "simple.cpp"
        "strciphr.cpp"
    )

    local COMPILED_OBJECTS=()

    for src in "${CRYPTOPP_SOURCES[@]}"; do
        local src_path="${CRYPTOPP_DIR}/${src}"
        local obj_path="${CRYPTOPP_BUILD}/${src%.cpp}.o"

        if [ ! -f "${src_path}" ]; then
            echo -e "${YELLOW}[WARN] Skipping missing Crypto++ file: ${src}${RESET}"
            continue
        fi

        emcc "${src_path}" \
            -c \
            -o "${obj_path}" \
            -std=c++20 \
            -I"${CRYPTOPP_DIR}" \
            -O3 \
            -DCRYPTOPP_DISABLE_ASM \
            -DCRYPTOPP_DISABLE_SSSE3 \
            -DCRYPTOPP_DISABLE_AESNI \
            -fno-exceptions \
            2>/dev/null || {
                echo -e "${YELLOW}[WARN] Failed to compile ${src} — skipping${RESET}"
                continue
            }

        COMPILED_OBJECTS+=("${obj_path}")
    done

    # Archive into static library
    emar rcs "${WASM_OUT}/libcryptopp.a" "${COMPILED_OBJECTS[@]}"
    echo -e "${GREEN}[OK] Crypto++ static library built: wasm-build/libcryptopp.a${RESET}"
}

# ── Compile FinEngine C++ Sources ──────────────────────────────────────────────
compile_finengine() {
    echo -e "\n${CYAN}${BOLD}[FinEngine-Wasm] Compiling FinEngine C++ sources...${RESET}"

    mkdir -p "${WASM_OUT}"

    # Source files — order matters for dependency resolution
    local SOURCES=(
        "${CPP_SRC}/encryptor.cpp"
        "${CPP_SRC}/budget_engine.cpp"
        "${CPP_SRC}/forecaster.cpp"
        "${CPP_SRC}/transaction_store.cpp"
        "${CPP_SRC}/wasm_bindings.cpp"
    )

    # ── Optimization & Debug Flags ─────────────────────────────────────────────
    local OPT_FLAGS
    local DEBUG_FLAGS
    if [ "${BUILD_MODE}" = "--debug" ]; then
        OPT_FLAGS="-O0 -g4 --source-map-base ./"  # Full debug info + source maps
        DEBUG_FLAGS="-DDEBUG -DFINENGINE_DEBUG"
        echo -e "${YELLOW}[BUILD MODE] Debug — optimizations disabled, source maps enabled${RESET}"
    else
        OPT_FLAGS="-O3 -flto"  # Aggressive optimization + link-time optimization
        DEBUG_FLAGS="-DNDEBUG"
        echo -e "${GREEN}[BUILD MODE] Release — full optimization enabled${RESET}"
    fi

    # ── Emscripten Linker Flags ────────────────────────────────────────────────
    # -s MODULARIZE=1          : Wraps output in a factory function (avoids polluting global scope)
    # -s EXPORT_NAME           : Name of the factory function importable in JS
    # -s ALLOW_MEMORY_GROWTH=1 : Allows Wasm heap to grow dynamically (required for variable data)
    # -s MAXIMUM_MEMORY        : Hard cap at 256MB (prevents runaway allocation)
    # -s INITIAL_MEMORY        : Start with 32MB heap
    # -s NO_EXIT_RUNTIME=1     : Prevents Wasm runtime teardown (extension is long-running)
    # -s FILESYSTEM=0          : Disable Emscripten's virtual FS (we don't need it, saves ~200KB)
    # -s ENVIRONMENT           : Target web + web worker contexts only
    # -s EXPORTED_RUNTIME_METHODS: Expose specific Emscripten runtime helpers to JS
    # --bind                   : Enable Embind (JS ↔ C++ binding system)
    # -s STRICT=1              : Enforce strict Emscripten mode (catches common mistakes)

    emcc \
        "${SOURCES[@]}" \
        "${WASM_OUT}/libcryptopp.a" \
        \
        -std=c++20 \
        -I"${CPP_SRC}" \
        -I"${CRYPTOPP_DIR}" \
        \
        ${OPT_FLAGS} \
        ${DEBUG_FLAGS} \
        \
        -s MODULARIZE=1 \
        -s EXPORT_NAME="FinEngineWasm" \
        -s ALLOW_MEMORY_GROWTH=1 \
        -s MAXIMUM_MEMORY=268435456 \
        -s INITIAL_MEMORY=33554432 \
        -s NO_EXIT_RUNTIME=1 \
        -s FILESYSTEM=0 \
        -s ENVIRONMENT="web,worker" \
        -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","stringToUTF8","lengthBytesUTF8","stackAlloc","stackRestore","stackSave"]' \
        -s STRICT=1 \
        -s ASSERTIONS=0 \
        --bind \
        \
        -o "${WASM_OUT}/finengine.js"

    echo -e "${GREEN}[OK] Wasm module compiled:${RESET}"
    echo -e "      ${WASM_OUT}/finengine.js"
    echo -e "      ${WASM_OUT}/finengine.wasm"

    # ── Print file sizes ───────────────────────────────────────────────────────
    local JS_SIZE WASM_SIZE
    JS_SIZE=$(du -sh "${WASM_OUT}/finengine.js" | cut -f1)
    WASM_SIZE=$(du -sh "${WASM_OUT}/finengine.wasm" | cut -f1)
    echo -e "${CYAN}  Glue JS:    ${JS_SIZE}${RESET}"
    echo -e "${CYAN}  Wasm binary: ${WASM_SIZE}${RESET}"
}

# ── Copy Artifacts to Extension ────────────────────────────────────────────────
copy_to_extension() {
    echo -e "\n${CYAN}${BOLD}[FinEngine-Wasm] Copying Wasm artifacts to extension...${RESET}"

    mkdir -p "${EXTENSION_WASM_DIR}"

    cp "${WASM_OUT}/finengine.js"   "${EXTENSION_WASM_DIR}/finengine.js"
    cp "${WASM_OUT}/finengine.wasm" "${EXTENSION_WASM_DIR}/finengine.wasm"

    echo -e "${GREEN}[OK] Artifacts copied to: extension-ui/wasm/${RESET}"
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  FinEngine-Wasm Build Script${RESET}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

    validate_environment
    build_cryptopp
    compile_finengine
    copy_to_extension

    echo -e "\n${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  Build complete!"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  Load the extension from: ${BOLD}extension-ui/${RESET}"
    echo -e "  Chrome → Extensions → Load Unpacked → select extension-ui/"
}

main "$@"
