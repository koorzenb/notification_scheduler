# Implementation Plan - AnnouncementService Refactor

## 1. Refactor AnnouncementService
Refactor the `AnnouncementService` in `example/lib/services/announcement_service.dart` to use the Async Factory pattern.

- [ ] **Create Private Constructor**: Hide the default constructor to enforce usage of the factory method.
- [ ] **Add Static `create` Method**: Implement `static Future<AnnouncementService> create({required AnnouncementConfig config})` replacing the current `initialize()` method/pattern.
- [ ] **Inject Configuration**: ensure `create` accepts an `AnnouncementConfig` object to pass down to the `AnnouncementScheduler`.
- [ ] **Handle Permissions**: Ensure permission requests are handled within the `create` flow or documented as a prerequisite.
- [ ] **Update Usage**: Update any calls in the example app (e.g., `main.dart`) to use `AnnouncementService.create(...)`.

## 2. Update Documentation
Update the package `README.md` to recommend the Service pattern.

- [ ] **Update Quick Start**: Change the example code to show how to structure an `AnnouncementService` wrapper as the primary entry point for the application.
- [ ] **Explain Benefits**: Briefly mention why wrapping the `AnnouncementScheduler` in a service (for DI, state management, etc.) is the recommended approach.
