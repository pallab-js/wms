---
spec-id: WMS-102
title: Inventory Item Catalogue
phase: 1
status: approved
---

## Summary
Implement the inventory item catalogue with full CRUD operations and SKU management per warehouse.

## Detailed Requirements

### Functional Requirements
- FR-01: The system SHALL allow creating inventory items with SKU, name, description, category, unit of measure, quantity, threshold, and cost.
- FR-02: The system SHALL display inventory items in a table view.
- FR-03: The system SHALL allow filtering items by warehouse.
- FR-04: The system SHALL enforce unique SKUs within a warehouse.
- FR-05: The system SHALL highlight items below their minimum threshold.

### Non-Functional Requirements
- NFR-01: Item list SHALL load in under 200ms for up to 10,000 items.
- NFR-02: All operations SHALL produce audit log entries.

## Acceptance Criteria
- [ ] Can create an inventory item with valid data
- [ ] Cannot create duplicate SKU in same warehouse
- [ ] Item list displays with correct columns
- [ ] Can filter items by warehouse
- [ ] Low-stock items highlighted
- [ ] Audit entries created for all mutations

## Out of Scope
- Barcode scanning (Phase 3)
- CSV import (Phase 2)
- Bulk operations
