# dotfiles guidance

## Public repository

- This repository is public. Never write an employer's, client's or customer's
  name, or their internal repository names, ticket IDs or URLs, anywhere in it.
  Company-specific guidance belongs in that company's repository `AGENTS.md`.

## Symlinks

- Manage all symlinks (including skills) via `install.conf.yaml` and apply with `./install` (dotbot) — never use manual `ln -s`.
- A new skill needs **four** entries in `install.conf.yaml`, one each for `~/.cursor/skills/<name>`, `~/.claude/skills/<name>`, `~/.codex/skills/<name>`, `~/.gemini/config/skills/<name>`, all pointing to `skills/<name>` with `relink: true`, `create: true`, `force: true`.
- Every repo-defined skill under `skills/` must be available to Cursor,
  Claude, Codex, and Antigravity. When changing skill links, audit all `skills/*`
  directories against `~/.cursor/skills/<name>`, `~/.claude/skills/<name>`,
  `~/.codex/skills/<name>`, and `~/.gemini/config/skills/<name>` entries in `install.conf.yaml`.
  Exception: `spawn-claude` and `close-idle-sessions` are Claude-only (they launch
  `claude` / drive Claude sessions); link them only to `~/.claude/skills/`.

## Skill discovery

- Omit `disable-model-invocation` from every skill's frontmatter. Setting it
  to `true` hides the skill from OpenCode's model-visible available-skills list,
  blocking normal skill discovery and usage even when the skill is installed
  correctly. Explicit loading by ID still works, but the model cannot normally
  discover the skill. Claude Code also hides flagged skills from the model.
- Do not add this flag to enable Cursor slash commands; keep skills discoverable
  across harnesses. After adding or changing skills, reload the Cursor window
  so it rescans `~/.cursor/skills/`.

## Subdirectory guidance

- [agents/AGENTS.md](agents/AGENTS.md) - global agent guidance source linked into Codex
- [nanopublishing/AGENTS.md](nanopublishing/AGENTS.md) - nanopublishing project guidance
