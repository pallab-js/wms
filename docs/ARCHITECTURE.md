# WarehouseOS Architecture

## Overview

WarehouseOS follows an **MVVM + Repository + Service Layer** architecture with strict module separation via local Swift packages.

## Module Structure

```
WMSCore (zero dependencies)
    ├── Models/        — Domain structs
    ├── Protocols/     — Repository + service protocols
    └── Errors/        — WMSError enum

WMSData (depends on WMSCore)
    ├── SwiftDataModels/ — @Model classes
    ├── Repositories/    — Repository implementations
    └── Migrations/      — Schema versioning

WMSServices (depends on WMSCore)
    ├── WarehouseService
    ├── InventoryService
    ├── EmployeeService
    ├── TransferService
    ├── DashboardService
    └── AuditLogger

WMSFeatures (depends on WMSCore, WMSServices, WMSDesignSystem)
    ├── Warehouses/   — Warehouse CRUD views
    ├── Inventory/     — Inventory management views
    ├── Employees/     — Employee management views
    ├── Transfers/     — Transfer order views
    ├── Reports/       — Dashboard and analytics
    └── Settings/      — Application settings

WMSDesignSystem (zero dependencies)
    ├── Components/    — Reusable UI components
    ├── Typography.swift
    └── ColorTheme.swift
```

## Data Flow

```
SwiftUI View → ViewModel → Service → Repository → SwiftData
```

## Dependency Injection

A hand-rolled `DependencyContainer` at the app root creates all repositories and services. ViewModels receive services via init injection. Views access the container through SwiftUI `Environment`.

## ADR-001: MVVM + Repository Pattern

**Date:** 2025-01-01
**Status:** Accepted

### Context
Need an architecture that supports testability, SwiftUI data binding, and long-term maintainability.

### Decision
Use MVVM with Repository pattern and Service layer. ViewModels are `@Observable` classes. Repositories are protocol-based. Services enforce business rules.

### Consequences
+ Clean separation of concerns
+ Easy to unit test with mock repositories
+ SwiftUI data binding works naturally
- More boilerplate than simpler patterns
- Requires discipline to maintain boundaries
