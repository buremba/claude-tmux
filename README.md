# claude-tmux

A Claude Code plugin that makes Claude aware of its tmux environment, enabling parallel agents, background services, and self-continuation across sessions.

## Installation

```
/plugins install buremba/claude-tmux
```

Or clone manually:
```bash
git clone https://github.com/buremba/claude-tmux ~/.claude/plugins/claude-tmux
```

## How It Works

When you run Claude Code inside tmux, Claude automatically detects it and can:
- Run tasks in background windows (servers, tests, long-running processes)
- Spawn parallel agents in visible panes (side-by-side work)
- Monitor output without switching windows
- Queue messages for the next session (self-continuation)
- Record interactions as asciinema files

Just ask Claude what you need—it handles the tmux details automatically.

## Use Cases

### Run a Dev Server in Background + Show Logs

```
Start the dev server in a background window and show me the logs in a visible pane.
Wait until it's ready on port 3000.
```

Claude will create a background window for the server, a visible pane for logs, and monitor for readiness.

### Fix Multiple Bugs in Parallel

```
Fix these 3 bugs in parallel using separate Claude agents:
1. Authentication timeout in login.py
2. 500 error in /api/users endpoint
3. Button alignment in header component

Run each in a separate background window and report when all are complete.
```

Claude will spawn 3 agents in background windows and monitor completion.

### Run Tests + Remind Next Session

```
Run the full test suite in the background.
When it's done, queue a message telling me if we should deploy to staging.
```

Claude will spawn tests in a background window and queue a reminder for the next session.

### Record a Demo

```
/record -p "Demonstrate spawning a parallel pane to review code" -o demo.cast
```

Records your interaction as an asciinema file. Playback with `asciinema play demo.cast` or upload to asciinema.org.

## Recording Options

```
/record -p "Your prompt" [OPTIONS]
  -w, --width WIDTH          Terminal width (default: 120)
  -h, --height HEIGHT        Terminal height (default: 35)
  -o, --output FILE.cast     Output file path
  -t, --timeout SECONDS      Timeout in seconds (default: 120)
```

## Requirements

- **tmux** (v3.0+)
- **Claude CLI** installed
- **bash**, **jq** (for scripts)
- **asciinema** (optional, for `/record` skill)

Install:
```bash
# macOS
brew install tmux jq asciinema

# Linux
sudo apt-get install tmux jq asciinema
```

## Troubleshooting

**Claude doesn't use tmux features**
- Make sure you're in a tmux session: `echo $TMUX`
- Check plugin installed: `ls ~/.claude/plugins/claude-tmux`
- Be explicit: "Run this in a background tmux window"

**Recording fails**
- Install asciinema: `brew install asciinema`
- Check jq: `jq --version`
- Create recordings dir: `mkdir -p ~/.claude/plugins/claude-tmux/skills/record/recordings`

**TMUX_ENVIRONMENT_DETECTED not showing**
- Start Claude Code from inside a tmux session
- Not working? Check plugin loaded in settings

## Skills Reference

- **[Tmux Awareness](skills/tmux-awareness/SKILL.md)** - Background work, parallel agents, monitoring
- **[Record](skills/record/SKILL.md)** - Create asciinema recordings

## License

MIT
