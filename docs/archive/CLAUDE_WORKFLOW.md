# Claude Code Session & Task Management Workflow

This guide defines best practices for managing Claude Code sessions and tasks across the project lifecycle.

## Table of Contents

1. [Session Start Workflow](#session-start-workflow)
2. [Task Management](#task-management)
3. [Session End Workflow](#session-end-workflow)
4. [Multi-Session Coordination](#multi-session-coordination)
5. [Best Practices](#best-practices)

---

## Session Start Workflow

### Starting a New Session

```bash
# Option 1: Start fresh session (new session ID generated)
claude

# Option 2: Resume previous session (preserves tasks and context)
claude --resume <session-id>

# Option 3: Interactive session picker
claude --resume
```

### Session Initialization Checklist

When starting ANY session (new or resumed), Claude should:

1. **Check for active tasks**
   ```
   /tasks
   ```

2. **Review project context**
   - Read `CLAUDE.md` for project overview
   - Check `TASK.md` or session notes if they exist
   - Review recent git commits for context

3. **Identify current session ID**
   - Session ID is shown in the prompt or can be found in logs
   - Format: UUID like `6d3cb2e1-29ce-4596-8225-f9079d2972ec`

4. **Ask user about priorities**
   - What should I focus on today?
   - Are there blockers from previous sessions?
   - Any urgent issues to address?

### Example Session Start

```markdown
## Session Start: 2026-01-29

**Session ID**: 6d3cb2e1-29ce-4596-8225-f9079d2972ec
**Working Directory**: ~/dev/icb/highspring

### Active Tasks
- Task #2 [pending]: Update ETL to populate department dimension
- Task #5 [in_progress]: Security audit of credentials

### Recent Commits
- 101ec2b: SECURITY: Remove hardcoded database credentials
- d7f5c7b: Add testing documentation and technical specifications

### Today's Focus
[User provides priorities]
```

---

## Task Management

### When to Create Tasks

**Always create tasks for:**
- Complex work with 3+ steps
- Multi-file changes
- Work that spans multiple sessions
- Work with dependencies between steps
- When user provides numbered lists of work

**Don't create tasks for:**
- Single file reads or simple queries
- Trivial one-step operations
- Pure research/exploration (use Task tool with Explore agent instead)

### Task Creation Pattern

**Step 1: Break down work into tasks**

```
User: "I need to add a new dimension for departments, update ETL, and run validation"

Claude creates 3 tasks:
1. Add new dimension table
2. Update ETL procedures
3. Run validation tests
```

**Step 2: Set up dependencies**

```
Task 2 blockedBy: [Task 1]
Task 3 blockedBy: [Task 2]
```

**Step 3: Mark as in_progress before starting work**

```
Before writing code:
TaskUpdate(taskId=1, status="in_progress")

After completing:
TaskUpdate(taskId=1, status="completed")
```

### Task Lifecycle

```
pending → in_progress → completed
   ↓
deleted (if no longer needed)
```

### Task Fields Best Practices

| Field | Guidelines | Example |
|-------|-----------|---------|
| **subject** | Imperative form, clear outcome | "Add Dim_Department table" |
| **description** | Detailed enough for another agent to complete | "Create tbl_Dim_Department with SK, BK, ValidFrom, ValidTo, IsCurrent columns following standard pattern" |
| **activeForm** | Present continuous (shown in spinner) | "Adding department dimension" |
| **status** | pending/in_progress/completed/deleted | "in_progress" |
| **owner** | Agent name if delegated | "etl-specialist-agent" |
| **blocks** | Tasks waiting on this one | [3, 4] |
| **blockedBy** | Tasks that must complete first | [1] |

### Task Management Commands

```bash
# View all tasks in current session
/tasks

# Using tools (Claude uses these):
TaskCreate     - Create new task
TaskUpdate     - Update status, owner, dependencies
TaskList       - View all tasks summary
TaskGet        - Get full task details including description
```

---

## Session End Workflow

### Before Ending a Session

Claude should:

1. **Review task status**
   ```
   TaskList()
   ```

2. **Update in-progress tasks**
   - Mark completed tasks as `completed`
   - Update partially complete tasks with progress notes
   - Don't leave tasks in `in_progress` unless actively blocked

3. **Create session summary** (if significant work done)
   - What was accomplished
   - What's pending
   - Any blockers or issues
   - Next steps

4. **Commit and push changes** (if code was written)
   ```bash
   git add .
   git commit -m "Descriptive message

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   git push origin main
   ```

5. **Document important decisions** (if needed)
   - Update CLAUDE.md with new patterns
   - Update TASK.md with next steps
   - Create notes for future sessions

### Session Summary Template

```markdown
## Session End Summary

**Session ID**: 6d3cb2e1-29ce-4596-8225-f9079d2972ec
**Duration**: [Start time] - [End time]
**Date**: 2026-01-29

### Completed Tasks
- ✅ Task #1: Add new dimension table
- ✅ Task #13: Remove database credentials from all files

### In Progress
- 🔄 Task #2: Update ETL to populate department dimension
  - Status: Stored procedure created, needs testing

### Pending
- ⏳ Task #5: Run validation on new dimension

### Commits Made
- 101ec2b: SECURITY: Remove hardcoded database credentials
- d7f5c7b: Add testing documentation

### Blockers/Issues
- None

### Next Session Priorities
1. Complete Task #2 (test ETL procedure)
2. Start Task #5 (validation)
3. Review Power BI model integration

### Notes for Next Session
- Remember to verify .env configuration works
- Check if CONFIG.md needs examples
```

---

## Multi-Session Coordination

### Using Shared Task Files

When coordinating across multiple concurrent sessions:

**Create TASKS.md in repository root:**

```markdown
# Master Task List

## Session A: Data Modeling (Session ID: uuid-aaaa)
- [ ] Task A1: Design dimension tables
- [ ] Task A2: Create DDL scripts

## Session B: ETL Development (Session ID: uuid-bbbb)
- [ ] Task B1: Build ETL procedures (depends on A1, A2)

## Session C: Power BI (Session ID: uuid-cccc)
- [ ] Task C1: Update TMDL model (depends on A1, A2)

## Session D: Testing (Session ID: uuid-dddd)
- [ ] Task D1: Validation suite (depends on B1, C1)
```

**Each session checks TASKS.md:**
1. Before starting work - verify dependencies complete
2. After completing work - mark task done, notify blockers

### Cross-Session Task Coordination Script

Use the existing `scripts/task_coordinator.py`:

```bash
# View all tasks across all sessions
python scripts/task_coordinator.py list

# Check if specific task is ready
python scripts/task_coordinator.py check 5

# Watch for changes (implementation needed)
python scripts/task_coordinator.py watch
```

---

## Best Practices

### Task Management

✅ **DO:**
- Create tasks at the start of multi-step work
- Mark tasks `in_progress` BEFORE starting work
- Mark tasks `completed` only when fully done
- Set up `blockedBy`/`blocks` for dependencies
- Use clear, specific task subjects
- Write detailed descriptions

❌ **DON'T:**
- Create tasks for trivial operations
- Leave tasks in `in_progress` when blocked
- Mark incomplete tasks as `completed`
- Create vague task descriptions
- Forget to update task status

### Session Management

✅ **DO:**
- Resume sessions when continuing previous work
- Check `/tasks` at session start
- Create session summaries for significant work
- Commit work before ending sessions
- Document important decisions in CLAUDE.md

❌ **DON'T:**
- Start new sessions for continuation work
- Forget to check existing tasks
- End sessions with uncommitted changes
- Leave unclear state for next session

### Git Workflow

✅ **DO:**
- Commit after completing each major task
- Use descriptive commit messages
- Include "Co-Authored-By: Claude Sonnet 4.5"
- Push to remote before session ends
- Create branches for experimental work

❌ **DON'T:**
- Commit WIP without clear status
- Use vague commit messages
- Push untested changes to main
- Leave local commits unpushed

### Communication

✅ **DO:**
- Proactively create tasks for complex work
- Update user on progress during long operations
- Ask clarifying questions before starting
- Explain architectural decisions
- Reference file locations with line numbers

❌ **DON'T:**
- Start work without understanding requirements
- Make assumptions about preferences
- Surprise user with major changes
- Skip explaining tradeoffs

---

## Task Storage Location

Tasks are automatically persisted:

```
~/.claude/todos/<session-id>-agent-<session-id>.json
```

- Saved automatically when session ends
- Restored when session is resumed
- Can be read by external tools/scripts

---

## Quick Reference

### Starting Work

```bash
# 1. Resume session (or start new)
claude --resume <session-id>

# 2. Check tasks
/tasks

# 3. Create tasks if needed
TaskCreate(subject="...", description="...", activeForm="...")

# 4. Mark task in progress
TaskUpdate(taskId=X, status="in_progress")

# 5. Do work...

# 6. Mark completed
TaskUpdate(taskId=X, status="completed")
```

### Ending Session

```bash
# 1. Review tasks
/tasks

# 2. Update any in_progress tasks

# 3. Commit changes
git add .
git commit -m "Message"
git push origin main

# 4. Create session summary (if needed)

# 5. End session
exit
```

### Resuming Session

```bash
# Find recent sessions
claude --resume

# Or use specific ID
claude --resume 6d3cb2e1-29ce-4596-8225-f9079d2972ec

# Tasks will be automatically restored!
```

---

## Troubleshooting

**Q: My tasks disappeared!**
- Tasks are session-specific
- Make sure you resumed the correct session ID
- Check `~/.claude/todos/<session-id>-agent-<session-id>.json`

**Q: Can I see tasks from other sessions?**
- Not via `/tasks` or TaskList tool
- Use `scripts/task_coordinator.py list` for cross-session view
- Or manually read JSON files in `~/.claude/todos/`

**Q: Should I use TaskList or /tasks?**
- `/tasks` is the user command (you type it)
- `TaskList` is the tool (Claude calls it)
- Both show the same information

**Q: How do I hand off work to another session?**
- Create tasks with clear descriptions
- Update TASKS.md with dependencies
- Include session ID in TASKS.md
- Other session can check blockers before starting

---

## Examples

### Example 1: Single Session with Sequential Tasks

```
Session Start:
  TaskCreate #1: Design schema
  TaskCreate #2: Write DDL (blockedBy: [1])
  TaskCreate #3: Test deployment (blockedBy: [2])

Work:
  TaskUpdate #1 → in_progress
  [design work]
  TaskUpdate #1 → completed

  TaskUpdate #2 → in_progress
  [write DDL]
  TaskUpdate #2 → completed

  TaskUpdate #3 → in_progress
  [test deployment]
  TaskUpdate #3 → completed

Session End:
  All tasks completed ✓
  Committed and pushed ✓
```

### Example 2: Multi-Session Coordination

```
Session A (Data):
  TaskCreate #A1: Create dimensions
  TaskUpdate #A1 → in_progress
  [work]
  TaskUpdate #A1 → completed
  Update TASKS.md: Mark A1 done

Session B (ETL):
  Check TASKS.md: A1 completed ✓
  TaskCreate #B1: Build ETL (blockedBy from TASKS.md context)
  TaskUpdate #B1 → in_progress
  [work]
  TaskUpdate #B1 → completed
  Update TASKS.md: Mark B1 done

Session C (Testing):
  Check TASKS.md: A1 ✓, B1 ✓
  TaskCreate #C1: Run validation
  TaskUpdate #C1 → in_progress
  [work]
  TaskUpdate #C1 → completed
```

---

## Integration with CLAUDE.md

This workflow should be referenced in `CLAUDE.md`:

```markdown
## Session Management

See [docs/CLAUDE_WORKFLOW.md](docs/CLAUDE_WORKFLOW.md) for:
- Session start/end procedures
- Task management best practices
- Multi-session coordination
```

---

## Version History

- **2026-01-29**: Initial workflow documentation
- Added session start/end checklists
- Defined task lifecycle and best practices
- Created multi-session coordination guide
