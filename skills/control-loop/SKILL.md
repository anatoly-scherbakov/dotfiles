---
name: control-loop
description: Create, review or start an agentic feedback loop described by a CONTROL-LOOP.md file, whose YAML-LD frontmatter is the loop's source of truth in control-theory terms (goal, set point, sensor, check, controller, actuator, work-in-progress limit, disturbance, supervisor). Use for "/control-loop create <directory>", "/control-loop review <file>", "/control-loop start <file>", or when asked to describe, audit or run a loop.
---

# Control loop

A `CONTROL-LOOP.md` describes one loop: what it holds true, how it measures that, and
what it does about a gap. This skill writes such a file, reviews it, and runs it.

## Modes

The first argument picks the mode; the second is a directory (`create`) or a
`CONTROL-LOOP.md` path. Read the mode's file and follow it.

| Mode | Does | File |
|---|---|---|
| `create <directory>` | Writes a new `CONTROL-LOOP.md` from the loop's live definitions | [create.md](create.md) |
| `review <file>` | Reports the file's breaches of the rules, its drift from the live definitions, and gaps in the loop's design | [review.md](review.md) |
| `start <file>` | Runs the loop in this session: schedules itself, senses, compares, acts, records | [start.md](start.md) |

## Shared resources

- [rules.md](rules.md): the rules `C01`–`C18` for a correct file. `create` writes by
  them and `review` checks against them.
- [vocabulary.yamlld](vocabulary.yamlld): the terms, their labels and comments, and
  their links to Wikidata and SOSA (`https://control-loop.md/vocabulary#`).
- [contexts/](contexts/): the files a project copies beside its `CONTROL-LOOP.md`.
  `control-loop.jsonld` is the context `https://control-loop.md/context`; the other two
  are a copy of the dollar context and its registration, because sparqld loads only
  contexts registered to local files.
- [template.md](template.md): the starting point for `create`.
- [state-template.md](state-template.md): the shape of `loop-state.md`, which `start`
  writes beside the loop file (gitignored).
- [check.rq](check.rq): the check (`C18`).
