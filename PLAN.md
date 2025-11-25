# Development Plan
## Announcement Scheduler Package

**Version**: 0.1.0  
**Last Updated**: November 25, 2025  
**Status**: Active Development

---

## Current Architecture Issue

### Problem Statement

The current implementation of `scheduleRecurringAnnouncement()` uses shared settings from `SchedulingSettingsService` (e.g., `setIsRecurring(true)`, `setRecurrencePattern()`, `setRecurrenceDays()`). This means:

- **Each new announcement overwrites the previous announcement's settings**
- **Cannot retrieve individual announcement configurations accurately**
- **Cannot differentiate between multiple recurring announcements**
- **Loss of per-announcement metadata (recurrence pattern, custom days, etc.)**

### Root Cause

The service treats recurring settings as **singleton configuration** rather than **per-announcement data**. Methods like:
- `_settingsService.setIsRecurring(true)` - overwrites for all announcements
- `_settingsService.setRecurrencePattern(recurrence)` - overwrites pattern
- `_settingsService.setRecurrenceDays(customDays)` - overwrites custom days

### Current Source of Truth Strategy

✅ **Keep**: `_notifications.pendingNotificationRequests()` as source of truth for **which** notifications are scheduled  
❌ **Replace**: `_settingsService.getScheduledTimes()` - replace with full `ScheduledAnnouncement` persistence  
✅ **Keep**: Platform notifications as authority for notification lifecycle

---

## Solution Architecture

### New Persistence Model

Replace the current `Map<String, int>` scheduled times storage with a full `List<ScheduledAnnouncement>` persistence layer:

**Before** (Current):
```dart
// Only stores notification ID → scheduled time (milliseconds)
Map<String, int> scheduledTimes = {
  '123': 1732550400000,
  '456': 1732636800000,
}
```

**After** (Proposed):
```dart
// Stores complete announcement data
List<ScheduledAnnouncement> scheduledAnnouncements = [
  ScheduledAnnouncement(
    id: '123',
    content: 'Morning reminder',
    scheduledTime: DateTime(...),
    recurrence: RecurrencePattern.weekdays,
    customDays: null,
    isActive: true,
  ),
  ScheduledAnnouncement(
    id: '456',
    content: 'Workout time',
    scheduledTime: DateTime(...),
    recurrence: RecurrencePattern.custom,
    customDays: [1, 3, 5],
    isActive: true,
  ),
]
```

### Unified ID Strategy

**Single ID for announcement and all its notifications**:

1. **Announcement ID Generation**:
   - Use `DateTime.now().millisecondsSinceEpoch` as base (integer)
   - Convert to string for `ScheduledAnnouncement.id`
   - Timestamp ensures uniqueness across all announcements

2. **Notification ID Derivation** (Android requires int):
   - **One-time**: `int.parse(announcementId)` - use announcement ID directly
   - **Recurring**: `int.parse(announcementId) + dayOffset` - add offset for each instance
     - Example: Base 1732550400, instances: 1732550400, 1732550401, 1732550402...

3. **Benefits**:
   - ✅ Perfect alignment between storage and platform notifications
   - ✅ Easy reconciliation: filter by ID or ID range
   - ✅ No ID collision risk (timestamp-based)
   - ✅ Deterministic: same announcement always generates same notification IDs

### Reconciliation Strategy

**Platform notifications remain the source of truth** for notification lifecycle:

1. When `getScheduledAnnouncements()` is called:
   - Retrieve `pendingNotificationRequests()` from platform (IDs only)
   - Load persisted `List<ScheduledAnnouncement>` from storage
   - **Reconcile**: Return only announcements whose IDs exist in pending notifications
   - **Cleanup**: Remove stale announcements from storage if not in pending notifications

2. This ensures:
   - ✅ Platform controls which notifications are actually scheduled
   - ✅ Storage provides rich metadata (recurrence, custom days, etc.)
   - ✅ Automatic cleanup of completed/cancelled announcements
   - ✅ Accurate per-announcement configuration retrieval

---

## Implementation Plan

