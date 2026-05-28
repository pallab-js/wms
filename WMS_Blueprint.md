# WarehouseOS — Enterprise macOS Desktop App
## Complete Development Blueprint: Swift + SwiftUI, GitHub + Spec-Kit

> **Platform:** macOS 14 Sonoma+ (Apple Silicon, M1 optimised)  
> **Stack:** Swift 5.10 / SwiftUI / SwiftData / CloudKit  
> **Tooling:** Git, GitHub, Spec-Kit, OpenCode AI  
> **Developer:** Solo, vibecoding workflow  
> **Target:** Production-ready, enterprise-grade desktop application  

---

## Table of Contents

1. [Project Vision & Scope](#1-project-vision--scope)
2. [Architecture Overview](#2-architecture-overview)
3. [Tech Stack & Tooling Rationale](#3-tech-stack--tooling-rationale)
4. [Environment Setup](#4-environment-setup)
5. [Repository Structure](#5-repository-structure)
6. [Git & GitHub Workflow](#6-git--github-workflow)
7. [Spec-Kit Workflow](#7-spec-kit-workflow)
8. [AI Vibecoding Protocol (Anti-Hallucination)](#8-ai-vibecoding-protocol-anti-hallucination)
9. [Development Phases Overview](#9-development-phases-overview)
10. [Phase 0 — Foundation & Scaffolding](#10-phase-0--foundation--scaffolding)
11. [Phase 1 — MVP](#11-phase-1--mvp)
12. [Phase 2 — Core Business Features](#12-phase-2--core-business-features)
13. [Phase 3 — Advanced Operations](#13-phase-3--advanced-operations)
14. [Phase 4 — Analytics & Reporting](#14-phase-4--analytics--reporting)
15. [Phase 5 — Production Hardening](#15-phase-5--production-hardening)
16. [Data Layer Design](#16-data-layer-design)
17. [Testing Strategy](#17-testing-strategy)
18. [Security & Compliance](#18-security--compliance)
19. [Distribution & Deployment](#19-distribution--deployment)
20. [Living Document Protocol](#20-living-document-protocol)

---

## 1. Project Vision & Scope

### 1.1 Product Summary

**WarehouseOS** is a standalone macOS desktop application designed for business organisations that operate multiple physical warehouses. It provides a single, unified control plane for inventory management, employee oversight, inbound/outbound logistics, and operational analytics — all running natively on macOS with optional iCloud-based sync.

### 1.2 Core Problem Statement

Organisations managing multiple warehouses typically rely on fragmented spreadsheets, disconnected tools, or expensive ERP systems requiring web access and ongoing subscriptions. WarehouseOS solves this by delivering a fast, offline-capable, native macOS application that feels purpose-built for warehouse operations, with the performance and reliability that only a native app provides.

### 1.3 User Personas

**Warehouse Administrator** — configures warehouses, manages employee access, and oversees global operations across all locations.

**Warehouse Manager** — manages day-to-day operations for one or more specific warehouses: stock levels, employee shifts, and transfer orders.

**Inventory Clerk** — records inbound/outbound stock movements, performs stocktakes, and flags discrepancies.

**Analyst/Owner** — reads dashboards, generates reports, and reviews KPIs without interacting with operational records.

### 1.4 Scope Boundaries (MVP vs Final)

| Feature Area | MVP | Final |
|---|---|---|
| Warehouse CRUD | ✅ | ✅ |
| Employee management | ✅ | ✅ |
| Inventory items catalogue | ✅ | ✅ |
| Stock-in / Stock-out recording | ✅ | ✅ |
| Basic dashboard | ✅ | ✅ |
| Multi-warehouse transfers | ❌ | ✅ |
| Role-based access control | ❌ | ✅ |
| Barcode/QR scanning | ❌ | ✅ |
| Alerts & threshold notifications | ❌ | ✅ |
| Advanced analytics & charts | ❌ | ✅ |
| PDF report export | ❌ | ✅ |
| iCloud sync | ❌ | ✅ |
| Audit log | ❌ | ✅ |
| CSV import/export | ❌ | ✅ |

---

## 2. Architecture Overview

### 2.1 Architectural Pattern

The application follows a strict **MVVM + Repository + Service Layer** architecture, deliberately chosen for SwiftUI's data-binding model and long-term testability.

```
┌─────────────────────────────────────────────────────────┐
│                       SwiftUI Views                      │
│           (Declarative UI, no business logic)            │
└──────────────────────┬──────────────────────────────────┘
                       │  @StateObject / @ObservedObject
┌──────────────────────▼──────────────────────────────────┐
│                    ViewModels                            │
│    (State management, input validation, UI logic)        │
└──────────────────────┬──────────────────────────────────┘
                       │  Protocol-based calls
┌──────────────────────▼──────────────────────────────────┐
│                  Service Layer                           │
│   (Business rules, domain logic, orchestration)         │
└──────────────────────┬──────────────────────────────────┘
                       │  Repository protocol
┌──────────────────────▼──────────────────────────────────┐
│               Repository Layer                          │
│   (Abstracts persistence; SwiftData implementation)     │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              SwiftData + CloudKit                        │
│     (Local persistence + optional iCloud sync)          │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Module Boundaries

The project is divided into Swift Package Manager (SPM) local packages to enforce strict separation and prevent circular dependencies:

- `WMSCore` — Domain models, protocols, and business rules. Has zero UI or persistence dependencies.
- `WMSData` — SwiftData models, repository implementations, migration handlers.
- `WMSServices` — Service layer implementations consuming `WMSCore` protocols.
- `WMSFeatures` — Feature-specific ViewModels and SwiftUI views, one sub-module per feature.
- `WMSDesignSystem` — Reusable UI components, typography tokens, color scheme.
- `WMSApp` — App entry point, dependency injection root, navigation coordinator.

### 2.3 Navigation Architecture

Use **NavigationSplitView** (three-column on large screens, two-column on smaller) as the macOS-native navigation paradigm. A centrally managed `AppRouter` observable object drives programmatic navigation, preventing scattered navigation state across views.

### 2.4 Dependency Injection

A lightweight, hand-rolled DI container at the app root injects services and repositories into ViewModels via the SwiftUI `Environment`. Avoid third-party DI frameworks to keep the dependency graph transparent and debuggable.

---

## 3. Tech Stack & Tooling Rationale

### 3.1 Core Stack

| Component | Choice | Rationale |
|---|---|---|
| Language | Swift 5.10 | Type-safe, modern, first-class Apple support |
| UI Framework | SwiftUI | Declarative, macOS-native, future-proof |
| Persistence | SwiftData | Native, CoreData-backed, CloudKit-compatible |
| Sync | CloudKit (optional) | Zero-cost for solo apps, iCloud-native |
| Charts | Swift Charts | Native, composable, zero external deps |
| Testing | XCTest + Swift Testing | Native, no overhead |
| Formatting | swift-format | Consistent code style |

### 3.2 Development Tooling

| Tool | Purpose |
|---|---|
| Git | Local version control |
| GitHub | Remote repository, project management |
| GitHub Spec-Kit | Specification management, feature planning |
| GitHub Issues | Bug tracking, feature requests |
| GitHub Projects (Kanban) | Sprint and phase tracking |
| GitHub Actions | CI: build, lint, test on push |
| OpenCode AI | AI-assisted code generation (vibecoding) |
| Xcode 16+ | IDE, simulator, Instruments |
| xcbeautify | Human-readable Xcode build output in terminal |
| swiftlint | Static analysis and style enforcement |

### 3.3 What to Explicitly Avoid

Avoid adding third-party dependencies unless absolutely necessary. Every external package is a maintenance burden. The following are banned unless a specific phase demands them with no native alternative: Alamofire (use URLSession), Realm (use SwiftData), SnapKit (use SwiftUI layout), Kingfisher (use AsyncImage), any reactive framework (use Combine or async/await natively).

---

## 4. Environment Setup

### 4.1 System Prerequisites

Perform these steps once before any code is written.

```bash
# 1. Verify Xcode 16+ is installed from the App Store
xcode-select --version
xcodebuild -version  # must be 16.0 or higher

# 2. Accept Xcode licence
sudo xcodebuild -license accept

# 3. Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 4. Install essential CLI tools
brew install git
brew install gh           # GitHub CLI
brew install swiftlint
brew install swift-format
brew install xcbeautify

# 5. Install OpenCode (follow official docs for current install method)
# https://opencode.ai — install via their documented method

# 6. Configure Git identity
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main

# 7. Authenticate GitHub CLI
gh auth login
```

### 4.2 Spec-Kit Installation

GitHub Spec-Kit is a CLI tool for managing software specifications as structured markdown files linked to GitHub Issues and pull requests.

```bash
# Install via GitHub CLI extension (check official repo for current method)
gh extension install github/spec-kit

# Verify installation
gh spec --version

# Initialise spec-kit in the repository root (run after repo is created)
gh spec init
```

### 4.3 Xcode Project Settings (one-time)

After creating the Xcode project, configure these settings immediately and commit them:

- Set Deployment Target to **macOS 14.0**.
- Set Swift Language Version to **Swift 5**.
- Enable **Strict Concurrency Checking** (set to `Complete` under Swift compiler settings).
- Add `com.apple.security.app-sandbox` to entitlements (required for Mac App Store).
- Add `com.apple.developer.ubiquity-kvstore-identifier` and CloudKit entitlements (even if unused in MVP — avoids a re-provision later).
- Set the bundle identifier to a reverse-domain format: `com.yourorg.warehouseos`.

---

## 5. Repository Structure

```
warehouseos/
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                    # Build + lint + test on PR
│   │   └── release.yml               # Notarise + archive on tag
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── pull_request_template.md
│   └── CODEOWNERS
│
├── specs/                            # Spec-Kit managed specifications
│   ├── 00-product-vision.md
│   ├── 01-architecture.md
│   ├── 02-data-models.md
│   ├── phase-1/
│   │   └── *.spec.md
│   ├── phase-2/
│   │   └── *.spec.md
│   └── ...
│
├── WarehouseOS/                      # Main Xcode project
│   ├── WarehouseOS.xcodeproj/
│   ├── WarehouseOS/                  # App target
│   │   ├── App/
│   │   │   ├── WarehouseOSApp.swift
│   │   │   ├── AppRouter.swift
│   │   │   └── DependencyContainer.swift
│   │   ├── Resources/
│   │   │   ├── Assets.xcassets
│   │   │   └── Localizable.strings
│   │   └── Preview Content/
│   │
│   └── WarehouseOSTests/
│       ├── Unit/
│       ├── Integration/
│       └── Snapshots/
│
├── Packages/                         # Local SPM packages
│   ├── WMSCore/
│   │   ├── Package.swift
│   │   └── Sources/WMSCore/
│   │       ├── Models/               # Domain models (structs)
│   │       ├── Protocols/            # Repository + service protocols
│   │       └── Errors/
│   ├── WMSData/
│   │   ├── Package.swift
│   │   └── Sources/WMSData/
│   │       ├── SwiftDataModels/      # @Model classes
│   │       ├── Repositories/
│   │       └── Migrations/
│   ├── WMSServices/
│   │   ├── Package.swift
│   │   └── Sources/WMSServices/
│   ├── WMSFeatures/
│   │   ├── Package.swift
│   │   └── Sources/
│   │       ├── Warehouses/
│   │       ├── Inventory/
│   │       ├── Employees/
│   │       ├── Transfers/
│   │       ├── Reports/
│   │       └── Settings/
│   └── WMSDesignSystem/
│       ├── Package.swift
│       └── Sources/WMSDesignSystem/
│           ├── Components/
│           ├── Typography.swift
│           └── ColorTheme.swift
│
├── Scripts/
│   ├── setup.sh                      # One-shot dev environment setup
│   ├── lint.sh
│   └── generate-docs.sh
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   └── CHANGELOG.md
│
├── .swiftlint.yml
├── .swift-format
├── .gitignore
├── README.md
└── BLUEPRINT.md                      # This document
```

---

## 6. Git & GitHub Workflow

### 6.1 Branching Strategy

Use a simplified **Git Flow** adapted for a solo developer with AI-assisted coding:

```
main          ← production-ready, tagged releases only
develop       ← integration branch, always stable
feature/*     ← one branch per spec/feature
fix/*         ← bug fixes against develop
release/*     ← release candidate preparation
```

**Rule:** Never commit directly to `main` or `develop`. All changes enter through a pull request, even when working solo — this forces you to review AI-generated code before it merges.

### 6.2 Commit Convention

Use **Conventional Commits** format. This makes the changelog auto-generatable and keeps AI-generated commit messages structured.

```
<type>(<scope>): <short summary>

Types: feat | fix | refactor | test | docs | chore | perf | ci
Scope: warehouses | inventory | employees | transfers | reports | data | ui | ci

Examples:
feat(inventory): add low-stock threshold alert model
fix(warehouses): resolve crash on empty warehouse list
test(employees): add unit tests for EmployeeService.deactivate
chore(ci): update swiftlint to 0.56
```

### 6.3 Pull Request Protocol

Every PR must include:

1. Reference to its Spec-Kit spec: `Closes spec #XX`.
2. A brief description of what changed and why.
3. Evidence that tests pass (CI badge or screenshot).
4. Self-review checklist completed.

The PR template (`.github/pull_request_template.md`) should enforce this automatically.

### 6.4 Tagging & Releases

```bash
# Tag a release
git tag -a v0.1.0 -m "MVP release: core warehouse and inventory management"
git push origin v0.1.0

# GitHub Actions release workflow triggers on tag push
# It archives, notarises, and creates a GitHub Release automatically
```

Use semantic versioning: `MAJOR.MINOR.PATCH`. During development phases, use `0.x.y`. Promote to `1.0.0` only when Phase 5 is complete and the app is production-ready.

### 6.5 .gitignore Configuration

```gitignore
# Xcode
*.xcuserstate
xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3

# Build
build/
*.o
*.d

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Swift Package Manager
.build/
.swiftpm/

# Secrets — NEVER commit these
*.p12
*.mobileprovision
*.cer
Secrets.plist
Config.xcconfig   # if it contains secrets

# OpenCode AI
.opencode/cache/
```

---

## 7. Spec-Kit Workflow

### 7.1 What Spec-Kit Does

Spec-Kit (by GitHub) manages **feature specifications** as structured markdown files living in the `specs/` directory of the repository. Each spec defines what a feature should do, its acceptance criteria, and its relationship to GitHub Issues. This creates a tight loop between specification, implementation, and verification — critical when using AI to write code.

### 7.2 Spec Anatomy

Every spec file follows this template:

```markdown
---
spec-id: WMS-012
title: Inventory Low-Stock Alert
phase: 2
status: draft | approved | in-progress | complete
linked-issue: #45
---

## Summary
One paragraph describing what this feature is and why it exists.

## Context & Background
Business context, any prior decisions, constraints.

## Detailed Requirements

### Functional Requirements
- FR-01: The system SHALL display a warning badge on any SKU whose current
  quantity falls at or below its defined minimum threshold.
- FR-02: The user SHALL be able to configure the minimum threshold per SKU.
- FR-03: The system SHALL send a macOS notification when a threshold is crossed.

### Non-Functional Requirements
- NFR-01: Threshold evaluation SHALL complete within 50ms of a stock movement.
- NFR-02: The feature SHALL function fully offline.

## Data Model Impact
List any new or changed SwiftData models.

## UI/UX Notes
Wireframe description or ASCII sketch if helpful.

## Acceptance Criteria
- [ ] GIVEN a SKU with minimum threshold 10, WHEN stock falls to 9, THEN a 
      badge appears in the inventory list.
- [ ] GIVEN the badge is displayed, WHEN the user clicks it, THEN the edit 
      threshold sheet opens.
- [ ] Unit test coverage ≥ 80% for InventoryAlertService.

## Out of Scope
Explicitly list what this spec does NOT cover.

## Open Questions
Any unresolved decisions to settle before implementation starts.
```

### 7.3 Spec Lifecycle

```
draft → review → approved → in-progress → complete → archived
```

A spec must be in `approved` state before any implementation branch is created. This discipline prevents writing code against ambiguous requirements — one of the primary causes of AI hallucination during vibecoding.

### 7.4 Spec-First Development Rule

**Always write or update the spec before opening OpenCode.** The spec is the source of truth you hand to the AI. Never prompt an AI coding assistant with vague intent like "add inventory tracking." Instead, reference the approved spec and prompt with precision (see Section 8).

---

## 8. AI Vibecoding Protocol (Anti-Hallucination)

This section is one of the most critical in this blueprint. AI coding assistants (including OpenCode) are powerful but will hallucinate confidently — inventing APIs, proposing architectures that contradict your spec, or drifting from established patterns if not tightly guided. The following protocol minimises that risk.

### 8.1 The Golden Rules

**Rule 1 — Spec First, Prompt Second.** Never start a coding session without an approved spec open in front of you. The spec is the boundary. If the AI proposes something outside it, stop and reject it.

**Rule 2 — One Spec Per Session.** Each OpenCode session should address exactly one spec. Context switching mid-session introduces drift.

**Rule 3 — Atomic Tasks.** Even within a spec, break work into the smallest coherent unit. "Implement the InventoryItem SwiftData model with all fields from spec WMS-002" is better than "start building inventory."

**Rule 4 — Always Show Context.** Begin every OpenCode session by pasting the relevant spec, the current data model file, and any protocol definitions the AI will implement against. Never assume it remembers context from a prior session.

**Rule 5 — Review Before Commit.** All AI-generated code must be read line-by-line before being committed. The PR review step (even solo) is your hallucination checkpoint.

**Rule 6 — Do Not Accept Dependency Additions.** If the AI suggests adding a third-party package not in your approved stack (see Section 3.3), reject it and ask for a native alternative. Log the suggestion in the spec's Open Questions.

**Rule 7 — Verify API Existence.** SwiftData, SwiftUI, and Swift APIs change frequently. If the AI uses an API you do not recognise, verify it in Apple's official documentation before accepting the code. Do not trust that the AI's usage is correct for your deployment target.

### 8.2 Prompt Engineering Patterns

Use these prompt patterns consistently when working in OpenCode:

**Pattern 1 — Context Load:**
```
I am building a macOS SwiftUI app called WarehouseOS using SwiftData for 
persistence. The architecture is MVVM + Repository + Service Layer. Local SPM 
packages are used for module separation. I am now implementing [spec title] 
(spec ID: WMS-0XX). Here is the spec: [paste spec]. Here is the current 
state of the relevant file(s): [paste files]. Do not add dependencies. 
Do not modify files outside the scope of this spec.
```

**Pattern 2 — Model Generation:**
```
Based on the data model section of spec WMS-0XX, generate the SwiftData @Model 
class for [ModelName]. It should live in the WMSData package. Match these exact 
field names and types: [list from spec]. Include a corresponding domain model 
struct in WMSCore. Do not add any fields not listed in the spec.
```

**Pattern 3 — Test Generation:**
```
Write XCTest unit tests for [ServiceName] in WMSServicesTests. Tests must cover 
all acceptance criteria in spec WMS-0XX. Use mock repositories conforming to the 
protocols in WMSCore. Do not test persistence directly — test through the 
service layer only.
```

**Pattern 4 — Correction Loop:**
```
The code you generated fails to compile. Here is the exact error: [paste error]. 
Do not change the architecture or introduce new dependencies to fix this. 
Identify the minimal change needed.
```

### 8.3 Anti-Patterns to Actively Avoid

Do not ask the AI open-ended questions like "what is the best way to build inventory tracking?" — you will get a generic answer that ignores your architecture. Instead, ask "given this repository protocol [paste protocol], write a concrete SwiftData implementation."

Do not accept refactoring suggestions that span multiple modules unless you have scheduled a dedicated refactor session with its own spec. AI-driven scope creep is a major productivity killer.

Do not let the AI rename your symbols. Consistent naming is a team contract. If the AI renames `WarehouseRepository` to `WarehouseStore`, reject it.

### 8.4 Hallucination Log

Maintain a file at `docs/AI_HALLUCINATION_LOG.md`. When the AI produces confidently wrong output (non-existent API, wrong architecture, fantasy framework), log it:

```markdown
| Date | Session | AI Output | Correct Reality | Action Taken |
|------|---------|-----------|----------------|--------------|
| 2025-01-15 | WMS-005 | Used `.modelContext.insert()` on a background actor without @ModelActor isolation | SwiftData requires @ModelActor for background contexts | Rejected, implemented with correct actor isolation |
```

This log becomes invaluable over time — it teaches you where the AI is consistently wrong and helps you pre-empt errors in future prompts.

---

## 9. Development Phases Overview

| Phase | Name | Duration (est.) | Key Deliverable |
|---|---|---|---|
| 0 | Foundation & Scaffolding | 1–2 weeks | Runnable app skeleton, CI live |
| 1 | MVP | 3–4 weeks | Core warehouse + inventory management |
| 2 | Core Business Features | 4–5 weeks | Employees, transfers, alerts |
| 3 | Advanced Operations | 3–4 weeks | RBAC, barcode scanning, audit log |
| 4 | Analytics & Reporting | 3–4 weeks | Charts, PDF export, CSV I/O |
| 5 | Production Hardening | 2–3 weeks | Performance, accessibility, App Store |

Total estimated duration for solo development: **16–22 weeks**.

---

## 10. Phase 0 — Foundation & Scaffolding

### 10.1 Goals

By the end of Phase 0, you have a runnable macOS app skeleton with all infrastructure in place: CI pipeline, linting, module structure, design system tokens, and an empty but navigable three-column layout.

### 10.2 Steps

**Step 0.1 — Repository Initialisation**

```bash
# Create the GitHub repository
gh repo create warehouseos --private --description "Enterprise warehouse management for macOS"

# Clone and set up
git clone https://github.com/yourorg/warehouseos.git
cd warehouseos

# Create initial branch structure
git checkout -b develop
git push -u origin develop
```

**Step 0.2 — Xcode Project Creation**

Open Xcode. Create a new project: macOS → App. Name it `WarehouseOS`. Select SwiftUI interface, SwiftData storage. Place it inside the cloned repository directory.

Immediately after creation:
- Delete the auto-generated `ContentView.swift` and `Item.swift` — you will replace them with proper module-structured files.
- Configure all Xcode settings from Section 4.3.
- Add `.gitignore` (see Section 6.5).
- Make an initial commit: `chore: initialise xcode project skeleton`.

**Step 0.3 — Local SPM Packages**

Create each package listed in Section 5. For each:

```bash
# Example for WMSCore
mkdir -p Packages/WMSCore/Sources/WMSCore
cat > Packages/WMSCore/Package.swift << 'EOF'
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WMSCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WMSCore", targets: ["WMSCore"])
    ],
    targets: [
        .target(name: "WMSCore"),
        .testTarget(name: "WMSCoreTests", dependencies: ["WMSCore"])
    ]
)
EOF
```

Add each package to the Xcode project via File → Add Package Dependencies → Add Local.

**Step 0.4 — Design System Bootstrap**

In `WMSDesignSystem`, create the foundational tokens that all UI will use. This prevents design drift and makes theming trivial.

```swift
// ColorTheme.swift
import SwiftUI

public extension Color {
    static let wmsAccent        = Color("AccentColor", bundle: .module)
    static let wmsSurface       = Color("SurfaceColor", bundle: .module)
    static let wmsBackground    = Color("BackgroundColor", bundle: .module)
    static let wmsDestructive   = Color("DestructiveColor", bundle: .module)
    static let wmsWarning       = Color("WarningColor", bundle: .module)
    static let wmsSuccess       = Color("SuccessColor", bundle: .module)
}

// Typography.swift
public extension Font {
    static let wmsLargeTitle    = Font.largeTitle.weight(.bold)
    static let wmsTitle         = Font.title2.weight(.semibold)
    static let wmsHeadline      = Font.headline
    static let wmsBody          = Font.body
    static let wmsCaption       = Font.caption.weight(.medium)
    static let wmsMonospace     = Font.system(.body, design: .monospaced)
}
```

**Step 0.5 — App Shell Navigation**

Implement the three-column `NavigationSplitView` skeleton in `WMSApp` with placeholder views for each section. The sidebar should already show all final navigation destinations as greyed-out stubs.

```swift
// AppRouter.swift
@Observable
final class AppRouter {
    var selectedSection: AppSection? = .warehouses
    var selectedWarehouseID: PersistentIdentifier?
}

enum AppSection: String, CaseIterable, Identifiable {
    case warehouses, inventory, employees, transfers, reports, settings
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String { /* SF Symbol name per case */ }
}
```

**Step 0.6 — CI Pipeline**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [develop]
  pull_request:
    branches: [develop, main]

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app
      
      - name: SwiftLint
        run: swiftlint --strict
      
      - name: Build
        run: |
          xcodebuild build \
            -project WarehouseOS/WarehouseOS.xcodeproj \
            -scheme WarehouseOS \
            -destination "platform=macOS" \
            | xcbeautify
      
      - name: Test
        run: |
          xcodebuild test \
            -project WarehouseOS/WarehouseOS.xcodeproj \
            -scheme WarehouseOS \
            -destination "platform=macOS" \
            | xcbeautify
```

**Step 0.7 — Spec-Kit Initialisation**

```bash
gh spec init

# Create foundational specs
gh spec create "Product Vision" --phase 0
gh spec create "Architecture Decisions" --phase 0
gh spec create "Data Model Design" --phase 0
```

Write and approve these three foundational specs before writing any feature code. They are your architectural constitution.

**Phase 0 Completion Checklist:**
- [ ] Repository live on GitHub with `main` and `develop` branches
- [ ] All six SPM packages created and linked in Xcode
- [ ] Design system tokens defined
- [ ] App compiles and runs to a visible (empty) window
- [ ] CI pipeline passes on `develop`
- [ ] SwiftLint configured and passing
- [ ] Spec-Kit initialised with foundational specs approved
- [ ] All Phase 1 specs written in `draft` state
- [ ] Git tag `v0.0.1` applied

---

## 11. Phase 1 — MVP

### 11.1 Goals

A functional warehouse management application where an administrator can create and manage warehouses, define an inventory catalogue, and record stock movements. No authentication, no multi-user sync, no advanced features — but the core workflow is complete and usable.

### 11.2 Specs to Write and Approve First

Write and get to `approved` status before writing any implementation code:

- `WMS-101`: Warehouse entity — create, read, update, delete
- `WMS-102`: Inventory item catalogue — SKU management
- `WMS-103`: Stock movement recording — stock-in and stock-out
- `WMS-104`: Dashboard — per-warehouse summary view
- `WMS-105`: Application settings — organisation name, units of measure

### 11.3 Feature: Warehouse Management (WMS-101)

**Data Model (WMSData):**

```swift
@Model
final class WarehouseEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var code: String                  // Short identifier, e.g. "WH-001"
    var address: String
    var capacity: Int                 // Maximum storage units
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var inventoryItems: [InventoryItemEntity] = []
    
    init(name: String, code: String, address: String, capacity: Int) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.address = address
        self.capacity = capacity
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**Domain Model (WMSCore):**

```swift
// Pure struct — no persistence concerns
public struct Warehouse: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var code: String
    public var address: String
    public var capacity: Int
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date
}
```

**Repository Protocol (WMSCore):**

```swift
public protocol WarehouseRepository: Sendable {
    func fetchAll() async throws -> [Warehouse]
    func fetch(byID id: UUID) async throws -> Warehouse?
    func save(_ warehouse: Warehouse) async throws
    func delete(id: UUID) async throws
}
```

**Service Layer (WMSServices):**

```swift
public final class WarehouseService {
    private let repository: any WarehouseRepository
    
    public init(repository: any WarehouseRepository) {
        self.repository = repository
    }
    
    public func createWarehouse(name: String, code: String, 
                                 address: String, capacity: Int) async throws -> Warehouse {
        // Validate: name non-empty, code unique, capacity > 0
        // Business rule enforcement lives here, not in the view model
    }
    
    public func deactivateWarehouse(id: UUID) async throws {
        // Check for pending transfers before deactivating
    }
}
```

**ViewModel (WMSFeatures/Warehouses):**

```swift
@Observable
@MainActor
final class WarehouseListViewModel {
    var warehouses: [Warehouse] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let service: WarehouseService
    
    init(service: WarehouseService) {
        self.service = service
    }
    
    func loadWarehouses() async {
        isLoading = true
        do {
            warehouses = try await service.getAllWarehouses()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

### 11.4 Feature: Inventory Catalogue (WMS-102)

Define `InventoryItemEntity` with these fields: `id`, `sku` (unique), `name`, `description`, `category`, `unitOfMeasure`, `currentQuantity`, `minimumThreshold` (stub for Phase 2), `unitCost`, `warehouseID`, `isActive`, `createdAt`, `updatedAt`.

Implement full CRUD following the same layered pattern as Warehouse. This pattern — Domain Model → Repository Protocol → SwiftData Implementation → Service → ViewModel → View — is the template for every feature in the application. Establish it correctly here and do not deviate.

### 11.5 Feature: Stock Movements (WMS-103)

Stock movements are append-only records. Never edit or delete a movement — this is a fundamental accounting principle and a non-negotiable design constraint.

```swift
@Model
final class StockMovementEntity {
    @Attribute(.unique) var id: UUID
    var movementType: MovementType     // .stockIn | .stockOut | .adjustment
    var quantity: Int                  // Always positive; type determines direction
    var note: String?
    var referenceNumber: String?       // e.g. purchase order number
    var recordedAt: Date
    var recordedByUserID: UUID?        // Null in MVP, used in Phase 3 RBAC
    
    var itemID: UUID                   // Denormalised for query performance
    var warehouseID: UUID
    
    // Relationships
    var inventoryItem: InventoryItemEntity?
}

enum MovementType: String, Codable {
    case stockIn, stockOut, adjustment
}
```

The `InventoryService.recordMovement()` method must atomically update `InventoryItemEntity.currentQuantity` and insert the movement record within a single `ModelContext` transaction.

### 11.6 Feature: Dashboard (WMS-104)

The dashboard is a read-only summary view. Do not put any mutation logic here. It should display:

- Total warehouses (active count)
- Total SKUs across all warehouses
- Total inventory value (sum of `currentQuantity × unitCost`)
- A list of warehouses with their utilisation percentage (`currentTotalItems / capacity`)
- Recent stock movements (last 10 records)

Use `Swift Charts` for the utilisation bar chart. Do not use any third-party charting library.

### 11.7 Phase 1 Completion Checklist

- [ ] All WMS-10x specs at `complete` status
- [ ] Warehouse CRUD works end-to-end
- [ ] Inventory item CRUD works end-to-end
- [ ] Stock-in and stock-out recording works
- [ ] Dashboard shows accurate aggregated data
- [ ] Settings: organisation name persists
- [ ] Unit test coverage ≥ 75% for all Service classes
- [ ] No SwiftLint violations
- [ ] CI passes
- [ ] App runs without crash on macOS 14
- [ ] Git tag `v0.1.0` applied, GitHub Release created

---

## 12. Phase 2 — Core Business Features

### 12.1 Goals

Elevate the MVP to a complete single-organisation tool by adding employee management, warehouse-to-warehouse transfer orders, low-stock alerting, and application-level search.

### 12.2 Specs to Write and Approve

- `WMS-201`: Employee management — profile, role stub, warehouse assignment
- `WMS-202`: Transfer orders — request, approve, execute, complete
- `WMS-203`: Low-stock alerts — threshold monitoring and macOS notifications
- `WMS-204`: Global search — warehouses, SKUs, employees
- `WMS-205`: CSV import — bulk SKU import from spreadsheet

### 12.3 Feature: Employee Management (WMS-201)

An `Employee` record contains: `id`, `firstName`, `lastName`, `employeeCode`, `jobTitle`, `email`, `phone`, `warehouseAssignments` (many-to-many with warehouses), `isActive`, `hireDate`, `notes`.

The many-to-many warehouse assignment is important architecture: an employee can manage multiple warehouses, and a warehouse has many employees.

```swift
@Model
final class EmployeeEntity {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var lastName: String
    @Attribute(.unique) var employeeCode: String
    var jobTitle: String
    var email: String
    var isActive: Bool
    var hireDate: Date
    
    @Relationship(inverse: \WarehouseEntity.employees)
    var warehouses: [WarehouseEntity] = []
}
```

Add `var employees: [EmployeeEntity] = []` to `WarehouseEntity` with the matching inverse relationship.

### 12.4 Feature: Transfer Orders (WMS-202)

Transfer orders represent the movement of stock from one warehouse to another. This is a multi-step workflow with states.

```
Transfer Order States:
DRAFT → SUBMITTED → APPROVED → IN_TRANSIT → COMPLETED
                  ↓            ↓
               CANCELLED    CANCELLED
```

A `TransferOrderEntity` contains: `id`, `transferCode`, `status`, `sourceWarehouseID`, `destinationWarehouseID`, `requestedDate`, `completedDate`, `notes`, and a `@Relationship` to `TransferLineItemEntity` records.

Each `TransferLineItemEntity` references an inventory item, a requested quantity, and an actually-transferred quantity (which may differ if stock is partially available).

State transitions are enforced in `TransferService`, not in the view layer. The view can only call `requestTransfer()`, `approveTransfer()`, `completeTransfer()`, and `cancelTransfer()` — it cannot directly mutate the status field.

Stock quantity is only deducted from the source warehouse when the transfer reaches `IN_TRANSIT`, and added to the destination when it reaches `COMPLETED`. This is an explicit accounting rule — document it in the spec and in code comments.

### 12.5 Feature: Low-Stock Alerts (WMS-203)

After every stock movement, `InventoryAlertService` evaluates whether any affected item is now at or below its `minimumThreshold`. If so, it posts a macOS `UNUserNotification` and stores an `AlertRecord` in SwiftData.

```swift
// Request notification permission at app launch (once)
UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in }

// Alert posting
func postLowStockNotification(for item: InventoryItem, in warehouse: Warehouse) {
    let content = UNMutableNotificationContent()
    content.title = "Low Stock Alert"
    content.body = "\(item.name) in \(warehouse.name) is below minimum threshold."
    content.sound = .default
    let request = UNNotificationRequest(
        identifier: "low-stock-\(item.id)",
        content: content,
        trigger: nil  // deliver immediately
    )
    UNUserNotificationCenter.current().add(request)
}
```

An in-app `AlertsCentre` sidebar badge should reflect the count of unacknowledged alerts.

### 12.6 Phase 2 Completion Checklist

- [ ] All WMS-20x specs at `complete` status
- [ ] Employee CRUD and warehouse assignment works
- [ ] Transfer order full state machine works
- [ ] Low-stock notifications fire correctly after stock-out
- [ ] Global search returns results from all entity types
- [ ] CSV import works for at least 500 rows without UI freeze (use async background context)
- [ ] Unit test coverage ≥ 80% for new service classes
- [ ] Git tag `v0.2.0` applied

---

## 13. Phase 3 — Advanced Operations

### 13.1 Goals

Add role-based access control, barcode/QR code scanning via AVFoundation, a comprehensive audit log, and multi-warehouse analytics foundations.

### 13.2 Specs to Write and Approve

- `WMS-301`: Role-based access control — roles, permissions, user context
- `WMS-302`: Barcode and QR code scanning — AVFoundation-based scanner
- `WMS-303`: Audit log — immutable record of all mutations
- `WMS-304`: Supplier management — supplier profiles, PO associations
- `WMS-305`: Product categories and tagging system

### 13.3 Feature: Role-Based Access Control (WMS-301)

In a single-user desktop app, RBAC functions as a **permission profile system** rather than multi-user authentication. The current user selects (or is assigned) a role at setup, which restricts what UI controls and operations are available. This design also prepares the architecture for future multi-user support without a breaking change.

Define four roles: `Administrator`, `WarehouseManager`, `InventoryClerk`, `Analyst`.

```swift
// In WMSCore
public enum UserRole: String, Codable, CaseIterable {
    case administrator, warehouseManager, inventoryClerk, analyst
    
    public var permissions: Set<Permission> { /* define per role */ }
}

public enum Permission: String, Codable {
    case createWarehouse, editWarehouse, deleteWarehouse
    case createEmployee, editEmployee, deactivateEmployee
    case recordStockIn, recordStockOut, adjustStock
    case createTransfer, approveTransfer
    case viewReports, exportData
    case manageSettings
}
```

Inject the current `UserSession` (holding the active role) into the environment. Views check `userSession.can(.createWarehouse)` before showing action buttons. ViewModels validate permissions before calling services.

### 13.4 Feature: Barcode/QR Scanning (WMS-302)

macOS supports `AVCaptureSession` with an attached camera. Build a `BarcodeScannerView` using `NSViewRepresentable` that wraps an `AVCaptureVideoPreviewLayer`. The scanner publishes scanned codes via `Combine`'s `PassthroughSubject` or an `AsyncStream`.

Barcode scanning is used in two contexts: looking up an inventory item by scanning its label, and recording a stock movement by scanning first the item barcode then a shelf/location barcode.

This feature requires the `NSCameraUsageDescription` key in `Info.plist`.

### 13.5 Feature: Audit Log (WMS-303)

Every create, update, delete, and state transition must produce an `AuditEntry`. This is a non-negotiable enterprise requirement.

```swift
@Model
final class AuditEntryEntity {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var entityType: String           // "Warehouse", "InventoryItem", etc.
    var entityID: UUID
    var action: String               // "created", "updated", "deleted", etc.
    var changedFields: Data?         // JSON-encoded diff of changed fields
    var userRole: String
    var note: String?
}
```

Audit entries are immutable — no delete or update operations exist on this entity. The repository only exposes `insert(_:)` and `fetchAll(filter:sort:)`.

Create an `AuditLogger` actor that services call after successful mutations. It should never throw into the calling context — audit failure should log to the system console but not block the business operation.

### 13.6 Phase 3 Completion Checklist

- [ ] All WMS-30x specs at `complete` status
- [ ] Role selection in Settings restricts UI controls correctly
- [ ] Barcode scanner opens, scans, and populates item fields
- [ ] Every mutation produces a corresponding audit entry
- [ ] Audit log view is filterable by entity type, date range, and action
- [ ] Supplier profiles link to inventory items
- [ ] Git tag `v0.3.0` applied

---

## 14. Phase 4 — Analytics & Reporting

### 14.1 Goals

Deliver the analytics and reporting capabilities that transform the app from an operational tool into a business intelligence platform: interactive charts, period-over-period comparisons, and exportable PDF/CSV reports.

### 14.2 Specs to Write and Approve

- `WMS-401`: Analytics dashboard — time-series charts, KPI cards
- `WMS-402`: PDF report generation — inventory, movement, employee reports
- `WMS-403`: CSV export — all entity types
- `WMS-404`: Date-range filtering — global date filter context
- `WMS-405`: Inventory valuation report — FIFO/average cost methods

### 14.3 Feature: Analytics Dashboard (WMS-401)

Build the analytics view using `Swift Charts` exclusively. Key charts to implement:

**Stock Movement Trend** — a line chart showing daily stock-in vs stock-out volume over a selectable period (7 days, 30 days, 90 days, custom range).

**Warehouse Utilisation** — a grouped bar chart comparing current utilisation vs capacity across all active warehouses.

**Top Moving SKUs** — a horizontal bar chart of the 10 most frequently moved inventory items by transaction count.

**Inventory Value Over Time** — an area chart showing total inventory value at end-of-day for the selected period. This requires storing daily snapshots; implement a background task that runs at midnight to record the snapshot.

For every chart, implement an accessible text summary (a sentence describing the chart's key insight) for VoiceOver users.

### 14.4 Feature: PDF Reports (WMS-402)

Use native `PDFKit` combined with `NSAttributedString` and `NSPrintOperation` for PDF generation. Do not use any third-party PDF library.

Build a `ReportRenderer` class that accepts a `ReportDefinition` (title, sections, data) and produces a `Data` object containing the PDF. Provide a sheet in the app for the user to preview, configure page layout, and export.

Report types to implement: Inventory Status Report, Stock Movement History, Employee Roster, Transfer Order History, and Warehouse Summary.

### 14.5 Feature: CSV Export (WMS-403)

```swift
public struct CSVExporter {
    public static func export<T: CSVExportable>(_ items: [T]) -> String {
        let header = T.csvHeaders.joined(separator: ",")
        let rows = items.map { $0.csvRow.joined(separator: ",") }
        return ([header] + rows).joined(separator: "\n")
    }
}

public protocol CSVExportable {
    static var csvHeaders: [String] { get }
    var csvRow: [String] { get }
}
```

All major entities should conform to `CSVExportable`. Present exports through `NSSavePanel` for the user to choose a destination.

### 14.6 Phase 4 Completion Checklist

- [ ] All WMS-40x specs at `complete` status
- [ ] All five chart types render correctly with live data
- [ ] Charts update reactively when underlying data changes
- [ ] PDF export produces a properly formatted, printable document
- [ ] CSV export writes clean, properly escaped files
- [ ] Date range filter applies globally across all analytics views
- [ ] Inventory valuation report shows total value with method selector
- [ ] Git tag `v0.4.0` applied

---

## 15. Phase 5 — Production Hardening

### 15.1 Goals

Prepare the application for real-world enterprise use and Mac App Store distribution. This phase is about quality, reliability, performance, accessibility, and polish — not new features.

### 15.2 Performance Profiling

Use Xcode Instruments with the following instruments:

**Time Profiler** — identify any operations on the main thread that take longer than 16ms (one frame at 60Hz). All database queries, file I/O, and network calls must be confirmed off the main thread.

**Memory Graph Debugger** — identify and resolve retain cycles, especially in `@Observable` ViewModels and `@Relationship` SwiftData entities.

**Hangs and Main Thread Checker** — eliminate all main thread hangs. The app must remain responsive under any load.

**Core Data / SwiftData Instruments** — profile fetch queries. Any query taking more than 100ms should have an index added to the relevant `@Attribute` in the SwiftData model.

Target performance thresholds for production:
- App cold launch to interactive: < 2 seconds
- Any list view with 10,000 records: loads in < 500ms
- Chart rendering: < 300ms for any dataset up to 12 months
- Stock movement recording: < 100ms round-trip including audit log

### 15.3 Memory Management

Implement pagination for all list views that may contain large datasets. Use `FetchDescriptor` with `fetchLimit` and `fetchOffset` for SwiftData queries. Never load the entire database into memory for display purposes.

```swift
// Example paginated fetch
var descriptor = FetchDescriptor<InventoryItemEntity>(
    predicate: #Predicate { $0.isActive == true },
    sortBy: [SortDescriptor(\.name)]
)
descriptor.fetchLimit = 50
descriptor.fetchOffset = page * 50
```

### 15.4 Accessibility

Run Xcode's Accessibility Inspector against every screen and resolve all critical issues:

- Every interactive control must have an `accessibilityLabel`.
- All charts must have `accessibilityChartDescriptor` providing a text summary.
- All custom components must support keyboard navigation.
- Verify the app is fully usable with VoiceOver enabled.
- Honour system settings for Reduce Motion, Increase Contrast, and larger text sizes.
- Minimum tap target size: 44×44 points for any tappable element.

### 15.5 Error Handling & Resilience

Implement a global error handling strategy. Every `async throws` call in a ViewModel must be caught, categorised, and surfaced to the user through a consistent UI pattern (a dismissible error banner at the top of the affected view, not a blocking alert for non-critical errors).

Define a `WMSError` enum in `WMSCore` that maps all domain errors to user-facing messages:

```swift
public enum WMSError: LocalizedError {
    case duplicateWarehouseCode(String)
    case insufficientStock(itemName: String, available: Int, requested: Int)
    case transferAlreadyCompleted
    case persistenceFailed(underlying: Error)
    // ... etc.
    
    public var errorDescription: String? { /* user-friendly message */ }
    public var recoverySuggestion: String? { /* actionable advice */ }
}
```

### 15.6 iCloud Sync (Optional but Recommended)

SwiftData with CloudKit sync is enabled by changing the `ModelContainer` configuration:

```swift
let schema = Schema([
    WarehouseEntity.self,
    InventoryItemEntity.self,
    // ... all entities
])
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .automatic  // enables CloudKit sync
)
```

Before enabling, verify: all `@Attribute` types are CloudKit-compatible (no `UUID` primary keys — use `@Attribute(.unique)` which CloudKit handles), all relationships have inverses defined, and all models conform to `Codable` where needed.

### 15.7 App Sandbox & Entitlements

For Mac App Store submission, the app must be sandboxed. Review and set these entitlements in `WarehouseOS.entitlements`:

```xml
<key>com.apple.security.app-sandbox</key>       <true/>
<key>com.apple.security.files.user-selected.read-write</key>  <true/>  <!-- for CSV/PDF export -->
<key>com.apple.security.device.camera</key>     <true/>  <!-- for barcode scanning -->
<key>com.apple.security.network.client</key>    <true/>  <!-- for CloudKit -->
```

### 15.8 Notarisation & Distribution

```bash
# Archive the app
xcodebuild archive \
  -scheme WarehouseOS \
  -archivePath WarehouseOS.xcarchive

# Export for distribution (uses exportOptions.plist)
xcodebuild -exportArchive \
  -archivePath WarehouseOS.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/

# Notarise with Apple (requires Apple Developer account)
xcrun notarytool submit ./build/WarehouseOS.dmg \
  --apple-id your@email.com \
  --team-id YOURTEAMID \
  --password "@keychain:AC_PASSWORD" \
  --wait

# Staple notarisation ticket
xcrun stapler staple ./build/WarehouseOS.dmg
```

Automate this entire flow in `.github/workflows/release.yml` triggered by a `v*.*.*` tag push.

### 15.9 Phase 5 Completion Checklist

- [ ] All Instruments profiling sessions completed, no critical issues
- [ ] All list views paginated
- [ ] Accessibility Inspector: no critical issues on any screen
- [ ] VoiceOver manual review completed
- [ ] `WMSError` enum covers all thrown errors
- [ ] Error UI tested: every error surfaces a visible, actionable message
- [ ] App sandbox entitlements finalised
- [ ] App passes `codesign --verify` and `spctl --assess`
- [ ] Notarisation succeeds
- [ ] App submitted to Mac App Store (or distributed via signed DMG)
- [ ] `CHANGELOG.md` up to date
- [ ] All specs at `complete` or `archived` status
- [ ] Git tag `v1.0.0` applied
- [ ] GitHub Release created with release notes and DMG attached

---

## 16. Data Layer Design

### 16.1 Model Relationship Map

```
Organisation (singleton)
    └── Warehouse (1:many)
            ├── InventoryItem (1:many)
            │       └── StockMovement (1:many, append-only)
            │       └── AlertRecord (1:many)
            ├── Employee (many:many via WarehouseEmployee join)
            └── TransferOrder (as source or destination)
                    └── TransferLineItem (1:many)

Supplier (independent)
    └── InventoryItem (many:many via SupplierItem join)

AuditEntry (global, no relationships — stores entity refs as UUIDs)
```

### 16.2 SwiftData Migration Strategy

As the app evolves across phases, SwiftData models will change. Manage migrations explicitly rather than relying on automatic migration (which silently drops data on conflicts).

```swift
// In WMSData, define a migration plan
enum WMSMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        WMSSchemaV1.self,
        WMSSchemaV2.self,
        // ... add with each breaking schema change
    ]
    
    static var stages: [MigrationStage] = [
        .lightweight(fromVersion: WMSSchemaV1.self, toVersion: WMSSchemaV2.self)
        // Use .custom for migrations requiring data transformation
    ]
}
```

Create a new `VersionedSchema` enum at the start of each phase that introduces breaking model changes. Never add non-optional fields to an existing model without a migration stage.

### 16.3 Query Performance Guidelines

Index every field that appears in a `#Predicate` filter or `SortDescriptor`. Add `@Attribute(.index)` to: `WarehouseEntity.code`, `InventoryItemEntity.sku`, `StockMovementEntity.recordedAt`, `AuditEntryEntity.timestamp`, `AuditEntryEntity.entityType`.

For complex cross-entity aggregations (e.g. total value per warehouse), write a dedicated `AnalyticsRepository` that uses raw `FetchDescriptor` queries rather than pulling all entities into memory and aggregating in Swift.

---

## 17. Testing Strategy

### 17.1 Test Pyramid

```
            ┌──────┐
           /  E2E   \       ~5%  — UI Tests via XCUITest
          /──────────\
         / Integration \    ~20% — Service + Repository integration tests
        /──────────────\           using in-memory SwiftData store
       /   Unit Tests   \  ~75% — Pure service and domain logic tests
      /──────────────────\         using mock repositories
```

### 17.2 Unit Testing Pattern

All unit tests use mock repository implementations injected via protocol. Tests are fast (no disk I/O) and deterministic.

```swift
// Mock repository for testing
final class MockWarehouseRepository: WarehouseRepository {
    var warehouses: [Warehouse] = []
    var shouldThrow = false
    
    func fetchAll() async throws -> [Warehouse] {
        if shouldThrow { throw WMSError.persistenceFailed(underlying: TestError.mock) }
        return warehouses
    }
    // ... other protocol methods
}

// Example unit test
@Test func createWarehouse_withDuplicateCode_throwsError() async throws {
    let repo = MockWarehouseRepository()
    repo.warehouses = [Warehouse.fixture(code: "WH-001")]
    let service = WarehouseService(repository: repo)
    
    await #expect(throws: WMSError.self) {
        try await service.createWarehouse(name: "Test", code: "WH-001", 
                                          address: "", capacity: 100)
    }
}
```

### 17.3 Integration Testing Pattern

Use an in-memory `ModelContainer` for integration tests:

```swift
@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: WarehouseEntity.self, 
                              InventoryItemEntity.self,
                              configurations: config)
}
```

Integration tests verify that the full Service → Repository → SwiftData stack works correctly, without hitting the real filesystem.

### 17.4 Test Coverage Targets

| Package | Target Coverage |
|---|---|
| WMSCore | 90% (pure domain logic) |
| WMSServices | 80% |
| WMSData | 70% |
| WMSFeatures | 50% (ViewModels only) |

Views (SwiftUI) are not unit tested — they are validated through UI tests and manual QA.

### 17.5 Snapshot Testing

Use XCTest's built-in `XCTAttachment` to capture view snapshots during key UI states and attach them to test results. This does not require a third-party framework and provides a visual record of UI regressions.

---

## 18. Security & Compliance

### 18.1 Data at Rest

SwiftData stores data in the app's sandboxed container at `~/Library/Application Support/com.yourorg.warehouseos/`. This directory is:

- Excluded from iCloud Drive (unless CloudKit sync is enabled deliberately)
- Excluded from Time Machine backups by default (add `NSURLIsExcludedFromBackupKey` key if needed)
- Protected by macOS's built-in file system permissions

For organisations requiring encryption at rest, enable FileVault on the host machine (OS-level) or implement an encrypted SQLite database using SQLCipher — but only if the customer explicitly requires it, as this adds significant complexity.

### 18.2 Sensitive Data Handling

Employee personal data (email, phone) and business data (inventory costs, supplier pricing) are sensitive. Follow these rules without exception:

- Never log sensitive fields to `os_log`, `print`, or any crash reporter.
- Never include sensitive data in error messages surfaced to the UI.
- Store any credentials (future cloud integrations) exclusively in the macOS Keychain using `Security.framework`.
- Never store credentials in `UserDefaults`, `AppStorage`, or any plist file.

### 18.3 Input Validation

All user input is validated at the Service layer before being written to the database. The ViewModel performs lightweight format validation (non-empty, correct character set) for immediate UI feedback. The Service performs business rule validation (uniqueness, referential integrity, range checks). Never trust the ViewModel's validation from the service layer.

---

## 19. Distribution & Deployment

### 19.1 Distribution Options

**Option A — Mac App Store:** Requires Apple Developer Program membership, sandbox compliance, and App Store review. Provides automatic updates, billing integration, and discoverability. Recommended for consumer or SMB deployment.

**Option B — Direct Distribution (Notarised DMG):** Signed and notarised by Apple but distributed outside the App Store (via email, company website, or MDM). Allows more permissive entitlements and avoids App Review. Recommended for enterprise internal distribution.

**Option C — Developer ID Distribution:** Same as B but uses a Developer ID certificate rather than the Mac App Store provisioning profile.

For an enterprise warehouse management system, **Option B** is recommended: it avoids App Store restrictions on entitlements while maintaining Gatekeeper compatibility (macOS will not block the app on launch).

### 19.2 Versioning for Updates

After v1.0.0, follow semantic versioning strictly:

- `PATCH` (e.g. 1.0.1): bug fixes only, no new features, no schema migrations
- `MINOR` (e.g. 1.1.0): new features that are backward-compatible; may include schema migrations
- `MAJOR` (e.g. 2.0.0): breaking changes, major architectural shifts, UI overhauls

### 19.3 Update Mechanism

For direct distribution (Option B), integrate **Sparkle** (the standard macOS update framework) to deliver automatic updates. Sparkle is the one third-party dependency that is explicitly permitted and expected in this project for production builds.

---

## 20. Living Document Protocol

This blueprint is a living document. It must be updated as the project evolves.

### 20.1 When to Update This Blueprint

Update `BLUEPRINT.md` when:

- An architectural decision changes (record the old decision, new decision, and rationale)
- A phase's scope changes significantly
- A new technology or tool is adopted (update Sections 3 and the affected phase)
- A phase is completed (mark it as complete with the completion date and version tag)
- The AI hallucination log reveals a systemic issue requiring a new rule in Section 8

### 20.2 Architectural Decision Record (ADR) Format

When a significant architectural decision is made or changed, append it to `docs/ARCHITECTURE.md` in this format:

```markdown
## ADR-XXX: [Short Title]
**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Superseded by ADR-YYY

### Context
Why was this decision needed?

### Decision
What was decided?

### Consequences
What are the positive and negative consequences?
```

### 20.3 Phase Completion Log

| Phase | Status | Completed Date | Release Tag |
|---|---|---|---|
| Phase 0 — Foundation | ⬜ Pending | — | — |
| Phase 1 — MVP | ⬜ Pending | — | — |
| Phase 2 — Core Features | ⬜ Pending | — | — |
| Phase 3 — Advanced Ops | ⬜ Pending | — | — |
| Phase 4 — Analytics | ⬜ Pending | — | — |
| Phase 5 — Production | ⬜ Pending | — | — |

Update status to `🟡 In Progress`, `✅ Complete`, or `🔴 Blocked` as the project advances.

---

*Blueprint version: 1.0.0 | Created for WarehouseOS | macOS 14+ | Swift 5.10 / SwiftUI / SwiftData*
