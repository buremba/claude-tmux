# Generating Demo Cast Files

This guide explains how to generate asciinema `.cast` files for each use case in the claude-tmux plugin.

## Quick Start

### Option 1: Interactive Demo Generator (Recommended)

Run the batch generator script to create demos interactively:

```bash
./generate-demos.sh
```

This will show a menu where you can select which demos to generate:

```
Select demos to generate:

  1) All demos
  2) Detect tmux session
  3) Spawn visible pane
  4) Spawn background window
  5) Wait for pattern (server ready)
  6) Capture output from pane
  7) Queue message for next session
  8) Combined workflow (pane + window)

  q) Quit
```

### Option 2: Generate Specific Demo from CLI

Record a single demo directly:

```bash
./skills/record/skill.sh \
  -p "Use detect-session.sh to show current tmux context" \
  -o ./skills/record/recordings/demo-detect-session.cast
```

### Option 3: Use from Claude Code

When running Claude Code in tmux:

```
/record -p "Demonstrate spawning a parallel pane with spawn-pane.sh" -o demo-pane.cast
```

## What Each Demo Shows

### demo-detect-session.cast
**Use Case:** Session Detection

Shows how to check current tmux context using `detect-session.sh`. Demonstrates:
- Running the detection script
- Viewing JSON output with session, window, pane info
- Understanding your tmux environment

**Prompt:** "Use the detect-session.sh script to check if we're in tmux and get session info"

### demo-spawn-pane.cast
**Use Case:** Parallel Visible Work

Demonstrates spawning a visible split pane for side-by-side work:
- Creating a horizontal or vertical split
- Running a command in the new pane
- User can see output in real-time

**Prompt:** "Spawn a visible split pane using spawn-pane.sh with a command like 'echo Hello from parallel pane'"

### demo-spawn-window.cast
**Use Case:** Background Services

Shows creating a background window for servers/watchers:
- Creating a new tmux window
- Starting a dev server or long-running process
- Window stays out of the way

**Prompt:** "Create a background window using spawn-window.sh named 'demo-server' with 'python3 -m http.server 8765'"

### demo-wait-for-text.cast
**Use Case:** Waiting for Conditions

Demonstrates waiting for a specific pattern in pane output:
- Starting a server in background
- Using `wait-for-text.sh` to detect when it's ready
- Useful for orchestrating dependent tasks

**Prompt:** "Start a simple server in background and use wait-for-text.sh to wait for the 'Serving HTTP' message with a 30 second timeout"

### demo-capture-output.cast
**Use Case:** Monitoring Output

Shows how to capture output from a pane:
- Getting recent lines from a pane
- JSON output with metadata
- Useful for checking status without switching windows

**Prompt:** "Use capture-output.sh to capture the last 20 lines from a pane and display them with JSON formatting"

### demo-queue-message.cast
**Use Case:** Self-Continuation

Demonstrates queuing messages for the next Claude session:
- Creating a reminder
- Message stored in `~/.claude/tmux-messages/`
- Delivered on next Claude session start

**Prompt:** "Use queue-message.sh to queue a message like 'Remember to review the PR when you start the next session'"

### demo-combined-workflow.cast
**Use Case:** Full Workflow

Shows a complete workflow combining multiple features:
- Spawn background window with dev server
- Spawn visible pane to show logs
- Wait for server to be ready
- Queue follow-up message

**Prompt:** "Demonstrate a complete workflow: spawn a background window with a dev server, spawn a visible pane to show logs, wait for server ready, and queue a follow-up message"

## Embedding Cast Files in HTML

### Using asciinema.org Player

The easiest way to embed cast files in your documentation:

```html
<asciinema-player src="path/to/demo-detect-session.cast"></asciinema-player>
<script src="https://js.asciinema.org/asciinema-player.min.js"></script>
```

### Upload to asciinema.org

Make cast files shareable:

```bash
asciinema upload skills/record/recordings/demo-detect-session.cast
```

You'll get a shareable link like: `https://asciinema.org/a/123456`

### HTML Demo Page Template