### Phase 1: Add Serialization to ScheduledAnnouncement ✅ FOUNDATION

**Goal**: Enable `ScheduledAnnouncement` to be persisted and retrieved from storage.

- [x] **Task 1.1**: Add `toJson()` method to `ScheduledAnnouncement`
  - Convert all fields to JSON-serializable format
  - Handle `DateTime` serialization (milliseconds since epoch)
  - Handle `RecurrencePattern` enum serialization (index or name)
  - Handle nullable fields (`recurrence`, `customDays`, `metadata`)
  
- [x] **Task 1.2**: Add `fromJson()` factory constructor to `ScheduledAnnouncement`
  - Parse JSON map back to `ScheduledAnnouncement` object
  - Deserialize `DateTime` from milliseconds
  - Deserialize `RecurrencePattern` from index/name
  - Provide safe defaults for missing fields
  
- [x] **Task 1.3**: Write unit tests for serialization
  - Test `toJson()` with all field combinations
  - Test `fromJson()` with valid data
  - Test `fromJson()` with missing optional fields
  - Test round-trip serialization (object → JSON → object)
  - Test edge cases (null metadata, empty custom days, etc.)

**Acceptance Criteria**:
- ✅ `ScheduledAnnouncement` can be serialized to JSON
- ✅ `ScheduledAnnouncement` can be deserialized from JSON
- ✅ All tests pass with `reason` property
- ✅ Round-trip serialization preserves data integrity

---

### Phase 2: Add Storage Methods and Remove Old Methods 📦 PERSISTENCE

**Goal**: Add new storage methods for `List<ScheduledAnnouncement>` and remove old singleton methods.

**Note**: Since the package is unpublished, we can safely remove old methods without deprecation.

- [x] **Task 2.1**: Add `getScheduledAnnouncements()` method
  - Retrieve stored list from `_storage.get<List<dynamic>>('scheduledAnnouncements')`
  - Deserialize each JSON object to `ScheduledAnnouncement`
  - Return empty list if no data exists
  - Handle deserialization errors gracefully
  
- [x] **Task 2.2**: Add `setScheduledAnnouncements()` method
  - Accept `List<ScheduledAnnouncement>` parameter
  - Serialize each announcement to JSON
  - Store as `List<Map<String, dynamic>>` in storage
  
- [ ] **Task 2.3**: Add `addScheduledAnnouncement()` helper method
  - Retrieve current list
  - Append new announcement
  - Store updated list
  - Optimize to avoid loading/saving entire list if needed
  
- [ ] **Task 2.4**: Add `removeScheduledAnnouncement()` helper method
  - Accept announcement ID
  - Retrieve current list
  - Filter out announcement with matching ID
  - Store updated list
  
- [ ] **Task 2.5**: Add `removeScheduledAnnouncements()` bulk removal method
  - Accept `List<String>` of IDs to remove
  - Retrieve current list
  - Filter out all announcements with matching IDs
  - Store updated list
  - Use for cleanup/reconciliation
  
- [ ] **Task 2.6**: Remove old scheduled times methods
  - Remove `getScheduledTime(int notificationId)`
  - Remove `setScheduledTime(int notificationId, DateTime scheduledTime)`
  - Remove `getScheduledTimes()`
  - Remove `setScheduledTimes(Map<int, DateTime> scheduledTimes)`
  - Remove `clearScheduledTimes()`
  
- [ ] **Task 2.7**: Remove singleton recurring settings methods
  - Remove `getIsRecurring()` and `setIsRecurring(bool)`
  - Remove `getIsRecurringPaused()` and `setIsRecurringPaused(bool)`
  - Remove `getIsRecurringActive()`
  - Remove `getRecurrencePattern()` and `setRecurrencePattern(RecurrencePattern)`
  - Remove `getRecurrenceDays()` and `setRecurrenceDays(List<int>)`
  - Remove `setRecurringConfig()`
  - **Keep** `getAnnouncementHour()`, `setAnnouncementHour()`, `getAnnouncementMinute()`, `setAnnouncementMinute()`, `setAnnouncementTime()`
  
