---
spec-id: WMS-003
title: Data Model Design
phase: 0
status: approved
---

## Summary
Define the data models, relationships, and persistence strategy for WarehouseOS.

## Context & Background
The data layer must support the full feature set across all phases while maintaining query performance and CloudKit compatibility.

## Detailed Requirements

### Core Entities
- Warehouse: id, name, code, address, capacity, isActive, timestamps
- InventoryItem: id, sku, name, description, category, unitOfMeasure, currentQuantity, minimumThreshold, unitCost, warehouseID, isActive, timestamps
- StockMovement: id, movementType, quantity, note, referenceNumber, recordedAt, recordedByUserID, itemID, warehouseID
- Employee: id, firstName, lastName, employeeCode, jobTitle, email, phone, warehouseIDs, isActive, hireDate, notes
- TransferOrder: id, transferCode, status, sourceWarehouseID, destinationWarehouseID, requestedDate, completedDate, notes, lineItems
- AuditEntry: id, timestamp, entityType, entityID, action, changedFields, userRole, note
- AlertRecord: id, message, severity, entityType, entityID, isAcknowledged, createdAt

### Relationships
- Warehouse 1:many InventoryItem
- Warehouse many:many Employee (via join)
- InventoryItem 1:many StockMovement
- TransferOrder 1:many TransferLineItem
- All mutations produce AuditEntry records

### Persistence Strategy
- SwiftData for local persistence
- CloudKit optional for sync (Phase 5)
- VersionedSchema for migrations
- @Attribute(.index) on frequently queried fields

## Acceptance Criteria
- [ ] All SwiftData models created with correct relationships
- [ ] Domain models created as pure structs
- [ ] Repository protocols defined
- [ ] Repository implementations working with in-memory store

## Out of Scope
- CloudKit sync configuration (Phase 5)
- Encryption at rest
