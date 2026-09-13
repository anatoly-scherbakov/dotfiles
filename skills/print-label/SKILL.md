---
name: print-label
description: Render and USB-print a custom NIIMBOT B1 label, always showing the exact preview and requiring explicit approval before the physical print.
disable-model-invocation: true
---

# Print label

Use this user-invoked skill to make a physical label for the local NIIMBOT B1.

## Printer profile

- Confirm the printer is present as USB ID `3513:0002` before doing work.
- Use `/dev/ttyACM0`, never serial auto-detection: `/dev/ttyUSB0` is the user's dosimeter.
- The B1 is model ID 4096 with a 384-pixel effective print head at 203 dpi. Do not use a nominal 400-pixel canvas for a 50 mm roll; it would clip.
- The usual roll is a 50 × 30 mm white die-cut roll. Its print canvas is 384 × 240 px. Read the current roll state at the beginning of a session; do not assume that a later roll has the same dimensions.
- Print with `~/.local/bin/niimbot-print`. If it is absent or the B1 cannot be verified, stop and explain what is missing rather than substituting another serial device.

## Workflow

1. Determine the requested text, icon, and label profile. If the loaded roll size cannot be verified, ask the user to confirm or measure it before preparing a print.
2. Render the label to a deterministic, monochrome PNG at the selected profile's exact pixel dimensions. For text and simple icons, prefer SVG or another vector source; when reusing an icon, record its source and license in the response. Do not use image generation for text or a simple pictogram.
3. Inspect the raster and show it inline as the preview. State that it has not printed.
4. Stop and wait for an explicit, current approval such as "print it." Any revision creates a new preview and requires new approval.
5. After approval, send exactly one copy at density 3 unless the user explicitly requests another quantity or density:

   ```sh
   ~/.local/bin/niimbot-print \
     -model b1 -addr /dev/ttyACM0 -density 3 -image <approved-preview.png>
   ```

6. Report completion only after the command succeeds. Ask the user to inspect the physical label for placement and legibility; do not infer that from the command acknowledgement.

## Safety boundary

- Never print during preview creation or because a user asked to make a label; printing requires explicit approval of that exact preview.
- Never reprint after an error or ambiguous result without asking.
- Keep preview artifacts in `/tmp` unless the user asks to retain or archive them.