- [ ] **Task 2.8**: Update `clearSettings()` method
  - Remove old storage key clearing (methods removed)
  - Clear new `scheduledAnnouncements` storage key only
  
- [ ] **Task 2.9**: Write unit tests for storage methods
  - Test `getScheduledAnnouncements()` with empty storage
  - Test `getScheduledAnnouncements()` with existing data
  - Test `setScheduledAnnouncements()` persistence
  - Test `addScheduledAnnouncement()` appending
  - Test `removeScheduledAnnouncement()` deletion
  - Test `removeScheduledAnnouncements()` bulk deletion
  - Test `clearSettings()` clears announcement storage
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ Can persist `List<ScheduledAnnouncement>` to storage
- ✅ Can retrieve `List<ScheduledAnnouncement>` from storage
- ✅ Can add/remove individual announcements
- ✅ Can bulk remove announcements by ID list
- ✅ Old singleton methods completely removed
- ✅ All tests pass

---

### Phase 3: Update scheduleRecurringAnnouncement() 🎯 CORE CHANGE

**Goal**: Change scheduling methods to persist full `ScheduledAnnouncement` objects.

- [ ] **Task 3.1**: Update `scheduleRecurringAnnouncement()` signature
  - Add optional `String? id` parameter (generate if null)
  - Add optional `Map<String, dynamic>? metadata` parameter
  - Keep existing parameters (content, announcementTime, recurrence, customDays)
  
- [ ] **Task 3.2**: Generate unique announcement ID if not provided
  - Use `DateTime.now().millisecondsSinceEpoch.toString()` as default
  - This ID serves as the base for ALL notification IDs (one-time and recurring)
  - Ensure uniqueness (timestamp guarantees no collisions)
  - Document unified ID strategy: announcement ID = notification ID base
  
- [ ] **Task 3.3**: Create `ScheduledAnnouncement` object in method
  - Build announcement with all provided parameters
  - Calculate first `scheduledTime` from `announcementTime`
  - Set `recurrence` and `customDays` from parameters
  - Set `isActive: true` by default
  - Include `metadata` if provided
  
- [ ] **Task 3.4**: Remove singleton setting calls (already removed in Phase 2)
  - Verify no calls to removed methods
  - ✅ Keep `_settingsService.setAnnouncementTime()` for default time
  
- [ ] **Task 3.5**: Persist announcement using new storage
  - Call `_settingsService.addScheduledAnnouncement(announcement)`
  - Store before or after scheduling platform notifications
  - Handle errors during storage
  
- [ ] **Task 3.6**: Update internal scheduling methods
  - Pass announcement ID to `_scheduleRecurringNotifications()`
  - Derive notification IDs from announcement ID:
    - For recurring: `int.parse(announcementId) + dayOffset` (e.g., base + 0, base + 1, base + 2...)
    - Ensures all notifications for same announcement share common base ID
  - Update `scheduleRecurringNotificationsImpl()` to accept announcement ID parameter
  
- [ ] **Task 3.7**: Write unit tests for updated method
  - Test announcement creation with all parameters
  - Test ID generation when not provided
  - Test persistence to storage
  - Test validation still works
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ `scheduleRecurringAnnouncement()` persists full `ScheduledAnnouncement`
- ✅ Old singleton settings methods not called
- ✅ Unique ID generation works
- ✅ All tests pass

---

### Phase 4: Update scheduleOneTimeAnnouncement() 📅 CONSISTENCY

**Goal**: Apply same pattern to one-time announcements.

- [ ] **Task 4.1**: Update `scheduleOneTimeAnnouncement()` signature
  - Add optional `String? id` parameter (generate if null)
  - Add optional `Map<String, dynamic>? metadata` parameter
  - Keep existing parameters (content, dateTime)
  
- [ ] **Task 4.2**: Create `ScheduledAnnouncement` object and derive notification ID
  - Build announcement with provided parameters
  - Set `recurrence: null` (one-time)
  - Set `customDays: null`
  - Set `scheduledTime: dateTime`
  - Set `isActive: true`
  - Include `metadata` if provided
  - Use announcement ID directly as notification ID: `int.parse(announcementId)`
  
