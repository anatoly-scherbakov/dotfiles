# dotfiles guidance

## Symlinks

- Manage all symlinks (including skills) via `install.conf.yaml` and apply with `./install` (dotbot) — never use manual `ln -s`.
- A new skill needs **three** entries in `install.conf.yaml`, one each for `~/.cursor/skills/<name>`, `~/.claude/skills/<name>`, `~/.codex/skills/<name>`, all pointing to `skills/<name>` with `relink: true`, `create: true`, `force: true`.
