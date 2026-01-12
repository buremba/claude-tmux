---
name: tmux-awareness
description: This skill is AUTOMATICALLY ENABLED when Claude runs inside tmux. Use for "run parallel Claude agents", "spawn agent in pane", "start background server", "run dev server", "watch in background", "queue message for later", "self-continuation", "check tmux status", "split pane", "new window", or any parallel execution, background processes, or tmux operations. The SessionStart hook auto-detects tmux and injects capabilities.
version: 1.0.0
---

# Tmux Awareness Skill

**AUTO-ENABLED:** When Claude runs inside tmux, the SessionStart hook automatically detects this and injects tmux context. Claude will see "TMUX_ENVIRONMENT_DETECTED" at session start with available capabilities.

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

## Session Detection

Get current tmux context:

```bash
{baseDir}/scripts/detect-session.sh
```

Returns JSON:
```json
{
  "in_tmux": true,
  "session": "main",
  "window": 0,
  "pane": 0,
  "target": "main:0.0"
}
```

## Creating Visible Panes

Split the current window to show parallel work:

```bash
# Horizontal split (side by side)
{baseDir}/scripts/spawn-pane.sh -d h -c "claude --print 'Review the PR'"

# Vertical split (stacked)
{baseDir}/scripts/spawn-pane.sh -d v -c "npm run watch"

# Custom size (30% of space)
{baseDir}/scripts/spawn-pane.sh -d h -p 30 -c "tail -f logs/app.log"
```

Returns JSON with pane target for monitoring.

## Creating Background Windows

Create a separate window for background workers:

```bash
# Dev server (stays in current window)
{baseDir}/scripts/spawn-window.sh -n "dev-server" -c "npm run dev"

# Another Claude agent
{baseDir}/scripts/spawn-window.sh -n "agent-fix-tests" -c "claude --print 'Fix failing tests'"

# Switch to the new window
{baseDir}/scripts/spawn-window.sh -n "monitor" -c "htop" --switch
```

Returns JSON with window target.

## Monitoring Output

### Capture Pane Contents

```bash
# Get last 100 lines from a target
{baseDir}/scripts/capture-output.sh -t "dev-server:0.0" -l 100

# JSON output with metadata
{baseDir}/scripts/capture-output.sh -t "agent-1:0.0" -l 50 --json
```

### Wait for Pattern

```bash
# Wait for server to be ready (30s timeout)
{baseDir}/scripts/wait-for-text.sh -t "dev-server:0.0" -p "ready on port" -T 30

# Wait for shell prompt (agent completed)
{baseDir}/scripts/wait-for-text.sh -t "agent-1:0.0" -p '^\$' -T 300

# Wait for fixed string
{baseDir}/scripts/wait-for-text.sh -t "build:0.0" -p "Build successful" -F
```

## Direct Tmux Commands

For operations not covered by helper scripts, use tmux directly:

### List Windows and Panes

```bash
# List all windows
tmux list-windows -F '#{window_index}: #{window_name} (#{window_panes} panes)'

# List all panes across windows
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'
```

### Send Keys to Pane

```bash
# Send command to background pane
tmux send-keys -t "dev-server:0.0" "npm run build" Enter

# Send Ctrl-C to stop a process
tmux send-keys -t "dev-server:0.0" C-c
```

### Kill Window or Pane

```bash
# Kill a window
tmux kill-window -t "dev-server"

# Kill a pane
tmux kill-pane -t "main:0.1"
```

## Self-Continuation

Queue messages for the next Claude session:

```bash
# Queue a reminder
{baseDir}/scripts/queue-message.sh "Check if the build passed and deploy to staging"

# Queue from stdin
echo "Review the PR comments from Alice" | {baseDir}/scripts/queue-message.sh -
```

Messages are stored in `~/.claude/tmux-messages/` and delivered when the next Claude session starts.

## Common Patterns

### Parallel Bug Fixes

```bash
# Spawn 3 agents to fix different bugs
{baseDir}/scripts/spawn-window.sh -n "bug-auth" -c "claude --print 'Fix auth timeout bug in login.py'"
{baseDir}/scripts/spawn-window.sh -n "bug-api" -c "claude --print 'Fix 500 error in /api/users'"
{baseDir}/scripts/spawn-window.sh -n "bug-ui" -c "claude --print 'Fix button alignment in header'"

# Monitor completion
for win in bug-auth bug-api bug-ui; do
  {baseDir}/scripts/wait-for-text.sh -t "$win:0.0" -p '^\$' -T 600
done
```

### Dev Server with Live Logs

```bash
# Start server in background window
{baseDir}/scripts/spawn-window.sh -n "server" -c "npm run dev"

# Show logs in visible pane
{baseDir}/scripts/spawn-pane.sh -d v -p 30 -c "tail -f logs/server.log"

# Wait for server ready
{baseDir}/scripts/wait-for-text.sh -t "server:0.0" -p "listening on" -T 30
```

### Build and Notify Next Session

```bash
# Start build in background
{baseDir}/scripts/spawn-window.sh -n "build" -c "npm run build && echo 'BUILD_DONE'"

# Queue message for follow-up
{baseDir}/scripts/queue-message.sh "Check build results in 'build' window. If successful, deploy to staging."
```

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

## Tips

1. **Use `--print` mode** for Claude agents when non-interactive execution is needed
2. **Name windows descriptively** - makes monitoring easier
3. **Check session first** - always verify in_tmux before using features
4. **Use panes for visibility** - things user should see during work
5. **Use windows for background** - servers, watchers stay out of way
6. **Queue important follow-ups** - self-continuation ensures nothing is forgotten
