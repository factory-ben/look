---
name: look
description: Capture any app window without switching focus. Use when user asks to "look at [app]", "what's on my [app]", "read my [screen/window]", or needs to see content from Chrome, Slack, Superhuman, Granola, Notes, etc. Works even when windows are obscured or behind others.
---

# look

Capture window content without changing focus.

## Build

```bash
swiftc -O -parse-as-library look.swift -o look
```

## Usage

```bash
./look chrome        # OCR text from Chrome
./look slack         # fuzzy match app name
./look list          # show all windows
./look --json        # JSON output
./look               # frontmost window
```

## Output

- **TTY**: OCR text to stdout
- **Piped**: JSON `{app, title, image, text}`
