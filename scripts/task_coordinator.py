#!/usr/bin/env python3
"""
Cross-Session Task Coordinator

Aggregates tasks from all Claude Code sessions and manages dependencies.
Usage:
    python task_coordinator.py list              # Show all tasks across sessions
    python task_coordinator.py check <task-id>   # Check if task is ready
    python task_coordinator.py watch             # Watch for changes and trigger notifications
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime

CLAUDE_DIR = Path.home() / ".claude" / "todos"
MASTER_TASKS_FILE = Path(__file__).parent.parent / "TASKS.md"


def load_all_session_tasks() -> Dict[str, List[Dict[str, Any]]]:
    """Load tasks from all session files."""
    all_tasks = {}

    if not CLAUDE_DIR.exists():
        return all_tasks

    for task_file in CLAUDE_DIR.glob("*.json"):
        session_id = task_file.stem.split("-agent-")[0]
        try:
            with open(task_file, 'r') as f:
                tasks = json.load(f)
                if tasks:  # Only include sessions with tasks
                    all_tasks[session_id] = tasks
        except Exception as e:
            print(f"Error reading {task_file}: {e}", file=sys.stderr)

    return all_tasks


def get_task_status_summary(all_tasks: Dict[str, List[Dict[str, Any]]]) -> Dict[str, int]:
    """Get summary of task statuses across all sessions."""
    summary = {"pending": 0, "in_progress": 0, "completed": 0, "total": 0}

    for session_id, tasks in all_tasks.items():
        for task in tasks:
            status = task.get("status", "pending")
            summary[status] = summary.get(status, 0) + 1
            summary["total"] += 1

    return summary


def check_dependencies(task: Dict[str, Any], all_tasks: Dict[str, List[Dict[str, Any]]]) -> Dict[str, Any]:
    """Check if all dependencies for a task are completed."""
    blocked_by = task.get("blockedBy", [])

    if not blocked_by:
        return {"ready": True, "waiting_for": []}

    waiting_for = []

    # Search across all sessions for blocking tasks
    for session_id, tasks in all_tasks.items():
        for t in tasks:
            if t.get("id") in blocked_by:
                if t.get("status") != "completed":
                    waiting_for.append({
                        "id": t.get("id"),
                        "subject": t.get("subject"),
                        "status": t.get("status"),
                        "session": session_id
                    })

    return {
        "ready": len(waiting_for) == 0,
        "waiting_for": waiting_for
    }


def list_all_tasks():
    """List all tasks across all sessions."""
    all_tasks = load_all_session_tasks()

    if not all_tasks:
        print("No tasks found in any session.")
        return

    summary = get_task_status_summary(all_tasks)

    print("\n" + "="*80)
    print(f"MASTER TASK LIST - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)
    print(f"\nTotal: {summary['total']} tasks across {len(all_tasks)} sessions")
    print(f"  Pending: {summary.get('pending', 0)}")
    print(f"  In Progress: {summary.get('in_progress', 0)}")
    print(f"  Completed: {summary.get('completed', 0)}")
    print("\n" + "="*80 + "\n")

    for session_id, tasks in all_tasks.items():
        print(f"📁 Session: {session_id[:8]}...")
        print("-" * 80)

        for task in tasks:
            task_id = task.get("id", "?")
            subject = task.get("subject", "No subject")
            status = task.get("status", "pending")
            owner = task.get("owner", "")

            # Check dependencies
            dep_check = check_dependencies(task, all_tasks)

            status_icon = {
                "pending": "⏳",
                "in_progress": "🔄",
                "completed": "✅"
            }.get(status, "❓")

            print(f"  {status_icon} #{task_id} [{status.upper()}] {subject}")

            if owner:
                print(f"      👤 Owner: {owner}")

            if task.get("blockedBy"):
                if dep_check["ready"]:
                    print(f"      ✅ Dependencies satisfied")
                else:
                    print(f"      🚫 Blocked by:")
                    for blocker in dep_check["waiting_for"]:
                        print(f"         - #{blocker['id']} ({blocker['status']}) in session {blocker['session'][:8]}...")

            print()

        print()


def check_task_ready(task_id: str):
    """Check if a specific task is ready to start."""
    all_tasks = load_all_session_tasks()

    # Find the task
    found_task = None
    found_session = None

    for session_id, tasks in all_tasks.items():
        for task in tasks:
            if str(task.get("id")) == task_id:
                found_task = task
                found_session = session_id
                break
        if found_task:
            break

    if not found_task:
        print(f"❌ Task #{task_id} not found in any session.")
        return

    dep_check = check_dependencies(found_task, all_tasks)

    print(f"\n📋 Task #{task_id}: {found_task.get('subject')}")
    print(f"📁 Session: {found_session[:8]}...")
    print(f"📊 Status: {found_task.get('status', 'pending').upper()}")

    if dep_check["ready"]:
        print("\n✅ READY TO START - All dependencies satisfied!")
    else:
        print("\n🚫 NOT READY - Waiting for:")
        for blocker in dep_check["waiting_for"]:
            print(f"   - Task #{blocker['id']}: {blocker['subject']}")
            print(f"     Status: {blocker['status']} (Session: {blocker['session'][:8]}...)")

    print()


def watch_tasks():
    """Watch for task changes and trigger notifications."""
    print("👀 Watching for task changes...")
    print("(This is a placeholder - implement with file watching or polling)")
    print("\nTo implement:")
    print("  1. Use watchdog library to monitor ~/.claude/todos/")
    print("  2. On change, check dependencies")
    print("  3. Trigger notifications (webhook, slack, email, etc.)")
    print("  4. Update TASKS.md with current status")


def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  task_coordinator.py list              # Show all tasks")
        print("  task_coordinator.py check <task-id>   # Check if task is ready")
        print("  task_coordinator.py watch             # Watch for changes")
        sys.exit(1)

    command = sys.argv[1]

    if command == "list":
        list_all_tasks()
    elif command == "check":
        if len(sys.argv) < 3:
            print("Error: Please provide a task ID")
            sys.exit(1)
        check_task_ready(sys.argv[2])
    elif command == "watch":
        watch_tasks()
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