- [ ] **Task 4.3**: Persist announcement using new storage
  - Call `_settingsService.addScheduledAnnouncement(announcement)`
  - Store before scheduling platform notification
  - Handle errors
  
- [ ] **Task 4.4**: Verify old storage not used (already removed in Phase 2)
  - Verify no calls to removed `setScheduledTime()` method
  - Use new announcement persistence
  
- [ ] **Task 4.5**: Write unit tests
  - Test one-time announcement creation
  - Test ID generation
  - Test persistence
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ `scheduleOneTimeAnnouncement()` persists full `ScheduledAnnouncement`
- ✅ One-time and recurring announcements use same persistence model
- ✅ All tests pass

---

### Phase 5: Update getScheduledAnnouncements() 🔄 RECONCILIATION

**Goal**: Implement reconciliation strategy between platform and storage.

- [ ] **Task 5.1**: Refactor `getScheduledAnnouncements()` method
  - Retrieve `pendingNotificationRequests()` from platform (source of truth)
  - Retrieve stored `List<ScheduledAnnouncement>` from storage
  - Create Set of pending notification IDs for fast lookup
  
- [ ] **Task 5.2**: Implement reconciliation logic
  - Filter stored announcements: keep only those whose ID is in pending notifications
  - This automatically excludes completed/cancelled announcements
  
- [ ] **Task 5.3**: Implement automatic cleanup
  - Identify announcement IDs in storage but NOT in pending notifications
  - Call `_settingsService.removeScheduledAnnouncements(staleIds)`
  - Log cleanup actions if debug logging enabled
  
- [ ] **Task 5.4**: Handle edge cases
  - Platform notification exists but no stored announcement: skip or log warning
  - Stored announcement exists but no platform notification: cleanup (already handled)
  - Empty pending notifications: return empty list and cleanup all storage
  
- [ ] **Task 5.5**: Update return value
  - Return filtered `List<ScheduledAnnouncement>` with rich metadata
  - Sorted by `scheduledTime` (earliest first)
  
- [ ] **Task 5.6**: Update implementation
  - Use stored announcements from new storage
  - Remove manual `ScheduledAnnouncement` construction from notification data
  
- [ ] **Task 5.7**: Write unit tests
  - Test reconciliation with matching IDs
  - Test cleanup of stale announcements
  - Test edge case: platform notification without stored announcement
  - Test edge case: stored announcement without platform notification (cleanup)
  - Test empty pending notifications (cleanup all)
  - Test sorting by scheduled time
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ Platform notifications remain source of truth for lifecycle
- ✅ Storage provides rich metadata
- ✅ Automatic cleanup of stale data
- ✅ Edge cases handled gracefully
- ✅ All tests pass

---

### Phase 6: Update Cleanup Logic 🧹 MAINTENANCE

**Goal**: Ensure `_cleanupCompletedAnnouncements()` uses new storage.

- [ ] **Task 6.1**: Review current `_cleanupCompletedAnnouncements()` implementation
  - Identify calls to deprecated storage methods
  - Understand current cleanup strategy
  
- [ ] **Task 6.2**: Refactor cleanup method
  - Use `getScheduledAnnouncements()` (which already reconciles)
  - Cleanup is now automatic during retrieval
  - Consider if explicit cleanup method is still needed
  
- [ ] **Task 6.3**: Update cleanup trigger
  - Review `_setupCleanupListener()` and status stream
  - Ensure cleanup happens after `AnnouncementStatus.completed`
  - Test cleanup occurs at right time
  
- [ ] **Task 6.4**: Write unit tests
  - Test cleanup on completed status
  - Test cleanup removes correct announcements
  - Test cleanup doesn't remove active announcements
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ Cleanup uses new storage methods
- ✅ Completed announcements removed from storage
- ✅ Active announcements preserved
- ✅ All tests pass

---