Create an `DEMOS.html` file to showcase all demos:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Claude Tmux Plugin - Demos</title>
    <link rel="stylesheet" type="text/css" href="https://js.asciinema.org/asciinema-player.css" />
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .demo-section {
            background: white;
            margin: 20px 0;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .demo-section h2 {
            margin-top: 0;
            color: #333;
        }
        .demo-section p {
            color: #666;
            line-height: 1.6;
        }
        asciinema-player {
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Claude Tmux Plugin - Interactive Demos</h1>

    <div class="demo-section">
        <h2>1. Detect Tmux Session</h2>
        <p>Check your current tmux environment and get session information.</p>
        <asciinema-player src="skills/record/recordings/demo-detect-session.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <div class="demo-section">
        <h2>2. Spawn Visible Pane</h2>
        <p>Create a split pane for parallel work the user can see.</p>
        <asciinema-player src="skills/record/recordings/demo-spawn-pane.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <div class="demo-section">
        <h2>3. Spawn Background Window</h2>
        <p>Start a background server in a separate window.</p>
        <asciinema-player src="skills/record/recordings/demo-spawn-window.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <div class="demo-section">
        <h2>4. Wait for Pattern</h2>
        <p>Wait for a server to be ready or a process to complete.</p>
        <asciinema-player src="skills/record/recordings/demo-wait-for-text.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <div class="demo-section">
        <h2>5. Capture Output</h2>
        <p>Capture and display output from any pane.</p>
        <asciinema-player src="skills/record/recordings/demo-capture-output.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <div class="demo-section">
        <h2>6. Queue Message</h2>
        <p>Queue reminders for your next Claude session.</p>
        <asciinema-player src="skills/record/recordings/demo-queue-message.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <div class="demo-section">
        <h2>7. Combined Workflow</h2>
        <p>A complete workflow combining multiple tmux features.</p>
        <asciinema-player src="skills/record/recordings/demo-combined-workflow.cast"
                          autoplay="false"
                          loop="false"
                          speed="1"
                          preload="true">
        </asciinema-player>
    </div>

    <script src="https://js.asciinema.org/asciinema-player.min.js"></script>
</body>
</html>
```

## Manual Recording Steps

If you prefer to record manually from Claude Code:

1. **Start Claude Code in tmux:**
   ```bash
   tmux new-session -s claude
   claude
   ```

2. **When you see `TMUX_ENVIRONMENT_DETECTED`, ask Claude:**
   ```
   /record -p "Use detect-session.sh to show current tmux context" \
           -o ./skills/record/recordings/demo-detect-session.cast
   ```

3. **Wait for recording to complete** - you'll see the cast file saved

4. **Repeat for each use case**

## Dependencies

The record skill requires:
- `tmux` (v3.0+)
- `asciinema` (v3.0+)
- `claude` CLI
- `jq` for JSON processing

Install:
```bash
# macOS
brew install tmux asciinema jq

# Linux (Ubuntu/Debian)
sudo apt-get install tmux asciinema jq

# Python
pip install asciinema
```

## File Locations

- **Generated cast files:** `skills/record/recordings/demo-*.cast`
- **Generator script:** `./generate-demos.sh`
- **HTML page template:** Create `./DEMOS.html` (see above)
- **Messages queued during recording:** `~/.claude/tmux-messages/` (temporary)

## Playback

### Watch locally:
```bash
asciinema play skills/record/recordings/demo-detect-session.cast
```

### Upload to asciinema.org:
```bash
asciinema upload skills/record/recordings/demo-detect-session.cast
```

### Embed in GitHub README:

Add to your README.md:
```markdown
## Demos

### Detect Tmux Session
[![Detect Session](https://asciinema.org/a/YOUR-ID-FROM-UPLOAD.svg)](https://asciinema.org/a/YOUR-ID-FROM-UPLOAD)
```

## Tips

1. **First run takes longest** - Claude needs to initialize
2. **Keep prompts focused** - shorter prompts = quicker recording
3. **Use descriptive names** - makes it easy to find demos later
4. **Generate in order** - some demos depend on previous setup
5. **Test dimensions** - default 120x35 works for most displays

## Next Steps

After generating cast files:

1. Generate all 7 demos: `./generate-demos.sh` → select option 1
2. Review recordings: `ls -lh skills/record/recordings/`
3. Test one: `asciinema play skills/record/recordings/demo-detect-session.cast`
4. Create `DEMOS.html` using the template above
5. Upload to asciinema.org for shareable links
6. Update GitHub README with demo links
