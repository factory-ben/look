# look

Capture any window's content without switching focus. Let your AI see what you're looking at.

![look demo](media/demo.png)

## Install

```bash
# Clone and build
git clone https://github.com/factory-ben/look.git
cd look
swiftc -O -parse-as-library look.swift -o look

# Add to path
cp look /usr/local/bin/
```

## Usage

```bash
look chrome         # OCR text from Chrome window
look slack          # fuzzy match app name
look list           # show all windows
look --json         # JSON output (default when piped)
look                # frontmost window
```

## Output

**Terminal:**
```
Here's what an AI agent searches for when it's coding...
Documentation • Learning • API Reference • Debugging
```

**Piped/JSON:**
```json
{
  "app": "Google Chrome",
  "title": "Posts / X",
  "image": "/tmp/look-google-chrome.png",
  "text": "Here's what an AI agent searches for..."
}
```

## How it works

1. Finds window by app name using `CGWindowListCopyWindowInfo`
2. Captures isolated window with `screencapture -l` (works even if obscured)
3. Extracts text with macOS Vision OCR

## Requirements

- macOS 12+
- Screen Recording permission (System Settings → Privacy)

## License

MIT
