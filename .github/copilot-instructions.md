# Copilot Instructions

Quick reference for GitHub Copilot and AI assistants working in this Flutter project.

**For specialized tasks, use the agent coordination system in `.github/agent-*.md`**

---

## Agent Coordination System

**⚠️ IMPORTANT**: All referenced agent files exist and are complete. Always verify file existence using `list_dir` or `file_search` tools before assuming files are missing.

### Main Agent (You!)

- **Agent Coordinator**: `.github/agent-main.md` - Route requests, manage workflows
- **Routing Guide**: `.github/agent-routing.md` - Quick decision tree for task routing
- **Workflow Management**: `.github/workflow-management.md` - Multi-agent coordination
- **Examples**: `.github/workflow-examples.md` - Common development scenarios

### Specialized Agents

- **Planning Agent**: `.github/agent-planning.md` - Requirements analysis, task breakdown
- **Implementation Agent**: `.github/agent-implementation.md` - Code writing, feature development
- **Testing Agent**: `.github/agent-testing.md` - TDD workflows, test creation, test fixing
- **Review Agent**: `.github/agent-review.md` - Code review, quality assessment

## Essential Context

- **Project Config**: `.github/project-config.md` - project-specific settings
- **Product**: `PRD.md` - features, users, goals
- **Strategy**: `PLAN.md` - milestones, execution plan

---

## AI Agent Guidelines

### File Verification

- **Always verify before assuming**: Use `list_dir`, `file_search`, or `read_file` tools to check file existence
- **Complete system**: This project has a complete agent coordination system - all referenced `.github/agent-*.md` files exist
- **Check workspace structure**: Use tools to explore rather than relying on incomplete context

### Error Prevention

- Don't make assumptions about missing files without verification
- When in doubt, check the actual directory structure
- Reference the complete agent system when routing complex tasks

---

## Core Standards

### Platform & Tools

See `.github/project-config.md` for project-specific versions and requirements.

### Code Style (Quick Reference)

- Single quotes for strings (`'text'`)
- Arrow functions for callbacks (`() => action()`)
- Async/await (not `.then()`)
- Enums instead of string constants
- `///` docs for public APIs

### File Limits

- **UI files**: ≤200-250 lines (use `part`/`part of`)
- **Functions**: ≤30-50 lines (extract helpers)

### Testing

- **Mandatory**: All `expect` calls must have `reason` property
- **Location**: `test/` directory
- **Patterns**: Follow GetX, Hive patterns

---

## Security & Environment

```dart
// ❌ Never hardcode secrets
const apiKey = 'abc123';

// ✅ Use environment variables
final apiKey = dotenv.env['API_KEY'];
```

See `.github/project-config.md` for specific API keys and environment setup.

---

## Build Commands

```bash
flutter pub get          # Dependencies
flutter analyze          # Code analysis
flutter test            # Run tests
flutter build apk --debug  # Build
dart run update_version.dart  # Version bump for commits
```

---

## Quick Decision Guide

**Complex multi-step tasks:**

- Use the main agent coordination system (`.github/agent-main.md`)
- Reference routing guide for quick decisions (`.github/agent-routing.md`)
- Follow workflow management for multi-agent coordination

**Single-purpose tasks:**

- Planning & analysis → `.github/agent-planning.md`
- Code implementation → `.github/agent-implementation.md`
- Test creation → `.github/agent-testing.md`
- Code review → `.github/agent-review.md`

**Simple changes:** Follow core standards above

---

**For GitHub Copilot: You are the main coordinator agent. Use the system in `.github/agent-main.md` to route requests and coordinate workflows between specialized agents.**
