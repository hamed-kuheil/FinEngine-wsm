# ⚡ FinEngine-Wasm

### Local-First Financial Intelligence Engine

<div align="center">

<p align="center">
  <strong>High-Performance Browser Financial Engine Powered by C++ & WebAssembly</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WebAssembly-C++-654FF0?style=for-the-badge&logo=webassembly&logoColor=white"/>
  <img src="https://img.shields.io/badge/Security-AES--256--GCM-0F172A?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Architecture-Offline--First-10B981?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Chrome-MV3-F59E0B?style=for-the-badge&logo=googlechrome&logoColor=white"/>
  <img src="https://img.shields.io/badge/Language-C++17-00599C?style=for-the-badge&logo=cplusplus&logoColor=white"/>
</p>

<p align="center">
  Secure • Offline • Local-Only • Privacy-Focused
</p>

</div>

---

# 📖 Overview

**FinEngine-Wasm** is a modern privacy-first budgeting and financial computation platform that executes entirely inside the browser using **WebAssembly** and **modern C++**.

Unlike cloud-based financial tools, FinEngine-Wasm is built around a **local-first architecture**, ensuring that all sensitive financial data remains fully under user control.

No remote servers.
No external APIs.
No telemetry.
No cloud dependency.

All computation, encryption, and persistence occur locally within the browser sandbox.

---

# ✨ Key Features

## ⚡ High-Performance WebAssembly Runtime

* Native-speed financial computation using C++
* Deterministic browser-side execution
* Low-overhead Wasm runtime integration
* Optimized for performance-critical workloads

---

## 🔒 Advanced Security Architecture

* AES-256-GCM authenticated encryption
* Secure HKDF-based key derivation
* Cryptographically secure nonce generation
* Authenticated local persistence
* Sandboxed WebAssembly memory isolation

---

## 🌐 Fully Offline-First

* No backend infrastructure required
* Works entirely offline
* Local-only encrypted persistence
* Zero dependency on remote services

---

## 🧠 Financial Processing Engine

* Budget calculation engine
* Local transaction processing
* Expense aggregation
* Deterministic financial analysis
* Extensible modular computation core

---

## 🚀 Chrome Extension MV3 Support

* Manifest V3 compliant
* Strict Content Security Policy
* Secure extension runtime isolation
* Modern browser-extension architecture

---

# 🏗️ System Architecture

```text
┌────────────────────────────────────────────────────────────┐
│                   Chrome Extension UI                     │
│               Popup / Dashboard Interface                 │
└──────────────────────────┬─────────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────────┐
│                  JavaScript Runtime Layer                 │
│                     Embind Communication                  │
│                                                           │
│  • Browser API interaction                                │
│  • IndexedDB persistence                                  │
│  • Extension lifecycle management                         │
│  • UI orchestration                                       │
└───────────────┬───────────────────────┬───────────────────┘
                │                       │
┌───────────────▼────────────┐ ┌────────▼──────────────────┐
│     Local Persistence      │ │     WebAssembly Engine    │
│                             │ │        (C++ Core)         │
│  • IndexedDB               │ │                           │
│  • Encrypted storage       │ │  • Financial processing   │
│  • Offline-first design    │ │  • Encryption operations  │
│  • Local-only persistence  │ │  • Budget calculations    │
└────────────────────────────┘ └───────────────────────────┘
                │
┌───────────────▼───────────────────────────────────────────┐
│                    Security Components                    │
│                                                           │
│  • AES-256-GCM encryption                                │
│  • HKDF key derivation                                   │
│  • Secure nonce generation                               │
│  • Authenticated local persistence                       │
└───────────────────────────────────────────────────────────┘
```

---

# ⚙️ Runtime Separation Model

FinEngine-Wasm is intentionally divided into isolated execution environments to maximize both security and maintainability.

---

## 🧩 WebAssembly Core (C++)

Responsible for:

* Financial computations
* Encryption & decryption
* Secure memory operations
* Deterministic processing
* Performance-critical logic

---

## 🌐 JavaScript Runtime Layer

Responsible for:

* Browser API integration
* IndexedDB management
* Extension lifecycle handling
* UI rendering & orchestration
* Wasm module communication

---

## 🔄 Interoperability

Communication between JavaScript and WebAssembly occurs through:

* Embind-generated bindings
* Explicit serialization boundaries
* Controlled runtime interfaces

---

# 🔒 Security Model

