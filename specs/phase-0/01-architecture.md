---
spec-id: WMS-002
title: Architecture Decisions
phase: 0
status: approved
---

## Summary
Define the architectural patterns, module boundaries, and technology choices for WarehouseOS.

## Context & Background
The application must support long-term maintainability, testability, and a clean separation of concerns. Local SPM packages enforce module boundaries and prevent circular dependencies.

## Detailed Requirements

### Architecture Pattern
- MVVM + Repository + Service Layer
- Views contain no business logic
- ViewModels manage state and input validation
- Services enforce business rules
- Repositories abstract persistence

### Module Boundaries
- WMSCore: Domain models, protocols, errors (zero dependencies)
- WMSData: SwiftData models, repository implementations
- WMSServices: Service layer implementations
- WMSFeatures: Feature-specific ViewModels and Views
- WMSDesignSystem: Reusable UI components and tokens
- WMSApp: App entry point, DI container, navigation

### Navigation
- NavigationSplitView (three-column on large screens)
- Central AppRouter for programmatic navigation

### Dependency Injection
- Hand-rolled DI container at app root
- Services injected via SwiftUI Environment
- No third-party DI frameworks

## Acceptance Criteria
- [ ] All six SPM packages created and linked
- [ ] No circular dependencies between packages
- [ ] App compiles with all packages linked

## Out of Scope
- Third-party dependency management
- Microservices architecture
