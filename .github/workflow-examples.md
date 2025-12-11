<!-- markdownlint-disable MD024 -->

# Example Workflows for Common Development Scenarios

This document provides complete examples of how the main agent coordinates workflows for typical development tasks.

## Example 1: Adding User Authentication Feature

### User Request: Authentication Feature
>
> "I need to add user authentication to the app with email/password login, logout, and session management."

### Main Agent Analysis: Authentication Feature

- **Type:** Complete feature development
- **Complexity:** High (multiple components, security considerations)
- **Workflow:** Feature Development (Planning → Testing → Implementation → Review)
- **Estimated Steps:** 4 agents, medium duration

## Workflow Execution

### Step 1: Planning Agent

**Handoff:**

```md
**Context:** User needs email/password authentication with session management
**Task:** Analyze requirements and create detailed implementation plan
**Requirements:** 
- Integration with existing Flutter/GetX architecture
- Follow security best practices
- Consider PRD.md user stories for auth requirements
**Success Criteria:** Complete plan with API design, data models, and security approach
**Next Step:** Testing agent will write comprehensive test suite
```

**Planning Agent Output (simulated):**

```md
Authentication Implementation Plan:
- AuthService (business logic)
- AuthController (UI state management)
- User model with validation
- Secure token storage with settings service
- Login/logout screens with form validation
- Session persistence across app restarts

Security Requirements:
- Password hashing and validation
- Token-based session management
- Secure storage integration
- Input validation and sanitization
```

#### Step 2: Testing Agent

**Handoff:**

```md
**Context:** Authentication plan completed with API design and security requirements
**Task:** Write comprehensive TDD test suite for authentication system
**Requirements:**
- Tests for AuthService (login, logout, token validation)
- Tests for AuthController state management
- Tests for User model validation
- Mock external dependencies
**Success Criteria:** Complete failing test suite that defines authentication behavior
**Next Step:** Implementation agent will write code to pass tests
```

#### Step 3: Implementation Agent

**Handoff:**

```md
**Context:** Authentication tests written and currently failing (TDD approach)
**Task:** Implement authentication system to make all tests pass
**Requirements:**
- Follow existing project patterns (GetX, services architecture)
- Integrate with SettingsService for secure storage
- Maintain code quality standards
- Minimal code to pass tests
**Success Criteria:** All authentication tests green, no breaking changes
**Next Step:** Review agent will validate security and quality
```

#### Step 4: Review Agent

**Handoff:**

```md
**Context:** Authentication system implemented, all tests passing
**Task:** Comprehensive security and quality review
**Requirements:**
- Security vulnerability assessment
- Code quality and standards compliance
- Integration safety with existing codebase
- Performance considerations
**Success Criteria:** Authentication ready for production use
**Next Step:** Feature complete, ready for user acceptance
```

### Workflow Result

```md
✅ Feature Complete: User Authentication
- AuthService with secure login/logout
- AuthController for UI state management  
- Comprehensive test coverage
- Security reviewed and approved
- Integration tested with existing app
```

---

## Example 2: Fixing Location Service Bug

### User Request: Location Service Bug
>
> "The location service sometimes crashes when GPS is disabled. Can you fix this?"

### Main Agent Analysis: Location Service Bug

- **Type:** Bug investigation and fix
- **Complexity:** Medium (error handling, edge cases)
- **Workflow:** Bug Resolution (Review → Testing → Implementation → Review)
- **Estimated Steps:** 4 agents, short duration

## Workflow Execution

### Step 1: Review Agent (Root Cause Analysis)

**Handoff:**

```md
**Context:** Location service crashes when GPS disabled
**Task:** Analyze LocationService code to identify crash cause
**Requirements:**
- Review error handling in location access
- Check GPS availability detection
- Identify missing null checks or exception handling
**Success Criteria:** Clear root cause identification with crash reproduction steps
**Next Step:** Testing agent will write test to reproduce bug
```

**Review Agent Output (simulated):**

