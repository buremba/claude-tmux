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

### From Claude Plugin Marketplace

In Claude Code, install directly from the marketplace:

```
/plugins install buremba/claude-tmux
```

Or search in the plugin marketplace for `claude-tmux` by `buremba`.

The plugin loads automatically. On your next Claude session in tmux, you'll see `TMUX_ENVIRONMENT_DETECTED` in your context.

### Manual Installation (Alternative)

If you prefer to manage plugins manually:

```bash
git clone https://github.com/buremba/claude-tmux ~/.claude/plugins/claude-tmux
```

## Recording Demos

Record asciinema demonstrations of Claude using the plugin:

**From Claude Code in tmux:**
```
/record -p "Your prompt here" -o output.cast
```

**Example:**
```
/record -p "Demonstrate spawning a parallel pane with spawn-pane.sh" -o demo.cast
```

Cast files save to `~/.claude/plugins/claude-tmux/skills/record/recordings/` and can be:
- **Played locally:** `asciinema play demo.cast`
- **Uploaded to asciinema.org:** `asciinema upload demo.cast`
- **Embedded in HTML:** `<asciinema-player src="demo.cast"></asciinema-player>`

**Recording options:**
```
/record -p "PROMPT" [OPTIONS]
  -w, --width WIDTH          Terminal width (default: 120)
  -h, --height HEIGHT        Terminal height (default: 35)
  -o, --output FILE.cast     Output file path
  -t, --timeout SECONDS      Response timeout (default: 120)
```

## How It Works

When you're in Claude Code **inside a tmux session**, Claude automatically detects the environment and gains these capabilities:

### What Claude Can Do

Simply ask Claude what you need, and it will automatically use tmux:

**Parallel agents:**
```
Run Claude in a visible split pane to review this PR
```
Claude will spawn itself in a side-by-side pane.

**Background servers:**
```
Start a dev server in the background and wait for it to be ready
```
Claude will create a separate window, start the server, and monitor it.

**Long-running tasks:**
```
Run the tests in the background and queue a message when they're done
```
Claude will spawn the tests in a background window and queue a reminder for the next session.

**Monitoring:**
```
Check the logs from the background server
```
Claude will capture and display output without switching windows.

### The Tmux Awareness Context

When Claude starts in tmux, it sees:
```
TMUX_ENVIRONMENT_DETECTED: You are running inside tmux!

Session: my-session | Window: 0 | Pane: 0
Current window has 1 pane(s), session has 2 window(s)

**Tmux Capabilities Available:**
- Create visible panes (split current window) for parallel work
- Create background windows for servers, watchers, long-running processes
- Spawn parallel Claude agents in separate panes/windows
- Monitor output from any pane/window
- Queue messages for self-continuation in next session
```

Claude **will automatically use these capabilities** for background processes, parallel work, and server management.

### Recording Demos

Record how Claude uses the plugin:

```
/record -p "Demonstrate spawning a parallel pane to review a PR" -o review-demo.cast
```

Claude will execute the prompt and record the entire interaction as an asciinema file.

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

Ask Claude to fix multiple bugs in parallel:

```
Fix these 3 bugs in parallel using separate Claude agents:
1. Authentication timeout in login.py
2. 500 error in /api/users endpoint
3. Button alignment in header component

Run each in a separate background window and report when all are complete.
```

Claude will automatically spawn 3 agents in background windows and monitor their completion.

### Dev Server with Live Logs

```
Start the dev server in the background and show the logs in a visible pane.
Wait until it's ready and then let me know.
```

Claude will create a background window for the server, a visible pane for logs, monitor for readiness, and confirm when it's running.

### Self-Continuation

```
Run the full test suite in the background. When it's done, queue a message
telling me if I should deploy to staging.
```

Claude will spawn tests in a background window, queue a message for the next session with the results.

### Documentation Workflow

```
Start the docs server in the background. Then create a recording showing
the new dashboard component in action.
```

Claude will:
1. Start the docs server in a background window
2. Record an asciinema demo of the new component
3. Save the .cast file for you to upload or share

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

## Advanced Tmux Control

For direct tmux control (if needed), Claude can use raw tmux commands:

### Listing Sessions and Windows

```
List all my tmux windows and panes
```

### Managing Windows

```
Kill the 'server' background window
```

### Monitoring Output

```
Show me the last 50 lines from the background server output
```

Claude will automatically use the tmux-awareness scripts to accomplish these tasks, but you can always ask for specific tmux operations if needed.

## Troubleshooting

### Tmux features not detected

**Problem:** You don't see "TMUX_ENVIRONMENT_DETECTED" at session start.

**Solution:**
1. Verify you're in tmux: `echo $TMUX`
2. Check plugin is installed: `ls ~/.claude/plugins/claude-tmux`
3. Verify plugin loads: `grep claude-tmux ~/.claude/settings.json`

### Recording fails

**Problem:** `/record` command not found or recording doesn't save.

**Solution:**
1. Check asciinema is installed: `asciinema --version`
2. Check jq is installed: `jq --version`
3. Check recordings directory exists: `mkdir -p ~/.claude/plugins/claude-tmux/skills/record/recordings`
4. Try custom output: `/record -p "test" -o /tmp/test.cast`

### Claude doesn't use tmux features

**Problem:** You ask Claude to run something in background, but it runs in foreground instead.

**Solution:**
1. Be explicit: "Run this in a background tmux window"
2. Describe what you want: "I need to see logs in a visible pane while the server runs"
3. Check you're in tmux: `echo $TMUX`
4. Verify plugin loaded: Check for `TMUX_ENVIRONMENT_DETECTED` in your session context

### Claude agents timeout or hang

**Problem:** Parallel Claude agents in background windows don't respond.

**Solution:**
1. Ask Claude to increase the timeout: "Give the agents 5 minutes to complete"
2. Check the logs: "Show me what's happening in the background window"
3. Verify Claude CLI works: `claude --version`
4. Check network connection and Claude API availability

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
