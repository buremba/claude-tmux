---
name: record
description: "Record asciinema demonstrations of Claude executing a prompt in tmux. Use this when the user asks to: record a demo, create a recording, capture Claude session, generate demo video, or record an example."
triggers:
  - "record"
  - "recording"
  - "asciinema"
  - "demo"
  - "capture session"
version: 1.0.0
---

# Record Skill - Claude Tmux Recording

Record Claude executing any prompt in a tmux session and save it as an asciinema `.cast` file.

## Overview

This skill records Claude interacting with prompts in tmux. Perfect for:

- **Creating demos** of Claude using tmux plugin features
- **Capturing workflows** with split panes and windows
- **Generating documentation** showing real Claude interactions
- **Sharing examples** with asciinema.org
- **Building tutorials** with actual Claude behavior

## Usage

### Basic Recording

```bash
/record -p "Your prompt here"
```

Records Claude executing the prompt with default dimensions (120×35).

Output: `~/.claude/plugins/claude-tmux/skills/record/recordings/recording-TIMESTAMP.cast`

### Custom Output Path

```bash
/record -p "Show all tmux panes" -o ~/my-demo.cast
```

Saves to custom location.

### Custom Dimensions

```bash
/record -p "Demonstrate split panes" -w 100 -h 30
```

Records with custom terminal size (100 columns × 30 rows).

### Longer Timeout

```bash
/record -p "Complex task" -t 180
```

Wait up to 180 seconds for Claude response (default: 120).

### All Options

```bash
/record -p "PROMPT" [OPTIONS]

Required:
  -p, --prompt TEXT          Prompt for Claude to execute

Optional:
  -w, --width WIDTH          Terminal width (default: 120)
  -h, --height HEIGHT        Terminal height (default: 35)
  -o, --output FILE.cast     Output file path
  -t, --timeout SECONDS      Response timeout (default: 120)
  -i, --idle-time SECONDS    Compression idle time (default: 2)
  --help                     Show help
```

## How It Works

1. **Creates isolated tmux session** with exact dimensions
2. **Starts Claude** with auto-initialization
3. **Records externally** using `asciinema rec -c "tmux attach"`
4. **Sends your prompt** to Claude
5. **Waits for response** completion (detects shell prompt return)
6. **Exits cleanly** without manual intervention
7. **Saves .cast file** with full terminal capture

## Examples

### Record Claude checking tmux status

```bash
/record -p "Use detect-session.sh to show current tmux context"
```

### Record Claude spawning a pane

```bash
/record -p "Spawn htop in a split pane using spawn-pane.sh"
```

### Record dev workflow

```bash
/record -p "Create a background window named 'server' with a Python HTTP server on port 8000"
```

### Record and immediately upload

```bash
/record -p "Show tmux panes" -o /tmp/demo.cast && \
  asciinema upload /tmp/demo.cast
```

### Multiple recordings

```bash
/record -p "Show detect-session.sh output" -o demo1.cast
/record -p "Show spawn-pane.sh with htop" -o demo2.cast
/record -p "Show spawn-window.sh with server" -o demo3.cast
```

## Playback and Sharing

### Watch Recording

```bash
asciinema play ~/.claude/plugins/claude-tmux/skills/record/recordings/recording-*.cast
```

### Upload to asciinema.org

```bash
asciinema upload ~/.claude/plugins/claude-tmux/skills/record/recordings/recording-*.cast
```

Creates a shareable link to your recording.

### Convert to GIF

Requires `agg`: `npm install -g agg`

```bash
agg recording.cast recording.gif
```

Perfect for embedding in docs.

## Architecture

### Recording Flow

```
1. Parse prompt and options
2. Create unique tmux session with exact dimensions
3. Start Claude in session
4. Start asciinema recording from OUTSIDE (captures full terminal)
5. Send prompt to Claude
6. Wait for Claude response (poll for shell prompt return)
7. Exit Claude and shell gracefully
8. asciinema recording stops automatically
9. Save .cast file
```

### Dimension Control

Terminal dimensions are set at two levels:

```bash
# Tmux session: exact size
tmux new-session -x WIDTH -y HEIGHT

# Asciinema recording: matching size
asciinema rec --window-size WIDTHxHEIGHT
```

Both must match for consistent playback.

### Claude Interaction

The skill detects when Claude finishes:

1. Send prompt via `tmux send-keys`
2. Poll pane content for shell prompt return
3. Shell prompt (`$`, `❯`, `#`, etc.) indicates completion
4. Even if Claude times out, gracefully exit and save recording

## Troubleshooting

### Recording shows wrong dimensions

- Ensure `-w` and `-h` match the dimensions you want
- Check terminal supports requested size: `stty size`
- Try standard size: `-w 80 -h 24`

### Claude doesn't respond

- Increase timeout: `-t 180` (waits 180 seconds)
- Check Claude CLI works: `claude --dangerously-skip-permissions -c "echo test"`
- Check internet connection

### Recording doesn't save

- Check output directory is writable: `ls -ld ~/.claude/plugins/claude-tmux/skills/record/recordings/`
- Try custom path: `-o /tmp/test.cast`

### Stuck tmux session

- List sessions: `tmux list-sessions`
- Kill stuck session: `tmux kill-session -t claude-record-*`

## Dependencies

Required (automatically checked):
- `tmux` - Terminal multiplexer
- `asciinema` - Terminal recording (v3.0+)
- `jq` - JSON processing
- `claude` - Claude CLI

## File Structure

```
~/.claude/plugins/claude-tmux/skills/record/
├── SKILL.md              # This documentation
├── skill.sh              # Entry point for /record
├── scripts/
│   ├── record.sh         # Main orchestrator
│   ├── common.sh         # Reusable utilities
│   ├── claude-control.sh # Claude management
│   └── validate-deps.sh  # Dependency validation
└── recordings/           # Output directory for .cast files
    ├── recording-20260111-143000.cast
    ├── recording-20260111-143030.cast
    └── ...
```

## Tips

1. **Keep prompts focused** - Shorter prompts = faster response = shorter recording
2. **Use specific commands** - Reference actual plugin scripts by path
3. **Test dimensions** - Verify output looks good at target size
4. **Cleanup recordings** - Remove old ones: `rm ~/.claude/plugins/claude-tmux/skills/record/recordings/*`
5. **Compress with idle time** - `-i 1` removes pauses shorter than 1 second

## Advanced Usage

### Batch record prompts

```bash
#!/bin/bash
prompts=(
  "Show current tmux session with detect-session.sh"
  "Create a split pane with spawn-pane.sh"
  "Start a background server with spawn-window.sh"
)

for i in "${!prompts[@]}"; do
  /record -p "${prompts[$i]}" -o "demo-$i.cast"
  sleep 2  # Brief pause between recordings
done
```

### Custom dimensions for platforms

```bash
# Twitter video (100×28)
/record -p "Your prompt" -w 100 -h 28 -o twitter-demo.cast

# YouTube (160×40)
/record -p "Your prompt" -w 160 -h 40 -o youtube-demo.cast

# Mobile (80×24)
/record -p "Your prompt" -w 80 -h 24 -o mobile-demo.cast
```

## Environment Variables

```bash
# Override default dimensions
export CLAUDE_TMUX_RECORD_WIDTH=100
export CLAUDE_TMUX_RECORD_HEIGHT=30

# Then record will use those defaults
/record -p "Your prompt"
```

## Feedback

- Found a bug? GitHub Issues: https://github.com/anthropics/claude-code/issues
- Have suggestions? Join the discussion with other users

---

**Skill Version**: 1.0.0
**Claude Tmux Plugin**: Requires tmux plugin installed