### Phase 7: Update cancelAnnouncementById() ❌ CANCELLATION

**Goal**: Update cancellation to remove from new storage.

- [ ] **Task 7.1**: Review current `cancelAnnouncementById()` implementation
  - Identify storage cleanup calls
  
- [ ] **Task 7.2**: Add storage removal
  - Parse ID to int if needed
  - Call `_notifications.cancel(id)` (already exists)
  - Call `_settingsService.removeScheduledAnnouncement(id)`
  
- [ ] **Task 7.3**: Write unit tests
  - Test cancellation removes from platform
  - Test cancellation removes from storage
  - Test cancelling non-existent ID (graceful handling)
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ Cancellation removes from both platform and storage
- ✅ Non-existent IDs handled gracefully
- ✅ All tests pass

---

### Phase 8: Update cancelAllNotifications() 🗑️ BULK CANCELLATION

**Goal**: Update bulk cancellation to clear new storage.

- [ ] **Task 8.1**: Review current `cancelAllNotifications()` implementation
  - Identify old storage clearing calls
  
- [ ] **Task 8.2**: Update storage clearing
  - Keep `_notifications.cancelAll()` (already exists)
  - ✅ Use `_settingsService.setScheduledAnnouncements([])` (clear list)
  
- [ ] **Task 8.3**: Clear timer tracking
  - Ensure active timers still cancelled (already exists)
  
- [ ] **Task 8.4**: Write unit tests
  - Test all platform notifications cancelled
  - Test all stored announcements cleared
  - Test timers cancelled
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ All notifications cancelled on platform
- ✅ All announcements cleared from storage
- ✅ Timers cleaned up
- ✅ All tests pass

---

### Phase 9: Update Internal Scheduling Methods 🔧 INTERNALS

**Goal**: Update internal methods to work with announcement objects.

- [ ] **Task 9.1**: Update `_scheduleRecurringNotifications()` signature
  - Add `required String announcementId` parameter
  - Pass to child methods
  
- [ ] **Task 9.2**: Update `scheduleRecurringNotificationsImpl()` signature
  - Add `required String announcementId` parameter
  - Use announcement ID for notification IDs
  - Update all call sites
  
- [ ] **Task 9.3**: Update notification ID generation
  - Current: `notificationId = i` (sequential - problematic!)
  - New: Derive from `announcementId` + offset: `int.parse(announcementId) + i`
  - One-time announcements: `int.parse(announcementId)` (no offset)
  - Recurring announcements: `int.parse(announcementId) + dayOffset` (0, 1, 2...)
  - Ensures uniqueness across announcements (timestamp-based base)
  - Ensures consistency for same announcement (deterministic)
  
- [ ] **Task 9.4**: Verify storage not used in internals
  - Verify no calls to removed storage methods
  - Announcements already persisted in Phase 3/4
  
- [ ] **Task 9.5**: Update `_scheduleDailyNotification()`
  - Remove `setScheduledTime()` call
  - Ensure announcement already persisted in calling method
  
- [ ] **Task 9.6**: Update unit tests
  - Update `scheduleRecurringNotificationsImpl()` tests
  - Test notification ID generation from announcement ID
  - Test uniqueness and consistency
  - All tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ Internal methods use announcement ID
- ✅ Notification IDs derived from announcement ID
- ✅ Old storage methods not called
- ✅ All tests pass

---

### Phase 10: Update API Documentation 📚 DOCUMENTATION

**Goal**: Update `API_REFERENCE.md` to reflect new architecture.

- [ ] **Task 10.1**: Update `scheduleRecurringAnnouncement()` documentation
  - Document new `id` parameter
  - Document new `metadata` parameter
  - Add examples with and without explicit ID
  - Explain ID generation
  
- [ ] **Task 10.2**: Update `scheduleOneTimeAnnouncement()` documentation
  - Document new `id` parameter
  - Document new `metadata` parameter
  - Add examples
  
- [ ] **Task 10.3**: Update `getScheduledAnnouncements()` documentation
  - Explain reconciliation strategy
  - Document automatic cleanup behavior
  - Note that returned list is accurate per-announcement config
  
