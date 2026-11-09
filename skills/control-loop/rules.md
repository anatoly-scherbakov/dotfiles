# Control loop rules

These rules define a correct `CONTROL-LOOP.md`. The `create` mode writes by them and
the `review` mode checks against them. Cite a rule by its number.

## Files

- `C01` A `CONTROL-LOOP.md` describes one loop. It lives in the project root, or beside
  the documents the loop works from (for example a runbook directory).
- `C02` A `contexts/` directory sits beside it, holding a copy of this skill's
  `contexts/` files. They are JSON-LD, never YAML-LD: some knowledge-graph importers
  load every `.yamlld` file in a repository, whatever their file patterns say, so a
  `.yamlld` context would land in the project's graph.
- `C03` The frontmatter's `"@context"` is `https://control-loop.md/context`, then one
  entry with `"@base"` and the project's own prefixes, if any. `"@base"` is the loop
  file's URL on the default branch, so `#loop` and the other ids are the same IRIs in
  every checkout and in the state file. Every other key must be a vocabulary term; any
  unknown key expands into `https://control-loop.md/undefined/`, which the check
  reports. Quote every value that starts with `#` (`loop: "#loop"`): unquoted, YAML
  reads it as a comment and drops the value.
- `C04` In a repo that is shared with a customer, write the file so the customer can
  read it: no internal channel ids, no quotes from internal conversation, no
  assessments of people. Name people only the way the repo already names them.

## Shape

- `C05` The root node has `$id: "#loop"`, `$type: ControlLoop`, a `name` and a
  `system` that says in words what the loop controls.
- `C06` The `goal` is reached once. The `set-point` is held on every tick on the way
  there. Both are free text.
- `C07` The set point's conditions are `clauses`. Each is a `SetPoint` with
  `$id: "#set-point-<name>"`, a short `name` and a `text`. The text is the source of
  truth; a check refines a clause and never replaces its text.
- `C08` Give an `$id` only to a node that something points at: the root, each
  set-point clause (checks and gaps point at it), each sensor and each actuator (the
  state file points at them): `#sensor-<name>`, `#actuator-<name>`. Leave every other
  node without one; queries reach it through its property.
- `C09` Every check `covers` one or more clauses and has a `verdict`. `Verified`: a
  `command` (a command, query or validation) gives the same answer on the same state.
  `Inferred`: a `judge` model reads the text. A clause that only inferred checks cover
  is closed by the supervisor, never by the loop.
- `C10` Every actuator has an `output`, a `gate` and an `on-gap`. `gate` says in words
  what stands between the output and the system: a review, a merge rule, a person's
  yes, or the standing approval that removed it. `on-gap` says what the loop does when
  a gap needs this actuator: `Act` when the loop may start the work now, because the
  gate comes later (an agent opens a pull request and the review is the gate);
  `Propose` when a person must decide before anything starts.
- `C11` The `clock` has a `sample-period` (an `xsd:duration`, such as `PT45M`) and a
  `mechanism`. When the `do` mode runs the loop, the mechanism says so, and the
  sample period is the interval it schedules. An optional `window`
  (`<days> HH:MM-HH:MM UTC`) limits the ticks to those days and hours; a loop with no
  window ticks at all hours.
- `C12` `memory` lists the durable records the loop reads and writes. `state` is
  `loop-state.md`, the file beside `CONTROL-LOOP.md` that the `do` mode reads and
  writes every cycle. The repo's `.gitignore` lists it, so it is never committed.
  It is Markdown-LD in the shape of [state-template.md](state-template.md): each
  sensor's latest `Observation` (SOSA), each `Gap` with the clauses it `breaks` and
  its `Actuation` (SOSA: the actuator, the `on-gap` taken, the `owner`, the
  `status`), and what was `reported`. It has the same `"@base"` as the loop file, so
  its references (`"#set-point-…"`, `"#sensor-…"`, `"#actuator-…"`) are the loop
  file's IRIs.
- `C13` A sensor `reads` something concrete: a command, an API call, a query, or an
  agent with its brief. A sensor that reads a channel where the supervisor acts
  returns the supervisor's own actions there too: they close gaps. A controller has
  a `role`. A `WorkInProgressLimit` has a
  `limit`.
- `C14` A part the loop lacks gets a node anyway, with a `status` that says it is
  missing. A limit left out on purpose says so in its `status`, with the decision.

## Sources

- `C15` Read each part from its live definition: the skill, prompt, factory, CI file
  or runbook the loop runs on, on its default branch. Link it with `definition`. A
  stale checkout, an old plan or an earlier session's summary is not a source.
- `C16` A new term goes into both `vocabulary.yamlld` and `contexts/control-loop.jsonld`,
  with a `label` and a `comment` in the vocabulary, and `skos:exactMatch` or
  `skos:closeMatch` to Wikidata when a verified item fits (use the `find-url-for`
  skill). Then copy the updated context into each project that uses the term.

## Body

- `C17` The Markdown body says what the loop is for in two or three sentences, then a
  `## Coverage` section: each clause with no verified check, and each missing part.

## Check

- `C18` A file (the loop file, and the state file when there is one) passes when
  [`check.rq`](check.rq) returns no rows. It lists each file
  sparqld could not load, with the parser's line and column, each key, class or
  value the context does not define, and each reference to a clause, sensor,
  actuator or loop that no file defines, and each open gap with `on-gap: Propose`
  whose clause no `Verified` check covers. Run it with sparqld 0.1.6 or later:
  - through the project's `control-loop` MCP server (the `sparqld` skill), set up in
    the local scope, so it is not committed:
    `claude mcp add --scope local control-loop -- sparqld mcp --pattern '<directory>/CONTROL-LOOP.md' --pattern '<directory>/loop-state.md' --pattern '<directory>/contexts/**' <absolute project path>`,
    where `<directory>` is the file's directory relative to the project root (no
    prefix for the root). Its tool appears from the next session on;
  - or, for a checkout without that server (a worktree), over HTTP:
    `sparqld --no-watch --port <free port>` with the same patterns, in the background,
    then `curl --data-urlencode query@<this skill>/check.rq http://127.0.0.1:<port>/`,
    then stop sparqld.