```md
Root Cause Analysis:
- LocationService.getCurrentPosition() doesn't handle PermissionDenied exception
- Missing null check after GPS availability check
- No fallback when GPS services unavailable
- Crash occurs in line 45: position!.latitude access

Recommended Fix:
- Add try-catch for location permission errors
- Implement GPS availability checking before access
- Add fallback behavior for disabled GPS
```

#### Step 2: Testing Agent (Bug Reproduction)

**Handoff:**

```md
**Context:** Root cause identified - missing exception handling in LocationService
**Task:** Write test that reproduces the GPS disabled crash
**Requirements:**
- Mock GPS disabled scenario
- Test should fail (demonstrate current bug)
- Cover edge cases (no permission, service unavailable)
**Success Criteria:** Reliable failing test that shows the crash
**Next Step:** Implementation agent will fix code to make test pass
```

#### Step 3: Implementation Agent (Bug Fix)

**Handoff:**

```md
**Context:** Bug reproduction test written and failing as expected
**Task:** Fix LocationService to handle GPS disabled scenario safely
**Requirements:**
- Add proper exception handling
- Implement GPS availability checking
- Maintain existing functionality for normal cases
- Make bug reproduction test pass
**Success Criteria:** Bug test passes, all existing location tests still green
**Next Step:** Review agent will verify fix completeness
```

#### Step 4: Review Agent (Fix Verification)

**Handoff:**

```md
**Context:** LocationService bug fix implemented, bug test now passing
**Task:** Verify fix is complete and doesn't introduce new issues
**Requirements:**
- Confirm robust error handling
- Check for similar issues in related code
- Validate no performance regressions
- Ensure fix follows project patterns
**Success Criteria:** Bug fix approved, no side effects identified
**Next Step:** Bug resolution complete
```

### Workflow Result

```md
✅ Bug Fixed: Location Service GPS Crash
- Added exception handling for GPS disabled scenarios
- Implemented graceful fallback behavior
- Test coverage for edge cases added
- No regressions in existing functionality
```

---

## Example 3: Code Quality Improvement

### User Request: Code Refactoring
>
> "The WeatherService class is getting too large and complex. Can you help refactor it?"

### Main Agent Analysis: Code Refactoring

- **Type:** Code quality improvement
- **Complexity:** Medium (refactoring existing functionality)
- **Workflow:** Quality Refactoring (Review → Planning → Testing → Implementation → Review)
- **Estimated Steps:** 5 agents, medium duration

## Workflow Execution

### Step 1: Review Agent (Quality Assessment)

**Handoff:**

```md
**Context:** WeatherService is too large and complex, needs refactoring
**Task:** Analyze WeatherService code quality issues
**Requirements:**
- Check file length and function complexity
- Identify separation of concerns issues
- Find code duplication opportunities
- Assess maintainability problems
**Success Criteria:** Detailed quality assessment with specific improvement areas
**Next Step:** Planning agent will create refactoring strategy
```

#### Step 2: Planning Agent (Refactoring Strategy)

**Handoff:**

```md
**Context:** WeatherService has multiple quality issues - large functions, mixed responsibilities
**Task:** Create step-by-step refactoring plan
**Requirements:**
- Preserve all existing functionality
- Improve code organization and readability
- Follow single responsibility principle
- Plan incremental, safe changes
**Success Criteria:** Safe refactoring approach with clear milestones
**Next Step:** Testing agent will ensure adequate test coverage
```

#### Step 3: Testing Agent (Safety Testing)

**Handoff:**

```md
**Context:** Refactoring plan created to split WeatherService into focused components
**Task:** Ensure comprehensive test coverage before refactoring begins
**Requirements:**
- Verify all WeatherService functionality is tested
- Add missing test cases if needed
- Tests must pass before refactoring starts
- Create safety net for refactoring process
**Success Criteria:** Complete test coverage, all tests green
**Next Step:** Implementation agent will execute refactoring
```

#### Step 4: Implementation Agent (Refactoring)

**Handoff:**