- [ ] **Task 10.4**: Add architecture explanation section
  - Explain old vs. new architecture
  - Provide code examples
  - Document removed singleton methods
  
- [ ] **Task 10.5**: Update `SchedulingSettingsService` documentation
  - Document new storage methods
  - Explain per-announcement model
  - Note removed singleton methods

**Acceptance Criteria**:
- ✅ All method signatures documented accurately
- ✅ Architecture explanation provided
- ✅ Examples updated
- ✅ Removed methods documented

---

### Phase 11: Update PRD.md 📋 REQUIREMENTS

**Goal**: Update Product Requirements Document to reflect architectural changes.

- [ ] **Task 11.1**: Update Technical Requirements section
  - Document new persistence model
  - Explain reconciliation strategy
  - Update platform limitation notes
  
- [ ] **Task 11.2**: Update User Workflows section
  - Update "View Scheduled Announcements" workflow
  - Remove note about known issue (creation time vs. scheduled time)
  - Update to reflect accurate metadata retrieval
  
- [ ] **Task 11.3**: Update Configuration Reference
  - Note that recurring settings are now per-announcement
  - Remove singleton recurring configuration guidance
  
- [ ] **Task 11.4**: Update Appendix
  - Add glossary terms (reconciliation, persistence layer, etc.)
  - Update related documents list

**Acceptance Criteria**:
- ✅ PRD reflects new architecture accurately
- ✅ Known issues section updated
- ✅ Technical details current

---

### Phase 12: Integration Testing 🧪 VALIDATION

**Goal**: Comprehensive testing of new architecture end-to-end.

- [ ] **Task 12.1**: Write integration test: Multiple recurring announcements
  - Schedule 3 different recurring announcements with different patterns
  - Verify each has unique ID
  - Verify each persisted correctly
  - Retrieve announcements and verify all metadata correct
  
- [ ] **Task 12.2**: Write integration test: Mix of one-time and recurring
  - Schedule 2 one-time and 2 recurring announcements
  - Verify correct persistence
  - Verify `getScheduledAnnouncements()` returns all 4
  - Verify metadata accurate for each type
  
- [ ] **Task 12.3**: Write integration test: Cancellation
  - Schedule multiple announcements
  - Cancel one by ID
  - Verify removed from platform and storage
  - Verify others unaffected
  
- [ ] **Task 12.4**: Write integration test: Cleanup
  - Schedule announcement
  - Manually trigger completion status
  - Verify cleanup removes from storage
  
- [ ] **Task 12.5**: Write integration test: Reconciliation
  - Schedule announcements
  - Manually remove one from platform (simulate completion)
  - Call `getScheduledAnnouncements()`
  - Verify removed from storage (automatic cleanup)
  
- [ ] **Task 12.6**: Write integration test: Validation limits
  - Schedule announcements up to `maxNotificationsPerDay`
  - Verify next one throws `ValidationException`
  - Verify validation uses per-announcement data
  
- [ ] **Task 12.7**: All integration tests use `expect` with `reason` property

**Acceptance Criteria**:
- ✅ All integration tests pass
- ✅ End-to-end functionality verified
- ✅ Edge cases covered
- ✅ Test coverage remains ≥70%

---

## Testing Strategy

### Unit Test Requirements

- ✅ All tests use `expect` with `reason` property (per coding standards)
- ✅ Test coverage ≥70% maintained throughout implementation
- ✅ Each phase includes dedicated test tasks
- ✅ Tests written before or alongside implementation (TDD encouraged)

### Integration Test Requirements

- ✅ Test multiple announcements with different configurations
- ✅ Test reconciliation and cleanup behavior
- ✅ Test validation limits with new persistence model
- ✅ Test end-to-end workflows from PRD.md

### Test Patterns

Follow existing test patterns:
- Use dependency injection (Strategy Pattern)
- Use `@visibleForTesting` setters for fake implementations
- Mock at service boundaries, not internal methods
- Test public API thoroughly

---