| Security Concern  | Implementation                  |
| ----------------- | ------------------------------- |
| Data Encryption   | AES-256-GCM                     |
| Key Derivation    | HKDF-based derivation           |
| Authentication    | GCM authentication tags         |
| Randomness        | Cryptographically secure nonces |
| Persistence       | Encrypted IndexedDB             |
| Runtime Isolation | WebAssembly sandbox             |
| Browser Security  | Manifest V3 CSP                 |
| External Exposure | No outbound communication       |

---

# 📦 Technology Stack

| Layer            | Technology           |
| ---------------- | -------------------- |
| Core Engine      | C++17                |
| Compilation      | Emscripten           |
| Runtime          | WebAssembly          |
| Browser Platform | Chrome Extension MV3 |
| Storage          | IndexedDB            |
| Encryption       | AES-256-GCM          |
| Bindings         | Embind               |
| Build System     | GNU Make             |

---

# 🧱 Project Structure

```text
FinEngine-Wasm/
│
├── README.md
├── Makefile
├── manifest.json
│
├── src/
│   │
│   ├── core/
│   │   ├── FinanceEngine.cpp
│   │   ├── CryptoManager.cpp
│   │   └── StorageManager.cpp
│   │
│   ├── bindings/
│   │   └── embind.cpp
│   │
│   ├── js/
│   │   ├── popup.js
│   │   └── storage.js
│   │
│   └── ui/
│       ├── popup.html
│       └── styles.css
│
├── wasm/
│   ├── finengine.wasm
│   └── finengine.js
│
└── tests/
    └── test_crypto.cpp
```

---

# ⚡ Build & Development

## ✅ Prerequisites

| Dependency     | Required Version |
| -------------- | ---------------- |
| Emscripten SDK | Latest           |
| Clang++        | 14+              |
| Chrome         | 116+             |
| GNU Make       | Latest           |

---

# 📥 Clone Repository

```bash
git clone https://github.com/HamedKuheil/finengine-wasm.git

cd finengine-wasm
```

---

# ⚙️ Initialize Environment

```bash
make setup
```

---

# 🧪 Activate Emscripten

```bash
source /path/to/emsdk/emsdk_env.sh

emcc --version
```

---

# 🚀 Build Commands

## Production Build

```bash
make
```

## Debug Build

```bash
make debug
```

---

# 🛠️ Development Commands

```bash
make              # Production build
make debug        # Debug build + source maps
make tests        # Native C++ unit tests
make package      # Extension packaging
make lint         # Static analysis
make clean        # Remove artifacts
make help         # Show all commands
```

---

# 🌐 Load Extension in Chrome

## 1️⃣ Open Chrome Extensions

```text
chrome://extensions/
```

---

## 2️⃣ Enable Developer Mode

Turn on:

```text
Developer Mode
```

---

## 3️⃣ Load Extension

Click:

```text
Load unpacked
```

Then select:

```text
extension-ui/
```

---

# 🧪 Testing Strategy

The project emphasizes:

* Deterministic runtime behavior
* Local cryptographic validation
* Secure storage verification
* Native C++ unit testing
* Wasm runtime validation

---

# 🗺️ Development Roadmap

| Iteration   | Deliverable                          | Status        |
| ----------- | ------------------------------------ | ------------- |
| Iteration 1 | Wasm Runtime + Build System          | ✅ Complete    |
| Iteration 2 | AES-GCM Secure Persistence           | ⏳ In Progress |
| Iteration 3 | IndexedDB Synchronization Layer      | ⏳ Pending     |
| Iteration 4 | Full Chrome Extension UI             | ⏳ Pending     |
| Iteration 5 | Performance Optimization & Profiling | ⏳ Pending     |

---

# 🎯 Engineering Objectives

FinEngine-Wasm explores modern browser-side systems engineering including:

* WebAssembly integration
* Secure local-first architecture
* Browser cryptography
* High-performance C++ execution
* Offline-capable application design
* Privacy-focused software engineering
* Extension sandboxing strategies

---

# 🔐 Privacy Philosophy

FinEngine-Wasm follows a strict privacy-centric model:

✅ No cloud storage
✅ No telemetry
✅ No analytics
✅ No external APIs
✅ No remote synchronization

User financial data never leaves the local browser environment.

---

# 👨‍💻 Developer

## Hamed Kuheil

Computer Engineering & Software Engineering Student

### Areas of Interest

* WebAssembly
* Systems Programming
* Privacy Engineering
* Secure Software Design
* Low-level Optimization

---

# 📜 License

Licensed under the MIT License.

This project is intended for:

* Educational purposes
* Research experimentation
* Systems programming exploration
* Browser security research

---

<div align="center">

## ⚡ FinEngine-Wasm

### Secure Local Financial Computing — Powered by WebAssembly

</div>
