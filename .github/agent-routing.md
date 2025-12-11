# Agent Routing Quick Reference

This is a practical guide for the main coordinator agent to quickly route requests and manage workflows.

## Quick Routing Decision Tree

### Keywords → Agent Mapping

**Planning Agent** triggers:

- plan, strategy, breakdown, analyze, requirements, design, architecture, approach, roadmap, milestones

**Implementation Agent** triggers:  

- implement, write, code, build, create, fix, develop, add, modify, update, refactor

**Testing Agent** triggers:

- test, TDD, coverage, verify, validate, unit test, integration, mock, assert

**Review Agent** triggers:

- review, check, analyze, quality, standards, security, performance, best practices

## Standard Workflows

### Workflow A: Complete Feature Development

```md
User Request Patterns:
- "Add [feature]"
- "Build [functionality]" 
- "Create [new component]"
- "I need [feature description]"

Flow:
Planning → Testing → Implementation → Review
```

### Workflow B: Bug Investigation & Fix

```md
User Request Patterns:
- "Fix [bug description]"
- "[Something] is not working"
- "There's an issue with [component]"
- "Debug [problem]"

Flow:
Review (analyze) → Testing (reproduce) → Implementation (fix) → Review (verify)
```

### Workflow C: Code Quality Improvement

```md
User Request Patterns:
- "Refactor [component]"
- "Improve [code quality aspect]"
- "Clean up [area]"
- "Optimize [performance]"

Flow:
Review (assess) → Planning (strategy) → Testing (safety) → Implementation → Review
```

### Workflow D: Testing Enhancement

```md
User Request Patterns:
- "Add tests for [component]"
- "Improve test coverage"
- "Test [functionality]"
- "TDD for [feature]"

Flow:
Testing (analyze gaps) → Testing (write tests) → Implementation (if needed) → Review
```

## Routing Logic

### Single Agent (Direct Route)

Route directly when:

- Request explicitly mentions agent specialty
- Task is clearly scoped to one agent
- No obvious dependencies or follow-up work needed

Examples:

- "Review this code" → Review Agent
- "Write tests for UserService" → Testing Agent  
- "Plan the authentication feature" → Planning Agent

### Multi-Agent (Workflow)

Use workflow when:

- Request involves multiple disciplines
- User wants complete end-to-end solution
- Task has natural sequential dependencies

Examples:

- "Add user login" → Workflow A (complete feature)
- "The app crashes on startup" → Workflow B (bug fix)
- "This code is messy" → Workflow C (quality improvement)

## Context Passing Between Agents

### Essential Information to Pass

**To Planning Agent:**

- User requirements (exact text)
- Business context from PRD.md
- Technical constraints from project-config.md
- Timeline or priority information

**To Testing Agent:**

- Component/feature being tested
- Expected behaviors and edge cases
- Existing test patterns to follow
- TDD context (write tests first?)

**To Implementation Agent:**

- Existing tests to make pass (TDD mode)
- Technical specifications from planning
- Code style requirements
- Integration points with existing code

**To Review Agent:**

- Specific areas of concern
- Context of what was changed/added
- Standards to check against
- Security or performance considerations

## Handoff Examples

### Planning → Testing

```md
**Handoff to Testing Agent**

**Context:** Planning agent analyzed user authentication requirements and created implementation plan
**Task:** Write comprehensive tests that define the authentication API and behavior
**Requirements:** Follow TDD approach - write failing tests for login, logout, token validation, and error handling
**Success Criteria:** Complete test suite that defines authentication interface
**Next Step:** Implementation agent will write code to make these tests pass
```

### Testing → Implementation  

```md
**Handoff to Implementation Agent**

**Context:** Tests written for authentication system - currently failing as expected
**Task:** Implement authentication code to make all tests pass
**Requirements:** Use GetX state management, follow project security patterns, minimal code to pass tests
**Success Criteria:** All authentication tests green, no breaking changes to existing code
**Next Step:** Review agent will validate implementation quality
```

## Quick Decision Checklist

Before routing, ask:

1. **Scope:** Single task or multiple related tasks?
2. **Dependencies:** Does this rely on or lead to other work?  
3. **Context:** Do I have enough information for the target agent?
4. **Workflow:** Is this part of a larger development process?
5. **User Intent:** Does user want planning or immediate action?

## Common Mistake Prevention

**Don't Route to Implementation First When:**

- User says "add feature" without planning
- No tests exist and TDD would be beneficial
- Complex feature that needs design thinking

**Don't Start Workflow When:**  

- User explicitly asks for just one agent type
- Task is truly standalone (like reviewing existing code)
- Quick fix or simple addition

**Always Include Context When:**

- Routing to any agent
- User provided specific details or constraints
- Previous agents have done related work

## Emergency Routing

**Critical Security Issue:** → Review Agent immediately
**Production Bug:** → Review (quick analysis) → Implementation (urgent fix)  
**Blocked Development:** → Planning Agent to resolve dependencies

---

**Remember:** When in doubt, ask the user for clarification rather than making assumptions about their intent.
