---
name: control-loop
description: Create, review or run an agentic feedback loop described by a CONTROL-LOOP.md file, whose YAML-LD frontmatter is the loop's source of truth in control-theory terms (goal, set point, sensor, check, controller, actuator, work-in-progress limit, disturbance, supervisor). Use for "/control-loop create <directory>", "/control-loop review <file>", "/control-loop do <file>", or when asked to describe, audit or run a loop.
---

# Control loop

A `CONTROL-LOOP.md` describes one loop: what it holds true, how it measures that, and
what it does about a gap. This skill writes such a file, reviews it, and runs it.

## Prerequisite: `sparqld` 0.1.7

Create, review, and the `C18` check need [`sparqld`](https://crates.io/crates/sparqld)
**0.1.7** or newer (context registration via `jsonld:Context` and
`schema:contentUrl`). Before those steps:

1. Run `sparqld --version`.
2. If `sparqld` is missing or older than 0.1.7, propose installing or upgrading
   with `cargo install sparqld` (add `--force` when an older binary is already
   on `PATH`). If `cargo` is missing, propose installing Rust and Cargo with
   Rustup first. Recheck `sparqld --version` after install.
3. Do not run the check until 0.1.7 or newer is available. If the user declines,
   stop and report that the check could not run.

## Modes

The first argument picks the mode; the second is a directory (`create`) or a
`CONTROL-LOOP.md` path. Read the mode's file and follow it.

| Mode | Does | File |
|---|---|---|
| `create <directory>` | Writes a new `CONTROL-LOOP.md` from the loop's live definitions | [create.md](create.md) |
| `review <file>` | Reports the file's breaches of the rules, its drift from the live definitions, and gaps in the loop's design | [review.md](review.md) |
| `do <file>` | Runs the loop from this session: schedules itself, and each cycle a fresh agent senses, compares, records and returns the jobs to start | [do.md](do.md) |

## Shared resources

- [rules.md](rules.md): the rules `C01`–`C18` for a correct file. `create` writes by
  them and `review` checks against them.
- [vocabulary.yamlld](vocabulary.yamlld): the terms, their labels and comments, and
  their links to Wikidata and SOSA (`urn:control-loop:vocab/`).
- [contexts/](contexts/): the files a project copies beside its `CONTROL-LOOP.md`.
  `control-loop.jsonld` is the self-registering context `urn:control-loop:context`
  (`jsonld:Context` + `schema:contentUrl`); sparqld resolves that URI from the
  local file and does not fetch it.
- [template.md](template.md): the starting point for `create`.
- [state-template.md](state-template.md): the shape of `loop-state.md`, which `do`
  writes beside the loop file (gitignored).
- [check.rq](check.rq): the check (`C18`).
