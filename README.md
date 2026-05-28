# WarehouseOS

Enterprise-grade warehouse management for macOS. A standalone desktop application for managing multiple warehouses, inventory, employees, and transfer orders — built natively with Swift and SwiftUI.

## Features

- **Multi-warehouse management** — Create, configure, and monitor warehouses with capacity tracking
- **Inventory catalogue** — SKU management with categories, units of measure, and cost tracking
- **Stock movements** — Atomic stock-in, stock-out, and adjustment recording with full audit trail
- **Transfer orders** — Multi-step workflow (Draft → Submitted → Approved → In Transit → Completed) with stock validation
- **Employee management** — Profiles with warehouse assignments and role-based access
- **Dashboard** — Real-time KPIs, warehouse utilisation charts, and recent activity
- **Audit log** — Immutable record of all mutations, filterable by entity type and action
- **Global search** — Search across warehouses, inventory items, and employees (Cmd+F)
- **Low-stock alerts** — Threshold monitoring with macOS notifications
- **Input validation** — Client-side and server-side validation with clear error messages
- **Accessibility** — Full VoiceOver support with accessibility labels on all controls

## Requirements

- macOS 14.0 Sonoma or later (Apple Silicon optimised)
- Swift 5.10+

## Quick Start

```bash
# Clone the repository
git clone https://github.com/pallab-js/wms.git
cd wms

# Build and run
swift build
swift run WarehouseOS
```

## Architecture

WarehouseOS follows a strict **MVVM + Repository + Service Layer** architecture with local Swift packages:

```
┌─────────────────────────────────┐
│        SwiftUI Views            │
│   (Declarative UI, no logic)    │
└──────────────┬──────────────────┘
               │ @StateObject
┌──────────────▼──────────────────┐
│         ViewModels              │
│  (State, validation, UI logic)  │
└──────────────┬──────────────────┘
               │ Protocol calls
┌──────────────▼──────────────────┐
│        Service Layer            │
│  (Business rules, orchestration)│
└──────────────┬──────────────────┘
               │ Repository protocol
┌──────────────▼──────────────────┐
│       Repository Layer          │
│  (Abstracts persistence)        │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│     File-based JSON Storage     │
└─────────────────────────────────┘
```

| Package | Purpose |
|---|---|
| `WMSCore` | Domain models, protocols, business rules, validators |
| `WMSData` | File-based persistence with atomic writes |
| `WMSServices` | Service layer with business logic and audit logging |
| `WMSFeatures` | Feature-specific ViewModels and SwiftUI views |
| `WMSDesignSystem` | Reusable UI components, typography, and colour tokens |

## Development

```bash
# Build
swift build

# Run
swift run WarehouseOS

# Run integration tests
swift run TestRunner

# Lint
swiftlint --strict
```

## Project Structure

```
wms/
├── Sources/WarehouseOSApp/     # App entry point, DI, navigation
├── Packages/
│   ├── WMSCore/                # Domain models and protocols
│   ├── WMSData/                # Persistence layer
│   ├── WMSServices/            # Business logic
│   ├── WMSFeatures/            # UI features
│   └── WMSDesignSystem/        # Design tokens
├── specs/                      # Feature specifications
├── docs/                       # Architecture and contributing docs
├── Scripts/                    # Dev tooling scripts
└── .github/                    # CI workflows, templates
```

## License

MIT License. See [LICENSE](LICENSE) for details.