## Architecture Change Summary

### Old Architecture (Singleton Settings)
```dart
// Singleton recurring settings (shared across all announcements)
await scheduler.scheduleRecurringAnnouncement(
  content: 'Morning reminder',
  announcementTime: TimeOfDay(hour: 8, minute: 0),
  recurrence: RecurrencePattern.weekdays,
);

// Problem: Cannot distinguish between multiple recurring announcements
// Each new announcement overwrites previous settings
```

### New Architecture (Per-Announcement Configuration)
```dart
// Per-announcement configuration with unique ID
await scheduler.scheduleRecurringAnnouncement(
  id: 'morning_reminder', // Optional: auto-generated if omitted
  content: 'Morning reminder',
  announcementTime: TimeOfDay(hour: 8, minute: 0),
  recurrence: RecurrencePattern.weekdays,
  metadata: {'category': 'health'}, // Optional metadata
);

// Each announcement maintains its own configuration
final announcements = await scheduler.getScheduledAnnouncements();
for (final announcement in announcements) {
  print('${announcement.id}: ${announcement.recurrence}');
}
```

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking internal tests | Medium | Update tests incrementally in each phase |
| Increased storage size | Low | `ScheduledAnnouncement` is small (~200-500 bytes each) |
| Reconciliation bugs | Medium | Comprehensive integration tests in Phase 12 |
| Test coverage drop | Medium | Test tasks in every phase, monitor coverage |
| Missing edge cases | Medium | Thorough integration testing covers real-world scenarios |

---

## Timeline Estimate

| Phase | Estimated Time | Dependencies |
|-------|---------------|--------------|
| Phase 1: Serialization | 2-3 hours | None |
| Phase 2: Storage + Remove Old | 3-4 hours | Phase 1 |
| Phase 3: Update Recurring Scheduling | 3-4 hours | Phase 1, 2 |
| Phase 4: Update One-Time Scheduling | 2 hours | Phase 1, 2 |
| Phase 5: Update Retrieval | 3-4 hours | Phase 2 |
| Phase 6: Update Cleanup | 2 hours | Phase 5 |
| Phase 7: Update Cancel By ID | 1 hour | Phase 2 |
| Phase 8: Update Cancel All | 1 hour | Phase 2 |
| Phase 9: Update Internal Methods | 2-3 hours | Phase 3, 4 |
| Phase 10: Update API Docs | 2 hours | All phases |
| Phase 11: Update PRD | 1 hour | All phases |
| Phase 12: Integration Testing | 4-5 hours | All phases |

**Total**: ~26-32 hours  
**Savings vs. deprecation approach**: ~2-6 hours

---

## Success Criteria

### Technical Success
- ✅ All unit tests pass with ≥70% coverage
- ✅ All integration tests pass
- ✅ `flutter analyze` passes with 0 errors/warnings
- ✅ Platform notifications remain source of truth
- ✅ Storage provides accurate per-announcement metadata
- ✅ Automatic reconciliation and cleanup works correctly

### Architectural Success
- ✅ No singleton recurring settings (cleanly removed)
- ✅ Each announcement has independent configuration
- ✅ `getScheduledAnnouncements()` returns accurate metadata
- ✅ Validation works with per-announcement data

### Documentation Success
- ✅ `API_REFERENCE.md` updated with new signatures
- ✅ `PRD.md` reflects new architecture
- ✅ Architecture changes clearly documented
- ✅ Removed methods noted in documentation

---

## Notes

- **Package Status**: Unpublished - direct removal of old methods is safe
- **No Deprecation Needed**: No external users to migrate
- **Platform Source of Truth**: Never changes - `pendingNotificationRequests()` always authoritative
- **Storage Role**: Provides rich metadata that platform API doesn't expose
- **Reconciliation**: Automatic cleanup ensures storage stays in sync with platform
- **Clean Architecture**: Immediate transition to per-announcement model

---

**Document Version**: 1.0  
**Last Review**: November 25, 2025  
**Next Review**: After Phase 7 completion  
**Approved By**: Development Team