```md
**Context:** WeatherService ready for refactoring with complete test coverage
**Task:** Execute refactoring plan while keeping all tests green
**Requirements:**
- Split WeatherService according to planning strategy
- Maintain exact same external API
- Keep all tests passing throughout process
- Follow incremental refactoring approach
**Success Criteria:** Improved code organization, all tests still green
**Next Step:** Review agent will verify quality improvements
```

#### Step 5: Review Agent (Final Quality Check)

**Handoff:**

```md
**Context:** WeatherService refactoring completed, all tests still passing
**Task:** Verify refactoring achieved quality goals
**Requirements:**
- Confirm improved code organization
- Validate maintainability improvements
- Check no functionality was lost
- Assess if further improvements needed
**Success Criteria:** Quality goals met, refactoring successful
**Next Step:** Refactoring complete
```

### Workflow Result

```md
✅ Refactoring Complete: WeatherService
- Split into WeatherService, WeatherParser, WeatherCache
- Reduced function complexity and file size
- Improved code organization and testability
- All existing functionality preserved
- Better separation of concerns achieved
```

---

## Example 4: Test Coverage Improvement

### User Request: Test Coverage
>
> "Add comprehensive tests for the NotificationService - I think our coverage is lacking."

### Main Agent Analysis: Test Coverage

- **Type:** Testing enhancement
- **Complexity:** Low-Medium (focused on testing)
- **Workflow:** Testing Enhancement (Testing → Testing → Implementation → Review)
- **Estimated Steps:** 4 agents, short-medium duration

## Workflow Execution

### Step 1: Testing Agent (Coverage Analysis)

**Handoff:**

```md
**Context:** User wants comprehensive tests for NotificationService
**Task:** Analyze current test coverage and identify gaps
**Requirements:**
- Review existing NotificationService tests
- Identify untested methods and scenarios
- Check edge case coverage
- Assess mock usage and integration testing
**Success Criteria:** Complete gap analysis with testing priorities
**Next Step:** Write missing tests to fill coverage gaps
```

#### Step 2: Testing Agent (Test Implementation)

**Direct continuation - same agent:**

```md
**Task:** Implement missing test cases identified in coverage analysis
**Requirements:**
- Follow existing test patterns and conventions
- Use proper mocking for external dependencies
- Cover both success and failure scenarios
- Include edge cases and boundary conditions
**Success Criteria:** Comprehensive test suite for NotificationService
```

#### Step 3: Implementation Agent (Test Support)

**Handoff:**

```md
**Context:** Comprehensive NotificationService tests written, some reveal missing functionality
**Task:** Add any missing functionality needed to support complete testing
**Requirements:**
- Add testable interfaces if needed
- Implement missing error handling revealed by tests
- Ensure all test scenarios can be properly validated
**Success Criteria:** All NotificationService tests pass, full functionality testable
**Next Step:** Review agent will validate test quality
```

#### Step 4: Review Agent (Test Quality Review)

**Handoff:**

```md
**Context:** Complete NotificationService test suite implemented
**Task:** Review test quality and coverage completeness
**Requirements:**
- Validate test effectiveness and clarity
- Check for proper test isolation
- Confirm edge cases are covered
- Assess maintainability of test code
**Success Criteria:** High-quality, maintainable test suite approved
**Next Step:** Testing enhancement complete
```

### Workflow Result

```md
✅ Testing Enhanced: NotificationService
- Complete test coverage for all public methods
- Edge cases and error scenarios covered
- Proper mocking of external dependencies
- Test quality meets project standards
- Improved confidence in notification functionality
```

---

## Quick Reference for Workflow Selection

| User Request Pattern | Recommended Workflow |
|---------------------|---------------------|
| "Add [feature]" | Feature Development |
| "[Something] is broken/crashes" | Bug Resolution |
| "Refactor/clean up [code]" | Quality Refactoring |
| "Add tests for [component]" | Testing Enhancement |
| "Review this [code/PR]" | Direct Review Agent |
| "Plan [complex feature]" | Direct Planning Agent |
| "Implement [specific task]" | Direct Implementation Agent |

**Remember:** Always provide rich context during handoffs and maintain workflow state throughout the process.
