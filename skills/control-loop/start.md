# Mode: start

Run the loop that a `CONTROL-LOOP.md` describes, from this session. `start` is
idempotent: the first call starts the loop, and the scheduled job calls the same
command for every later cycle. A second call never schedules a second job.

The job's prompt is `/control-loop start <absolute path to CONTROL-LOOP.md>`.

The session keeps only the clock and starts agents. A cycle agent does the work of
each cycle in its own fresh context, and the state file (`C12`) is its memory. Each
request of the session re-reads the session's whole context, so a cycle that ran
in the session would cost one full read per tool call and would grow the context
every tick. A cycle agent costs the session two short turns per cycle (the clock
turn and the turn its result arrives in) and a few lines of context.

## One cycle, in the session

1. **Clock.** Run `CronList` and look for jobs whose prompt is the one above. Delete
   each that is past its time. When one is still pending, keep it and create none.
   When none is pending, create a one-shot job (`CronCreate`, `recurring: false`) at
   now plus the clock's `sample-period`, with that prompt. Do this first, so a failed
   cycle still has a next one. A cycle that a job started finds that job past its
   time, so it always arms the next one.
   **Window.** Read the clock's `window` with one command
   (`grep -m1 '^  window:' <loop file>`); a loop without one ticks at all hours. When
   now plus the sample period falls outside the window, create the job at the
   window's next start instead. When now is outside the window and a job started this
   turn, arm the next job and end the turn: run no cycle agent.
2. **Cycle agent.** Start one agent on the mid-tier model, with a non-fork agent
   type (in Claude Code: `model: "sonnet"`), and the brief in
   [Cycle agent](#cycle-agent). At most one cycle agent runs at a time: while one
   runs, keep new reports for the next. Give it:
   - the absolute paths of the loop file and the state file;
   - the task ids of the agents the session started since the last cycle, each with
     the gap or sensor it serves;
   - the reports of agents that finished since the last cycle, verbatim.
   Extra items for one cycle are additions: the brief says that the agent still runs
   every sensor and every check.
   End the turn; the agent's result starts the next one.
3. **Start jobs.** When the cycle agent's result arrives, start one agent per job it
   returns, on the mid-tier model, with the job's brief verbatim. Keep each task id for the
   next cycle agent's brief. Do not read the loop file, the state file or the
   sensors yourself.
4. **Report.** Pass the cycle agent's report to the supervisor as it is. When it says
   nothing is new, say so in one line.

## Between cycles

- **A background report** (a sensor agent or a worker agent finishes) is part of the
  loop, not a message to relay. Run a cycle now (steps 2–4), with the report in the
  cycle agent's brief, or keep the report for the cycle agent that is running now.
  Do not handle it in the session.
- **Every turn** of the session, whatever started it (a user message, a compaction
  summary, a report), runs `CronList` first. When no job for this file is pending,
  run a cycle now. A compaction summary must carry the `start` command, this rule
  and the task ids not yet given to a cycle agent, or the next turn forgets the loop
  is running; the pending job is the backstop.
- **To stop** the loop, delete its job with `CronDelete`, and run a last cycle agent
  that records the stop in the state file. The loop also stops when the session
  closes; `start` in a new session resumes from the state file.
- **A small context** costs less, because each wake re-reads the session's context.
  The harness's automatic compaction keeps it small: the state file holds the loop's
  memory, and the pending job starts the next cycle after a compaction. Set the
  harness's compaction threshold well above the size of a compacted loop session
  (about 90k tokens), or the session compacts again soon after each compaction. A
  session cannot run `/compact` on itself: a job whose prompt is `/compact` arrives
  as plain text.

## Cycle agent

The brief for the agent of step 2. It works only through files, commands and its
report; it starts no agents.

1. **State.** Read the loop file and the state file. On the first cycle, create the
   state file from [state-template.md](state-template.md), with the loop file's
   `"@base"` copied verbatim, and check that the repo's `.gitignore` lists it. It
   holds each sensor's latest observation (with the task id of a sensor agent still
   running), each gap with the clauses it breaks and its actuation (the actuator, the
   `on-gap` taken, the owner: an agent's task id or a pull request URL, and the
   status), and what was reported to the supervisor. Record the task ids and the
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
   - `on-gap: Act`: return a job, one per gap, whose brief holds the facts already
     known, the actuator's gate, the clause's text and the gap's text. Record the gap
     with the status `starting`; the next cycle records its owner. A gap still
     `starting` after one `sample-period`, with no task id, gets a new job.
   - `on-gap: Propose`: put in the report what to do and why, and record the gap as
     `proposed`.
   Never do a gated step yourself: the worker stops at its actuator's gate.
5. **Record.** Write the state file, then run the check on it (`C18`).
6. **Return** two parts, and nothing else:
   - **Jobs**: each job's brief, ready to pass to an agent, and the gap or sensor it
     serves.
   - **Report**: only what is new since the last report: new sensor values that
     matter, gaps started, gaps proposed, agents that finished. A few lines; when
     nothing is new, one line.
