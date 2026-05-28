# Contributing to WarehouseOS

## Development Setup

1. Clone the repository
2. Open `WarehouseOS/WarehouseOS.xcodeproj` in Xcode 16+
3. Add local SPM packages via File → Add Package Dependencies
4. Build and run

## Code Style

- Follow Swift API Design Guidelines
- Use `swiftlint` for style enforcement
- Use `swift-format` for formatting
- No third-party dependencies without explicit approval

## Architecture Rules

- Views contain NO business logic
- ViewModels manage state and call services
- Services enforce business rules
- Repositories abstract persistence
- Domain models are pure structs (no persistence concerns)

## Commit Convention

Use Conventional Commits:

```
<type>(<scope>): <short summary>

Types: feat | fix | refactor | test | docs | chore | perf | ci
Scope: warehouses | inventory | employees | transfers | reports | data | ui | ci
```

## Pull Request Process

1. Create feature branch from `develop`
2. Write/update specs before implementation
3. Implement with tests
4. Ensure CI passes
5. Self-review checklist
6. Merge via PR (even for solo development)

## Testing

- Unit tests for all service classes (mock repositories)
- Integration tests with in-memory SwiftData store
- Minimum 75% coverage for service layer
