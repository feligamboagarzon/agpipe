# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## MarkItDown Integration (Document Conversion)

RTK is integrated with Microsoft's `markitdown` library to convert non-text files into Markdown automatically. This minimizes LLM token usage dramatically when reading or uploading documents.

Supported extensions: `.pdf`, `.docx`, `.pptx`, `.xlsx`, `.xls`, `.html`, `.png`, `.jpg`, `.jpeg`, `.mp3`, `.wav`.

When you read a file using `rtk read` or a hook-rewritten `cat` command, if the file is one of the supported formats above, RTK will convert it to Markdown dynamically:
```bash
rtk read invoice.pdf   # Automatically converts PDF to Markdown on standard output
cat slide.pptx         # Hook rewrites to 'rtk read slide.pptx' -> outputs Markdown
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

Refer to CLAUDE.md for full command reference.
