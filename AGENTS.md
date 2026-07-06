# dotfiles guidance

## Symlinks

- Manage all symlinks (including skills) via `install.conf.yaml` and apply with `./install` (dotbot) — never use manual `ln -s`.
- A new skill needs **three** entries in `install.conf.yaml`, one each for `~/.cursor/skills/<name>`, `~/.claude/skills/<name>`, `~/.codex/skills/<name>`, all pointing to `skills/<name>` with `relink: true`, `create: true`, `force: true`.
- Every repo-defined skill under `skills/` must be available to Cursor,
  Claude, and Codex. When changing skill links, audit all `skills/*`
  directories against `~/.cursor/skills/<name>`, `~/.claude/skills/<name>`,
  and `~/.codex/skills/<name>` entries in `install.conf.yaml`.

## Subdirectory guidance

- [agents/AGENTS.md](agents/AGENTS.md) - global agent guidance source linked into Codex
- [nanopublishing/AGENTS.md](nanopublishing/AGENTS.md) - nanopublishing project guidance
