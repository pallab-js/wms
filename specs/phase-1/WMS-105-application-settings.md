---
spec-id: WMS-105
title: Application Settings
phase: 1
status: approved
---

## Summary
Implement application-level settings for organisation configuration and user preferences.

## Detailed Requirements

### Functional Requirements
- FR-01: The system SHALL allow setting the organisation name.
- FR-02: The system SHALL allow setting default unit of measure.
- FR-03: The system SHALL persist settings across app launches.
- FR-04: The system SHALL display current user role.

### Non-Functional Requirements
- NFR-01: Settings SHALL persist using UserDefaults.
- NFR-02: Settings changes SHALL take effect immediately.

## Acceptance Criteria
- [ ] Organisation name can be set and persists
- [ ] Default unit of measure can be configured
- [ ] Settings survive app restart
- [ ] Current role displayed correctly

## Out of Scope
- Role-based access control (Phase 3)
- User authentication
- iCloud sync of settings
