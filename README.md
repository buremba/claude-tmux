# claude-tmux

A Claude Code plugin that makes Claude aware of its tmux environment, enabling parallel agents, background services, and self-continuation across sessions.

## Features

### 🔄 Tmux Awareness Skill
Automatically detect when Claude runs inside tmux and unlock powerful capabilities:

- **Spawn parallel Claude agents** in visible panes for side-by-side work
- **Create background windows** for dev servers, file watchers, and long-running processes
- **Monitor output** from parallel work with capture and wait-for-text utilities
- **Queue messages** for the next Claude session (self-continuation)
- **Direct tmux control** for advanced window/pane management

### 🎥 Record Skill
Record asciinema demonstrations of Claude executing prompts:

- Create demos of Claude using tmux features
- Generate documentation with real Claude interactions
- Share recordings on asciinema.org
- Build tutorials showing actual behavior
- Custom terminal dimensions for different platforms

## Installation

### For Claude Code Users

1. Clone or download this repository to a location of your choice:
   ```bash
   git clone https://github.com/anthropics/claude-tmux ~/.claude/plugins/claude-tmux
   ```

2. The plugin loads automatically. On your next Claude session in tmux, you'll see `TMUX_ENVIRONMENT_DETECTED` in your context.

### Manual Installation

If you prefer to manage plugins manually:

```bash
mkdir -p ~/.claude/plugins
cp -r claude-tmux ~/.claude/plugins/
```

## Quick Start

### Using Tmux Awareness

When Claude detects tmux, you can use these capabilities:

**Spawn a parallel Claude agent in a visible pane:**
```bash
~/.claude/plugins/claude-tmux/skills/tmux-awareness/scripts/spawn-pane.sh \
  -d h -c "claude --print 'Review this PR and suggest improvements'"
```

**Create a background window for a dev server:**
```bash
~/.claude/plugins/claude-tmux/skills/tmux-awareness/scripts/spawn-window.sh \
  -n "server" -c "npm run dev"
```

**Queue a message for the next session:**
```bash
~/.claude/plugins/claude-tmux/skills/tmux-awareness/scripts/queue-message.sh \
  "Check if the server passed all tests before deploying"
```

**Check current session info:**
```bash
~/.claude/plugins/claude-tmux/skills/tmux-awareness/scripts/detect-session.sh
```

### Using Record Skill

Record Claude executing a prompt:

```bash
/record -p "Demonstrate spawning a parallel pane with tmux"
```

With custom options:
```bash
/record -p "Show dev server setup" -w 120 -h 35 -o my-demo.cast
```

Record will save to `~/.claude/plugins/claude-tmux/skills/record/recordings/`

## Skills Overview

### Tmux Awareness (`tmux-awareness`)

**Auto-enabled:** When Claude runs in tmux, the SessionStart hook automatically detects this and injects capabilities.

**Available scripts:**
- `detect-session.sh` - Get current tmux context (JSON)
- `spawn-pane.sh` - Create visible split pane
- `spawn-window.sh` - Create background window
- `wait-for-text.sh` - Wait for pattern in pane output
- `capture-output.sh` - Capture recent pane contents
- `queue-message.sh` - Queue message for next session

**Learn more:** See [skills/tmux-awareness/SKILL.md](skills/tmux-awareness/SKILL.md)

### Record (`record`)

**Trigger:** Use `/record` command or ask Claude to record a demo.

**Usage:**
```bash
/record -p "PROMPT" [OPTIONS]
```

**Options:**
- `-w, --width` - Terminal width (default: 120)
- `-h, --height` - Terminal height (default: 35)
- `-o, --output` - Output file path
- `-t, --timeout` - Response timeout in seconds (default: 120)
- `-i, --idle-time` - Compression idle time (default: 2)

**Learn more:** See [skills/record/SKILL.md](skills/record/SKILL.md)

## Architecture

```
claude-tmux/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── skills/
│   ├── tmux-awareness/          # Parallel execution and monitoring
│   │   ├── SKILL.md             # Documentation
│   │   └── scripts/             # Implementation
│   │       ├── detect-session.sh
│   │       ├── spawn-pane.sh
│   │       ├── spawn-window.sh
│   │       ├── wait-for-text.sh
│   │       ├── capture-output.sh
│   │       └── queue-message.sh
│   └── record/                  # Recording demonstrations
│       ├── SKILL.md             # Documentation
│       ├── skill.sh             # /record command entry point
│       ├── scripts/             # Implementation
│       │   ├── record.sh
│       │   ├── common.sh
│       │   ├── claude-control.sh
│       │   └── validate-deps.sh
│       └── recordings/          # Output directory for .cast files
└── README.md                    # This file
```

## Use Cases

### Parallel Bug Fixes

Spawn multiple Claude agents to fix different bugs simultaneously:

```bash
spawn-window.sh -n "bug-auth" -c "claude --print 'Fix authentication timeout'"
spawn-window.sh -n "bug-api" -c "claude --print 'Fix 500 error in /api'"
spawn-window.sh -n "bug-ui" -c "claude --print 'Fix button alignment'"

# Monitor completion
for win in bug-auth bug-api bug-ui; do
  wait-for-text.sh -t "$win:0.0" -p '^\$' -T 600
done
```

