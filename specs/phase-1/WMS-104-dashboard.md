---
spec-id: WMS-104
title: Dashboard View
phase: 1
status: approved
---

## Summary
Implement a read-only dashboard displaying aggregated warehouse data, KPIs, and recent activity.

## Detailed Requirements

### Functional Requirements
- FR-01: The system SHALL display total active warehouse count.
- FR-02: The system SHALL display total SKU count.
- FR-03: The system SHALL display total inventory value.
- FR-04: The system SHALL show warehouse utilisation percentages.
- FR-05: The system SHALL show the 10 most recent stock movements.

### Non-Functional Requirements
- NFR-01: Dashboard SHALL load in under 500ms.
- NFR-02: Dashboard SHALL be read-only (no mutation logic).

## Acceptance Criteria
- [ ] KPI cards display correct values
- [ ] Warehouse utilisation shows correct percentages
- [ ] Recent movements list displays correctly
- [ ] Dashboard updates when data changes

## Out of Scope
- Charts and graphs (Phase 4)
- PDF export (Phase 4)
- Date range filtering (Phase 4)
