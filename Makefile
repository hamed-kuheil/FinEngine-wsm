# =============================================================================
# Makefile — FinEngine-Wasm Master Build Orchestration
#
# Usage:
#   make              → Full release build (Wasm + extension packaging)
#   make debug        → Debug build with source maps
#   make wasm         → Compile only the Wasm module (release)
#   make wasm-debug   → Compile only the Wasm module (debug)
#   make tests        → Build & run native C++ unit tests
#   make package      → Package extension into a distributable .zip
#   make clean        → Remove all build artifacts
#   make clean-wasm   → Remove only Wasm build artifacts
#   make setup        → Initialize git submodules (Crypto++ etc.)
#   make lint         → Run clang-tidy on C++ sources
#   make help         → Print this help message
# =============================================================================

.PHONY: all debug wasm wasm-debug tests package clean clean-wasm setup lint help

# ── Project Metadata ──────────────────────────────────────────────────────────
PROJECT_NAME    := finengine-wasm
VERSION         := 1.0.0
DIST_DIR        := dist
WASM_BUILD_DIR  := wasm-build
EXTENSION_DIR   := extension-ui
CPP_SRC_DIR     := backend-cpp/src
CRYPTOPP_DIR    := backend-cpp/third_party/cryptopp

# ── Shell & Colors ────────────────────────────────────────────────────────────
SHELL := /bin/bash
BOLD  := \033[1m
GREEN := \033[0;32m
CYAN  := \033[0;36m
RED   := \033[0;31m
RESET := \033[0m

# ── Tool Detection ─────────────────────────────────────────────────────────────
EMCC      := $(shell command -v emcc 2>/dev/null)
CLANG_TIDY := $(shell command -v clang-tidy 2>/dev/null)
ZIP        := $(shell command -v zip 2>/dev/null)

# ── Default: Full Release Build ───────────────────────────────────────────────
all: wasm
	@echo -e "$(GREEN)$(BOLD)[FinEngine] Full release build complete.$(RESET)"

debug: wasm-debug
	@echo -e "$(CYAN)$(BOLD)[FinEngine] Debug build complete.$(RESET)"

# ── Wasm Compilation ──────────────────────────────────────────────────────────
wasm:
ifndef EMCC
	$(error [ERROR] emcc not found. Activate the Emscripten SDK: source /path/to/emsdk/emsdk_env.sh)
endif
	@echo -e "$(CYAN)$(BOLD)[FinEngine] Compiling Wasm module (release)...$(RESET)"
	@chmod +x build/build_wasm.sh
	@./build/build_wasm.sh --release

wasm-debug:
ifndef EMCC
	$(error [ERROR] emcc not found. Activate the Emscripten SDK: source /path/to/emsdk/emsdk_env.sh)
endif
	@echo -e "$(CYAN)$(BOLD)[FinEngine] Compiling Wasm module (debug)...$(RESET)"
	@chmod +x build/build_wasm.sh
	@./build/build_wasm.sh --debug

# ── Native C++ Unit Tests ─────────────────────────────────────────────────────
# Tests compile directly with system clang++ (NOT Emscripten) for fast iteration.
# This does NOT test Wasm-specific behavior — it validates pure C++ logic.
TEST_SRCS := $(wildcard backend-cpp/tests/test_*.cpp)
TEST_BIN  := $(WASM_BUILD_DIR)/tests/run_tests

tests: $(TEST_BIN)
	@echo -e "$(CYAN)[FinEngine] Running native C++ tests...$(RESET)"
	@$(TEST_BIN) && echo -e "$(GREEN)$(BOLD)[FinEngine] All tests passed.$(RESET)"

$(TEST_BIN): $(TEST_SRCS) $(wildcard $(CPP_SRC_DIR)/*.cpp)
	@mkdir -p $(WASM_BUILD_DIR)/tests
	@clang++ \
		$(TEST_SRCS) \
		$(filter-out $(CPP_SRC_DIR)/wasm_bindings.cpp, $(wildcard $(CPP_SRC_DIR)/*.cpp)) \
		-std=c++20 \
		-I$(CPP_SRC_DIR) \
		-I$(CRYPTOPP_DIR) \
		-L$(CRYPTOPP_DIR) \
		-lcryptopp \
		-O2 \
		-DFINENGINE_NATIVE_TEST \
		-o $@ \
		2>&1 || (echo -e "$(RED)[ERROR] Test compilation failed. Is Crypto++ installed natively?$(RESET)"; exit 1)

# ── Package Extension for Distribution ────────────────────────────────────────
package: wasm
	@echo -e "$(CYAN)[FinEngine] Packaging extension...$(RESET)"
	@mkdir -p $(DIST_DIR)
	@cd $(EXTENSION_DIR) && \
		$(ZIP) -r ../$(DIST_DIR)/$(PROJECT_NAME)-v$(VERSION).zip . \
			--exclude "*.DS_Store" \
			--exclude "*/__pycache__/*" \
			--exclude "*.map"
	@echo -e "$(GREEN)$(BOLD)[FinEngine] Package created: $(DIST_DIR)/$(PROJECT_NAME)-v$(VERSION).zip$(RESET)"
	@du -sh $(DIST_DIR)/$(PROJECT_NAME)-v$(VERSION).zip

# ── Git Submodule Initialization ──────────────────────────────────────────────
setup:
	@echo -e "$(CYAN)[FinEngine] Initializing git submodules...$(RESET)"
	@git submodule update --init --recursive
	@echo -e "$(GREEN)[OK] Submodules initialized (Crypto++ ready at $(CRYPTOPP_DIR))$(RESET)"

# ── Linting ───────────────────────────────────────────────────────────────────
lint:
ifndef CLANG_TIDY
	$(error [ERROR] clang-tidy not found. Install via: apt install clang-tidy or brew install llvm)
endif
	@echo -e "$(CYAN)[FinEngine] Running clang-tidy...$(RESET)"
	@clang-tidy \
		$(wildcard $(CPP_SRC_DIR)/*.cpp) \
		-- \
		-std=c++20 \
		-I$(CPP_SRC_DIR) \
		-I$(CRYPTOPP_DIR) \
		-DCRYPTOPP_DISABLE_ASM

# ── Clean ─────────────────────────────────────────────────────────────────────
clean: clean-wasm
	@echo -e "$(CYAN)[FinEngine] Removing dist artifacts...$(RESET)"
	@rm -rf $(DIST_DIR)
	@echo -e "$(GREEN)[OK] All artifacts removed.$(RESET)"

clean-wasm:
	@echo -e "$(CYAN)[FinEngine] Removing Wasm build artifacts...$(RESET)"
	@rm -rf $(WASM_BUILD_DIR)
	@rm -f $(EXTENSION_DIR)/wasm/finengine.js
	@rm -f $(EXTENSION_DIR)/wasm/finengine.wasm
	@echo -e "$(GREEN)[OK] Wasm artifacts removed.$(RESET)"

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@echo -e "$(BOLD)FinEngine-Wasm Build System$(RESET)"
	@echo -e "──────────────────────────────────────────────────"
	@echo -e "  $(BOLD)make$(RESET)            Full release build"
	@echo -e "  $(BOLD)make debug$(RESET)      Debug build with source maps"
	@echo -e "  $(BOLD)make wasm$(RESET)       Compile Wasm module only (release)"
	@echo -e "  $(BOLD)make wasm-debug$(RESET) Compile Wasm module only (debug)"
	@echo -e "  $(BOLD)make tests$(RESET)      Build & run native C++ unit tests"
	@echo -e "  $(BOLD)make package$(RESET)    Package extension as .zip"
	@echo -e "  $(BOLD)make setup$(RESET)      Initialize git submodules"
	@echo -e "  $(BOLD)make lint$(RESET)       Run clang-tidy linter"
	@echo -e "  $(BOLD)make clean$(RESET)      Remove all build artifacts"
	@echo -e "  $(BOLD)make clean-wasm$(RESET) Remove only Wasm artifacts"
	@echo -e ""
	@echo -e "$(BOLD)Prerequisites:$(RESET)"
	@echo -e "  emcc (Emscripten SDK) — for Wasm compilation"
	@echo -e "  clang++ — for native C++ test compilation"
	@echo -e "  clang-tidy — for linting (optional)"
	@echo -e "  zip — for packaging"