### Dev Server with Live Logs

```bash
# Start server in background
spawn-window.sh -n "server" -c "npm run dev"

# Show logs in visible pane
spawn-pane.sh -d v -p 30 -c "tail -f logs/app.log"

# Wait for ready
wait-for-text.sh -t "server:0.0" -p "listening on" -T 30
```

### Self-Continuation

```bash
# Long-running task in background
spawn-window.sh -n "build" -c "npm run build && npm test"

# Queue reminder for next session
queue-message.sh "Check build results in 'build' window. Deploy if successful."
```

### Documentation Workflow

```bash
# Start server
spawn-window.sh -n "docs-server" -c "npm run docs:serve"

# Record demo
/record -p "Show the new dashboard component in the docs"

# Share the recording
asciinema upload ~/.claude/plugins/claude-tmux/skills/record/recordings/recording-*.cast
```

## Requirements

### Core Requirements
- **tmux** - Terminal multiplexer (v3.0+)
- **Claude CLI** - `claude` command available in PATH
- **bash** - For script execution
- **jq** - JSON processing (for record skill)

### For Recording
- **asciinema** - Terminal recording (v3.0+)
- **npm** or **pip** - To install asciinema

Install dependencies:

```bash
# macOS
brew install tmux asciinema jq

# Linux (Ubuntu/Debian)
sudo apt-get install tmux asciinema jq

# asciinema via pip
pip install asciinema
```

## Common Patterns

### Waiting for Conditions

```bash
# Wait for server to start (30s timeout)
wait-for-text.sh -t "server:0.0" -p "ready on port" -T 30

# Wait for process to complete (shell prompt)
wait-for-text.sh -t "build:0.0" -p '^\$' -T 600

# Wait for exact string (fixed match)
wait-for-text.sh -t "process:0.0" -p "DONE" -F
```

### Capturing Output

```bash
# Get last 100 lines
capture-output.sh -t "server:0.0" -l 100

# Get JSON output with metadata
capture-output.sh -t "agent:0.0" -l 50 --json
```

### Managing Sessions

```bash
# List all windows
tmux list-windows -F '#{window_index}: #{window_name}'

# List all panes
tmux list-panes -a

# Kill a window
tmux kill-window -t "server"

# Kill a pane
tmux kill-pane -t "main:0.1"
```

## Troubleshooting

### Tmux features not detected

**Problem:** You don't see "TMUX_ENVIRONMENT_DETECTED" at session start.

**Solution:**
1. Verify you're in tmux: `echo $TMUX`
2. Check plugin is installed: `ls ~/.claude/plugins/claude-tmux`
3. Verify plugin loads: `grep claude-tmux ~/.claude/settings.json`

### Scripts not found

**Problem:** "command not found" for detect-session.sh, spawn-pane.sh, etc.

**Solution:**
1. Check plugin path: `ls ~/.claude/plugins/claude-tmux/skills/*/scripts/`
2. Make scripts executable: `chmod +x ~/.claude/plugins/claude-tmux/skills/*/scripts/*.sh`
3. Use full path: `~/.claude/plugins/claude-tmux/skills/tmux-awareness/scripts/detect-session.sh`

### Recording fails

**Problem:** `/record` command not found or recording doesn't save.

**Solution:**
1. Check asciinema is installed: `asciinema --version`
2. Check jq is installed: `jq --version`
3. Check recordings directory: `mkdir -p ~/.claude/plugins/claude-tmux/skills/record/recordings`
4. Try custom output: `/record -p "test" -o /tmp/test.cast`

### Parallel agents timeout

**Problem:** Claude agents in background windows don't respond.

**Solution:**
1. Increase timeout: `wait-for-text.sh -t "window:0.0" -p '^\$' -T 300` (5 minutes)
2. Check agent output: `capture-output.sh -t "window:0.0" -l 20`
3. Verify claude CLI works: `claude --version`

## Documentation

- **[Tmux Awareness Skill](skills/tmux-awareness/SKILL.md)** - Complete reference for parallel execution
- **[Record Skill](skills/record/SKILL.md)** - Recording demonstrations guide

## Contributing

This is an official Claude Code plugin. To contribute:

1. Fork this repository
2. Make your improvements
3. Test thoroughly in your tmux environment
4. Submit a pull request with clear descriptions

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: Report bugs at https://github.com/anthropics/claude-code/issues
- **Feedback**: Share ideas and suggestions with the community
- **Documentation**: See skill SKILL.md files for detailed usage

## Changelog

### Version 1.0.0 (2026-01-12)

Initial release with:
- Tmux awareness auto-detection
- Parallel pane and window spawning
- Output monitoring and waiting utilities
- Self-continuation message queuing
- Recording skill for creating asciinema demonstrations

---

Made for [Claude Code](https://claude.com/claude-code) with ❤️ for tmux enthusiasts
