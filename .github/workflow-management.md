# Workflow Management for Main Agent

This guide provides templates and procedures for managing multi-agent workflows.

## Workflow State Tracking

### Workflow Status Types

- `PLANNED` - Workflow defined, not started
- `IN_PROGRESS` - Currently executing workflow steps
- `WAITING` - Waiting for agent response or user input
- `BLOCKED` - Cannot proceed due to dependency/issue
- `COMPLETED` - Workflow successfully finished
- `FAILED` - Workflow failed, requires intervention

### Workflow Context Template

```md
**Workflow:** [Workflow Name]
**Status:** [Current Status]
**Step:** [Current Step Number]/[Total Steps]
**Current Agent:** [Which agent is working]
**Started:** [Timestamp]
**User Goal:** [Original user request]

**Progress:**
- ✅ Step 1: [Completed step description]
- 🔄 Step 2: [Current step description] (Agent working)
- ⏳ Step 3: [Pending step description]
- ⏳ Step 4: [Pending step description]

**Context Data:**
- [Key information gathered during workflow]
- [Decisions made or constraints identified]
- [Files or components being worked on]
```

## Standard Workflow Templates

### Template 1: Feature Development Workflow

```md
**Workflow Name:** Feature Development
**Participants:** Planning → Testing → Implementation → Review
**Duration:** Medium to Long
**Best For:** New features, significant functionality additions

**Step 1: Requirements Analysis (Planning Agent)**
- Input: User requirements, business context
- Output: Implementation plan, technical design, acceptance criteria
- Success: Clear roadmap with defined scope and approach

**Step 2: Test Definition (Testing Agent)**  
- Input: Implementation plan from Step 1
- Output: Comprehensive test suite (failing tests for TDD)
- Success: Tests define complete API and behavior expectations

**Step 3: Implementation (Implementation Agent)**
- Input: Failing tests from Step 2, design from Step 1
- Output: Working code that passes all tests
- Success: All tests green, feature functional

**Step 4: Quality Review (Review Agent)**
- Input: Complete implementation from Step 3
- Output: Code quality assessment, recommendations
- Success: Code meets project standards, ready for production
```

### Template 2: Bug Investigation & Fix

```md
**Workflow Name:** Bug Resolution
**Participants:** Review → Testing → Implementation → Review
**Duration:** Short to Medium
**Best For:** Bug reports, unexpected behavior, production issues

**Step 1: Root Cause Analysis (Review Agent)**
- Input: Bug report, symptoms, affected code
- Output: Root cause identification, impact assessment
- Success: Clear understanding of what's wrong and why

**Step 2: Reproduction Test (Testing Agent)**
- Input: Root cause analysis from Step 1  
- Output: Test that reproduces the bug (failing test)
- Success: Reliable test that demonstrates the issue

**Step 3: Bug Fix (Implementation Agent)**
- Input: Failing test from Step 2, root cause from Step 1
- Output: Code fix that makes test pass
- Success: Bug test passes, no regression in other tests

**Step 4: Fix Verification (Review Agent)**
- Input: Fix implementation from Step 3
- Output: Verification that fix is complete and safe
- Success: Bug resolved, no side effects introduced
```

### Template 3: Code Quality Improvement

```md
**Workflow Name:** Quality Refactoring  
**Participants:** Review → Planning → Testing → Implementation → Review
**Duration:** Medium
**Best For:** Code cleanup, performance optimization, maintainability

**Step 1: Quality Assessment (Review Agent)**
- Input: Existing code, quality concerns
- Output: Detailed analysis of quality issues
- Success: Clear list of problems and improvement priorities

**Step 2: Refactoring Strategy (Planning Agent)**
- Input: Quality assessment from Step 1
- Output: Step-by-step refactoring plan
- Success: Safe refactoring approach that preserves functionality

**Step 3: Safety Testing (Testing Agent)**
- Input: Current code, refactoring plan from Step 2
- Output: Comprehensive test coverage for existing behavior
- Success: Tests ensure no functionality lost during refactoring

**Step 4: Refactoring Implementation (Implementation Agent)**
- Input: Refactoring plan from Step 2, safety tests from Step 3
- Output: Improved code that passes all existing tests
- Success: Code quality improved, all tests still green

**Step 5: Final Quality Check (Review Agent)**
- Input: Refactored code from Step 4
- Output: Verification of quality improvements
- Success: Confirmed that refactoring achieved quality goals
```

## Workflow Coordination Procedures

### Starting a Workflow

1. **Analyze User Request**
   - Identify workflow type needed
   - Gather initial context and requirements
   - Set user expectations about multi-step process

2. **Initialize Workflow State**
   - Create workflow tracking record
   - Define all steps and success criteria
   - Set initial status to `PLANNED`

3. **Begin First Step**
   - Route to appropriate first agent
   - Provide complete context and requirements
   - Update status to `IN_PROGRESS`

### Managing Workflow Steps

#### Between Steps (Handoff)

```md
**Step [X] Complete ✅**
**Agent:** [Completing Agent Name]
**Output:** [What was delivered]
**Status:** [Success/Issues]

**Initiating Step [X+1] 🔄**
**Next Agent:** [Target Agent]
**Input:** [What previous step provided]
**Task:** [Specific task for next agent]
**Context:** [Relevant background information]
**Expected Output:** [What next step should deliver]
```

#### When Steps Fail

```md
**Step [X] Failed ❌**
**Agent:** [Agent that encountered issue]
**Issue:** [What went wrong]
**Impact:** [How this affects workflow]

**Resolution Options:**
1. Retry with modified approach
2. Escalate to different agent
3. Request user clarification
4. Abort workflow

**Recommended Action:** [Choice with justification]
```

### Workflow Completion

#### Successful Completion

```md
**Workflow Complete ✅**
**Goal:** [Original user request]
**Result:** [What was accomplished]
**Artifacts:** [Code/tests/docs created]

**Summary:**
- Planning: [What was planned]
- Testing: [What tests were created]  
- Implementation: [What code was written]
- Review: [Quality verification results]

**Ready for:** [Next steps user can take]
```

#### Failed Workflow

```md
**Workflow Failed ❌**  
**Goal:** [Original user request]
**Failure Point:** [Where workflow broke down]
**Reason:** [Why it failed]

**Completed Steps:**
- [List what was successfully done]

**Recommendations:**
- [How user can proceed]
- [What needs to be addressed]
- [Alternative approaches]
```

## Special Situations

### User Intervention Required

When workflow needs user input:

```md
**Workflow Paused - User Input Needed ⏸️**
**Current Step:** [Where we are]
**Question:** [What we need to know]
**Options:** [If applicable]
**Impact:** [How this affects next steps]

**To Resume:** [What user needs to provide]
```

### Agent Conflict Resolution

When agents provide conflicting recommendations:

```md
**Agent Conflict Detected ⚠️**
**Agents:** [Which agents disagree]
**Conflict:** [What they disagree about]
**Options:**
1. [Agent A's recommendation + rationale]
2. [Agent B's recommendation + rationale]

**Recommendation:** [Main agent's decision + reasoning]
**Proceeding With:** [Chosen approach]
```

### Emergency Workflow Termination

Critical issues that require immediate stop:

```md
**WORKFLOW TERMINATED - EMERGENCY 🚨**
**Reason:** [Critical issue discovered]
**Immediate Action Required:** [What user must do]
**Safety:** [Steps to prevent damage]
**Recovery:** [How to resume later if possible]
```

---

**Key Principle:** Always maintain workflow context and keep user informed of progress and any issues that arise.
