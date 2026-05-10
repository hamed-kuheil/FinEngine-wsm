# FinEngine-Wasm — Project Structure

```
finengine-wasm/
│
├── README.md                          # Project overview & setup guide
├── PROJECT_STRUCTURE.md               # This file
│
├── backend-cpp/                       # All C++ source code (compiled to Wasm)
│   ├── src/
│   │   ├── budget_engine.cpp          # Core allocation logic (50/30/20, custom rules)
│   │   ├── budget_engine.h
│   │   ├── forecaster.cpp             # Burn rate & depletion date projections
│   │   ├── forecaster.h
│   │   ├── encryptor.cpp              # AES-256-GCM via Crypto++ (local encryption)
│   │   ├── encryptor.h
│   │   ├── transaction_store.cpp      # In-memory transaction management
│   │   ├── transaction_store.h
│   │   └── wasm_bindings.cpp          # Embind: JS ↔ C++ bridge (single entry point)
│   │
│   ├── third_party/
│   │   └── cryptopp/                  # Crypto++ library headers & sources (submodule)
│   │
│   └── tests/                         # Native C++ unit tests (run without Wasm)
│       ├── test_budget_engine.cpp
│       ├── test_forecaster.cpp
│       └── test_encryptor.cpp
│
├── wasm-build/                        # Compiled Wasm output (git-ignored in prod)
│   ├── finengine.wasm                 # Binary Wasm module (generated)
│   ├── finengine.js                   # Emscripten JS glue code (generated)
│   └── finengine.d.ts                 # TypeScript definitions (optional, for IDE support)
│
├── extension-ui/                      # Chrome Extension source
│   ├── manifest.json                  # MV3 manifest (root of extension)
│   │
│   ├── background/
│   │   └── service_worker.js          # MV3 service worker: Wasm host, message router
│   │
│   ├── content/
│   │   └── dom_scanner.js             # Content script: detects prices on e-commerce sites
│   │
│   ├── popup/
│   │   ├── popup.html                 # Extension popup shell
│   │   ├── popup.js                   # Popup logic: Wasm bridge + UI rendering
│   │   └── popup.css                  # Tailwind + custom styles (compiled or CDN)
│   │
│   ├── options/
│   │   ├── options.html               # Full settings page (salary, rules, categories)
│   │   └── options.js
│   │
│   ├── lib/
│   │   ├── wasm_bridge.js             # Shared Wasm module loader & API wrapper
│   │   ├── storage_manager.js         # Abstraction over chrome.storage + IndexedDB
│   │   └── message_bus.js             # Type-safe message routing constants & helpers
│   │
│   ├── assets/
│   │   ├── icons/
│   │   │   ├── icon16.png
│   │   │   ├── icon32.png
│   │   │   ├── icon48.png
│   │   │   └── icon128.png
│   │   └── fonts/                     # Self-hosted fonts (optional, for offline use)
│   │
│   └── wasm/                          # Copied from wasm-build/ at build time
│       ├── finengine.wasm
│       └── finengine.js
│
├── build/
│   ├── Makefile                       # Master build orchestration
│   ├── build_wasm.sh                  # Emscripten compilation script
│   ├── build_extension.sh             # Packages extension-ui/ + copies Wasm artifacts
│   └── build_tests.sh                 # Compiles & runs native C++ tests
│
└── dist/                              # Final packaged extension (git-ignored)
    └── finengine-wasm-vX.Y.Z.zip      # Ready-to-load Chrome extension package
```

## Directory Responsibilities

| Directory         | Owner Layer  | Description                                        |
|-------------------|--------------|----------------------------------------------------|
| `backend-cpp/`    | C++ / Wasm   | Pure C++ logic, zero browser APIs                 |
| `wasm-build/`     | Build output | Emscripten artifacts, never manually edited        |
| `extension-ui/`   | JS / HTML    | All browser-facing code, no C++ dependencies      |
| `build/`          | DevOps       | Build scripts, Makefiles, toolchain config         |
| `dist/`           | Release      | Final zipped extension for Chrome Web Store        |

## Data Flow Summary

```
[User Input / DOM Scan]
        │
        ▼
[Content Script: dom_scanner.js]
        │  chrome.runtime.sendMessage
        ▼
[Service Worker: service_worker.js]
        │  postMessage → Wasm
        ▼
[C++ Wasm Module]
   budget_engine ──► encryptor ──► serialized JSON
        │
        ▼
[storage_manager.js]
   chrome.storage.local + IndexedDB (encrypted blobs)
        │
        ▼
[Popup UI: popup.js]
   Decrypted data ──► Chart rendering ──► User display
```
