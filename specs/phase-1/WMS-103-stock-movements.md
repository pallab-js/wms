---
spec-id: WMS-103
title: Stock Movement Recording
phase: 1
status: approved
---

## Summary
Implement stock-in and stock-out recording with atomic quantity updates and append-only movement records.

## Detailed Requirements

### Functional Requirements
- FR-01: The system SHALL allow recording stock-in movements (quantity increases).
- FR-02: The system SHALL allow recording stock-out movements (quantity decreases).
- FR-03: The system SHALL allow recording adjustments.
- FR-04: Stock-out SHALL fail if insufficient stock.
- FR-05: Movement records SHALL be append-only (no edit/delete).
- FR-06: Each movement SHALL include optional note and reference number.

### Non-Functional Requirements
- NFR-01: Movement recording SHALL complete within 100ms.
- NFR-02: Quantity update and movement record SHALL be atomic.
- NFR-03: All movements SHALL produce audit log entries.

## Acceptance Criteria
- [ ] Can record stock-in and quantity increases
- [ ] Can record stock-out and quantity decreases
- [ ] Stock-out fails with insufficient stock error
- [ ] Movement records are immutable
- [ ] Recent movements displayed on dashboard
- [ ] Audit entries created for all movements

## Out of Scope
- Transfer orders (Phase 2)
- Batch movements
- Movement reversal
