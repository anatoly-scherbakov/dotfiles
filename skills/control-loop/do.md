# Mode: do

Run the loop that a loop directory describes, from this session. `do` is
idempotent: the first call starts the loop, and the scheduled job calls the same
command for every later cycle. A second call never schedules a second job.

The job's prompt is `/control-loop do <directory relative to the repo root>`. The
directory holds `CONTROL-LOOP.md` and `STATE.md`.
The session runs from the repo root. Never write a machine-local path (home directory,
scratchpad, config directory) into a loop file, a state file or a brief template.

The session keeps only the clock and starts agents. A cycle agent does the work of
each cycle in its own fresh context, and the state file (`C12`) is its memory. Each
request of the session re-reads the session's whole context, so a cycle that ran
in the session would cost one full read per tool call and would grow the context
every tick. A cycle agent costs the session two short turns per cycle (the clock
turn and the turn its result arrives in) and a few lines of context.

## One cycle, in the session

1. **Clock.** Run `CronList` and look for jobs whose prompt is the one above. Do this
   first, so a failed cycle still has a next one.
   - **Backstop.** When no recurring job has that prompt, create one
     (`CronCreate`, `recurring: true`) every 3 hours, only on the hours of the
     clock's `window`: a wake after a gap of more than an hour rewrites the whole
     cache. A turn that fails before its first tool call arms no job, and the
     backstop restarts the loop. A recurring job expires after 7 days; this step
     creates it again. With `trigger: gaps` this job is the slow timer: it always runs
     a full cycle (every sensor and every check).
   - **Next tick.** With `trigger: gaps`, arm no one-shot job (delete one that an earlier
     run left): the [events](#gap-trigger-trigger-gaps) start the cycles between two
     backstop jobs, and a job that starts this turn is the slow timer. Otherwise delete each one-shot job with that prompt that is past its time.
     When one is still pending, keep it and create none. When none is pending, create
     a one-shot job (`recurring: false`) at now plus the clock's `sample-period`, with
     that prompt. A cycle that a one-shot job started finds that job past its time,
     so it always arms the next one.
   - **Backstop tick.** Without `trigger: gaps`: when a job started this turn and a one-shot job is still
     pending, the loop is alive: end the turn and run no cycle agent.
   **Window.** Read the clock's `window` and `trigger` with one command
   (`grep -m2 -E '^  (window|trigger):' <loop file>`); a loop without a window ticks at all hours. When
   now plus the sample period falls outside the window, create the one-shot job at
   the window's next start instead. When now is outside the window and a job started
   this turn, arm the next job and end the turn: run no cycle agent.
2. **Cycle agent.** Start one agent on the mid-tier model, with a non-fork agent
   type (in Claude Code: `model: "sonnet"`), and the brief in
   [Cycle agent](#cycle-agent). At most one cycle agent runs at a time: while one
   runs, keep new reports for the next. Give it:
   - the loop directory, relative to the repo root;
   - the task ids of the agents the session started since the last cycle, each with
     the gap or sensor it serves;
   - the reports of agents that finished since the last cycle, verbatim;
   - the task ids of the agents still running now; every other task id in the state
     file belongs to an agent that is gone.
   Extra items for one cycle are additions: the brief says that the agent still runs
   every sensor and every check.
   End the turn; the agent's result starts the next one.
3. **Start jobs.** When the cycle agent's result arrives, start one agent per job it
   returns, on the mid-tier model, with the job's brief verbatim. Keep each task id for the
   next cycle agent's brief. Do not read the loop file, the state file or the
   sensors yourself. When an actuator's gate needs only checks, the session or its
   worker executes it once they pass; hold only for a gate that names a person.
   A gate that a worker or cycle agent cites stands until you can quote the text
   that lifts it; a search that misses the rule does not lift it.
   Zero reported checks is not a pass: wait until the PR's expected checks appear
   and complete before you merge.
4. **Report.** Pass the cycle agent's report to the supervisor as it is. When it says
   nothing is new, say so in one line.

## Gap trigger (`trigger: gaps`)

A loop whose clock has `trigger: gaps` starts a **dispatch** in the session, inside the
window, on each of these events:

- an agent the session started finishes;
- a cycle agent's or dispatch agent's result reports a gap that opened or closed, when it
  is a full cycle's result.

A dispatch's own result starts no dispatch. A dispatch is a cycle agent whose brief says `dispatch`. At most one cycle agent or
dispatch agent runs at a time; keep new events for the next one. The slow timer is
the only job that senses: a gap that comes from outside the loop (a message, a merge, a
person's act) is found by the next timer's sensors. The dispatch runs no sensor and no
check; it only dispatches. The session starts the dispatch's jobs as in step 3.

- **Unblocked gap.** An open gap that has no open `BLOCKS` edge to it, is not parked, is not
  held by the loop file (for example a held sprint), has no running owner and has no
  `retry-after` in the future. A gap is parked when it waits on one named thing that has not
  happened: the loop file's `memory` names the field that records the wait and the statuses
  that park a gap, and the open-gaps query returns that field. A status word alone parks no gap.
- **Pick.** The dispatch returns jobs for unblocked gaps, one per gap, up to the
  `WorkInProgressLimit` that bounds gap workers, less the agents already running.
  Gaps beyond the limit stay open; the next finished agent starts the next dispatch.
- **Rest.** When no gap is unblocked and no agent runs, the loop does nothing until the
  slow timer. A gap whose `retry-after` is in the future counts as unblocked when that
  time passes, and the timer finds it.
- **Retry.** A job fails when its agent finishes with the gap still open and no progress
  to report, or when its owner is gone (the gap's owner is not in the running list). Each
  failure adds 1 to the gap's `attempts` and sets `retry-after` to now plus a wait that
  doubles with each failure, from one sample period (45 minutes, then 90 minutes).
  When `attempts` reaches the clock's `retry-limit` (3 when absent), the status
  becomes `stuck`, no job starts, and the dispatch returns a card job (one question: what
  to do with the gap). A stuck gap waits on a person: the card's answer closes it or resets
  `attempts` to 0. A gap kept where `memory` says records `attempts` and `retry-after` in the
  shape `memory` defines.

## Between cycles

- **A background report** (a sensor agent or a worker agent finishes) is part of the
  loop, not a message to relay. Run a cycle now (steps 2–4), with the report in the
  cycle agent's brief, or keep the report for the cycle agent that is running now.
  With `trigger: gaps` the cycle is a dispatch. Do not handle it in the session.
- **Every turn** of the session, whatever started it (a user message, a compaction
  summary, a report), runs `CronList` first. When no one-shot job for this loop is
  pending, run a cycle now. With `trigger: gaps`, a missing backstop job is created
  and a full cycle runs; nothing else is armed. A compaction summary must carry the `do` command, this
  rule and the task ids not yet given to a cycle agent, or the next turn forgets the
  loop is running; the pending jobs are the backstop.
- **To stop** the loop, delete its jobs with `CronDelete`, and run a last cycle
  agent that records the stop in the state file. The loop also stops when the session
  closes; `do` in a new session resumes from the state file.
- **A small context** costs less, because each wake re-reads the session's context.
  The harness's automatic compaction keeps it small: the state file holds the loop's
  memory, and the pending job starts the next cycle after a compaction. Set the
  harness's compaction threshold well above the size of a compacted loop session
  (about 90k tokens), or the session compacts again soon after each compaction. A
  session cannot run `/compact` on itself: a job whose prompt is `/compact` arrives
  as plain text.

## Cycle agent

The brief for the agent of step 2. It works only through files, commands and its
report; it starts no agents. The brief says `full` (the default) or `dispatch`
([Gap trigger](#gap-trigger-trigger-gaps)). A dispatch runs steps 1 and 4–6, skips
steps 2 and 3 (no sensor job, no check, no observation written), and picks only the
unblocked gaps in step 4; its report names each gap that opened or closed.

1. **State.** Read the loop file and the state file. On the first cycle, create the
   state file from [state-template.md](state-template.md), with the loop file's
   `"@base"` copied verbatim, and, when the loop directory is in a git repo, commit it with the loop file. It
   holds each sensor's latest observation (with the task id of a sensor agent still
   running) and what was reported to the supervisor. Each gap, with the clauses it
   breaks and its actuation (the actuator, the `action` taken, the owner: an agent's
   task id or a pull request URL, and the status), is in the state file's `gaps` list,
   unless the loop file's `memory` says the gaps live elsewhere (for example a knowledge
   graph) and names the query that finds the open ones: then the state file has no `gaps`
   key, the agent runs that query for the gaps, and it writes a new or changed gap where
   `memory` says. Record the task ids and the
   reports from the brief first.
2. **Sense.** Run each sensor's `reads` that is a command, a query or an API call.
   For a sensor that is an agent, return a job with its brief, at most one per
   sensor: only when the state file holds no running task id for it.
3. **Compare.** Run each check: its `command` for a verified check, its `judge` for
   an inferred one. A clause holds when every check that covers it passes. A gap
   that waits on a person is a reading: check the thread, card or pull request it
   waits on every cycle, and close the gap when the person has acted.
4. **Act.** For each clause that does not hold, and each gap a sensor reported that
   has no owner in the state file, pick the actuator whose `output` fixes it:
   - `action: act`: return a job, one per gap, whose brief holds the facts already
     known, the actuator's gate, the clause's text and the gap's text. Record the gap
     with the status `starting`; the next cycle records its owner. A gap still
     `starting` after one `sample-period`, with no task id, gets a new job. A gap
     whose owner is a task id not in the brief's running list, or that has no owner,
     gets a new job in this cycle (with `trigger: gaps`, after the retry rule: the
     failure counts in `attempts`). "Waiting" is a valid status only when the gap
     waits on a person's act that you checked this cycle.
   - `action: propose`: put in the report what to do and why, and record the gap as
     `proposed`.
   Never do a gated step yourself: the worker stops at its actuator's gate.

   A concern that a party outside the loop raises (in a meeting note, a message the
   sensors read, or a decision record) and that the loop promised to act on is a gap in
   the same cycle. It stays open until the promised work is done and the party has
   been told. When no clause covers the concern, record the gap with no `breaks` and
   report the missing clause to the supervisor.
5. **Record.** Write the state file, then run [`check.rq`](check.rq) (`C18`) on it
   through the project's `control-loop` sparqld MCP server. Read sparqld's load report:
   0 files loaded, or 1 or more failed, is a FAIL, even when the query returns no
   rows. Quote every `reported` line as a string. If that server is not
   set up, set it up as [rules.md](rules.md) `C18` says, and report that the check
   waits for the next session. Delete each gap that is closed and reported from the state
   file (a gap kept elsewhere is closed where `memory` says); git history is the record.
   Commit `STATE.md` every cycle; open a pull request only when the record changes: a gap opens or closes, a gap's status
   or owner changes (wherever the gap is kept), or the cycle reports news
   (a `reported` line other than the one-line nothing-is-new report).
   Ship that change in one pull request and merge it once checks pass, under the
   project's merge rule. When only observations change, commit them without a pull
   request; the next pull request carries them.
   When the loop directory is not in a git repo, keep `STATE.md` beside the loop file
   and skip the commit.
6. **Return** two parts, and nothing else:
   - **Jobs**: each job's brief, ready to pass to an agent, and the gap or sensor it
     serves. Each brief ends with: "Any agent you start runs on the same model as
     you."
   - **Report**: only what is new since the last report: new sensor values that
     matter, gaps started, gaps proposed, agents that finished. A few lines; when
     nothing is new, one line.
