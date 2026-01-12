---
name: tmux-awareness
description: This skill is AUTOMATICALLY ENABLED when Claude runs inside tmux. Claude will automatically use tmux for background processes, parallel agents, and long-running tasks. Ask Claude to "run this in the background", "spawn a parallel agent", "start a dev server", "watch for completion", or any other parallel/background work. The SessionStart hook auto-detects tmux and injects capabilities.
version: 1.0.0
---

# Tmux Awareness Skill

**AUTO-ENABLED:** When Claude runs inside tmux, the SessionStart hook automatically detects this and injects tmux context. Claude will see "TMUX_ENVIRONMENT_DETECTED" at session start and **will automatically use tmux capabilities for all background processes, parallel agents, and long-running tasks**.

You don't need to tell Claude which tmux script to use - Claude understands it's in tmux and will automatically make the right choice.

## CRITICAL: Current Session vs Background Windows

**When to use the CURRENT session (split-window):**
- User asks to "show", "display", "run side by side", or wants to SEE something
- Visual tools like htop, lazygit, logs, monitoring
- Any request that implies the user wants to watch the output
- Default behavior for panes/splits

**When to use a NEW background window (spawn-window.sh):**
- User explicitly says "in the background", "background window", "don't need to see"
- Long-running servers, test suites, builds
- Tasks where user wants to continue working without watching

**NEVER use `tmux new-session`** - always work within the current session. Use `split-window` for visible panes or `new-window` for background work.

```bash
# CORRECT - split current window for visible work
tmux split-window -h
tmux send-keys "htop" Enter

# CORRECT - new window for background work
tmux new-window -d -n "server"
tmux send-keys -t server "npm start" Enter

# WRONG - never create new sessions!
tmux new-session -d -s newsession  # DO NOT DO THIS
```

## Automatic Detection

On every session start, the plugin runs `detect-tmux-context.sh` which:
1. Checks if running inside tmux
2. If yes, outputs session info and available capabilities
3. If no, stays silent

**If you see "TMUX_ENVIRONMENT_DETECTED" in your session context, all tmux features are available.**

## Core Concepts

### Panes vs Windows

- **Panes** (split current window): For things the user should **see** while working
  - Parallel Claude agents user wants to monitor
  - Live output from commands
  - Side-by-side work

- **Windows** (separate): For **background workers** out of the way
  - Dev servers
  - File watchers
  - Long-running processes

## How Claude Uses This Skill

When you ask Claude to do background work, parallel tasks, or run servers, Claude automatically:

1. **Detects you're in tmux** - Sees `TMUX_ENVIRONMENT_DETECTED` in context
2. **Makes smart decisions** - Chooses whether to use visible panes or background windows
3. **Manages processes** - Spawns agents, monitors completion, captures output
4. **Handles failures** - Retries on timeout, displays errors
5. **Queues continuations** - Reminds you in the next session if needed

You just ask Claude what you need, and it uses the appropriate tmux script automatically.

## What Claude Can Do

### Ask Claude to Create Visible Panes (Side-by-Side Work)
```
Run Claude in a visible split pane to review this code while I continue working
```
Claude will use `spawn-pane.sh` to split the current window.

### Ask Claude to Create Background Windows (Servers, Long Tasks)
```
Start the dev server in a background window and let me know when it's ready
```
Claude will use `spawn-window.sh` to create a separate window and `wait-for-text.sh` to detect readiness.

### Ask Claude to Monitor Output
```
Show me the logs from the background server
```
Claude will use `capture-output.sh` to get the output without switching windows.

### Ask Claude for Self-Continuation
```
Run the tests in the background. When done, queue a message telling me if they passed.
```
Claude will use `spawn-window.sh` for the tests and `queue-message.sh` to remind you in the next session.

## Available Scripts (For Reference)

Claude uses these scripts automatically:
- `detect-session.sh` - Get tmux context
- `spawn-pane.sh` - Create visible split pane
- `spawn-window.sh` - Create background window
- `wait-for-text.sh` - Wait for pattern in output
- `capture-output.sh` - Get pane contents
- `queue-message.sh` - Queue message for next session

You don't need to call these directly - just ask Claude what you need!

## Common Patterns

Ask Claude using natural language:

### Parallel Bug Fixes

```
Fix these 3 bugs in parallel:
1. Auth timeout bug in login.py
2. 500 error in /api/users endpoint
3. Button alignment issue in header

Spawn a separate Claude agent for each in background windows.
Report when all are complete.
```

Claude will spawn 3 agents in background windows and monitor their completion.

### Dev Server with Live Logs

```
Start the dev server in a background window and show me the logs in a visible pane.
Wait until the server is ready on port 3000, then let me know.
```

Claude will create a background window for the server, a visible pane for logs, and monitor for readiness.

### Build and Notify

```
Run the full build and test suite in the background.
When it's done, queue a message telling me if it passed and whether we should deploy to staging.
```

Claude will spawn the build in a background window and queue a reminder for the next session with the results.

## Script Reference

| Script | Purpose |
|--------|---------|
| `detect-session.sh` | Check if in tmux, get session info |
| `spawn-pane.sh` | Create visible split pane |
| `spawn-window.sh` | Create background window |
| `wait-for-text.sh` | Wait for pattern in pane output |
| `capture-output.sh` | Get recent pane contents |
| `queue-message.sh` | Queue message for next session |

All scripts are in `{baseDir}/scripts/` and return JSON for easy parsing.

## Tips for Best Results

1. **Be descriptive** - Tell Claude clearly what you want (visible vs background, how long to wait, etc)
2. **Use natural language** - No need to know which script to use; Claude figures it out
3. **Describe outcomes** - "Wait for the server to be ready" is better than "spawn server"
4. **Queue important work** - Ask Claude to queue messages if you need reminders in the next session
5. **Check logs** - Ask Claude to "show me the logs" or "what's happening in the background" anytime
6. **Set timeouts** - Tell Claude "wait up to 5 minutes" if tasks are slow
