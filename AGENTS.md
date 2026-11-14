# dotfiles guidance

## Public repository

- This repository is public. Never write an employer's, client's or customer's
  name, or their internal repository names, ticket IDs or URLs, anywhere in it.
  Company-specific guidance belongs in that company's repository `AGENTS.md`.

## Symlinks

- Manage all symlinks (including skills) via `install.conf.yaml` and apply with `./install` (dotbot) — never use manual `ln -s`.
- A new skill needs entries in `install.conf.yaml` for `~/.claude/skills/<name>`,
  `~/.codex/skills/<name>`, and `~/.gemini/config/skills/<name>`, all pointing
  to the skill directory with `relink: true`, `create: true`, and `force: true`.
- Every repo-defined skill under `skills/` must be available to Claude, Codex,
  and Gemini CLI. Audit these links when adding or changing skills.
  Exception: `spawn-claude` is Claude-only (it launches `claude`); link it only
  to `~/.claude/skills/`.

## Skill discovery

- Omit `disable-model-invocation` from every skill's frontmatter. Setting it
  to `true` hides the skill from OpenCode's model-visible available-skills list,
  blocking normal skill discovery and usage even when the skill is installed
  correctly. Explicit loading by ID still works, but the model cannot normally
  discover the skill. Claude Code also hides flagged skills from the model.
- Keep skills discoverable across supported harnesses.

## Subdirectory guidance

- [agents/AGENTS.md](agents/AGENTS.md) - global agent guidance source linked into Codex
- [nanopublishing/AGENTS.md](nanopublishing/AGENTS.md) - nanopublishing project guidance
