# WarehouseOS

[![CI](https://github.com/pallab-js/wms/actions/workflows/ci.yml/badge.svg)](https://github.com/pallab-js/wms/actions/workflows/ci.yml)

Native macOS warehouse management — inventory, warehouses, employees, and transfer orders. Built with Swift and SwiftUI; no server, no database.

## Features

- **Warehouses** — multiple sites with capacity tracking and utilisation metrics
- **Inventory** — SKUs, categories, units of measure, cost tracking, and threshold-based low-stock alerts with macOS notifications
- **Stock movements** — atomic stock-in, stock-out, and adjustments, each recorded in an immutable audit trail
- **Transfer orders** — Draft → Submitted → Approved → In Transit → Completed, with stock validation and cancellation
- **Employees** — profiles, activation state, and role-based permissions
- **Dashboard, filterable audit log, and global search (⌘F)**
- **Accessible** — VoiceOver labels on every control

## Requirements

- macOS 14.0 or later
- Swift 5.10 (Xcode 15.4+) or later
- [SwiftLint](https://github.com/realm/SwiftLint) for the lint step

## Getting started

```bash
git clone https://github.com/pallab-js/wms.git
cd wms

swift build
swift run WarehouseOS   # launch the app
swift run WMSSeed       # optional: load demo data
```

`WMSSeed` writes a demo dataset (3 warehouses, 15 SKUs, 6 employees, one transfer per workflow state) through the normal services, so validation, audit entries, alerts, and encryption behave exactly as they do in the app. It skips an already-populated store; use `--reset` to wipe and reseed, or `--dir <path>` to seed a scratch directory.

## Commands

| Task | Command |
|---|---|
| Build | `swift build` |
| Run the app | `swift run WarehouseOS` |
| Seed demo data | `swift run WMSSeed` |
| Run all tests (116) | `./Scripts/run-tests.sh` |
| Run integration tests only | `swift test` |
| Lint | `swiftlint --strict` |

## Architecture

Strict MVVM with a service and repository layer: **views → view models → services (business rules, validation, audit) → repositories → JSON on disk**. Each layer talks only to protocols declared in `WMSCore`.

| Package | Purpose |
|---|---|
| `WMSCore` | Domain models, repository and permission protocols, validation |
| `WMSData` | Atomic file-based JSON persistence, Keychain encryption |
| `WMSServices` | Business rules, stock and transfer workflows, audit logging |
| `WMSFeatures` | ViewModels and SwiftUI screens |
| `WMSDesignSystem` | Components, typography, and colour tokens |

`docs/` holds architecture and contributing notes; `specs/` holds feature specifications.

## Data

All records live in `~/Library/Application Support/WarehouseOS/*.json`, written atomically with `0600` permissions and encrypted with a key stored in the macOS Keychain.

## Continuous integration

GitHub Actions runs on every push and pull request: SwiftLint, build, and all test suites. Pushes to `main` also publish a packaged `.app` artifact, and tags matching `v*.*.*` cut a GitHub Release containing the app zip.

## License

MIT — see [LICENSE](LICENSE).
