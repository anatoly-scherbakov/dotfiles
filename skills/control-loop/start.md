# Mode: start

Run the loop that a `CONTROL-LOOP.md` describes, in this session. `start` is
idempotent: the first call starts the loop, and the scheduled job calls the same
command for every later cycle. A second call never schedules a second job.

The job's prompt is `/control-loop start <absolute path to CONTROL-LOOP.md>`.

## One cycle

1. **Clock.** Run `CronList` and look for jobs whose prompt is the one above. Delete
   each that is past its time. When one is still pending, keep it and create none.
   When none is pending, create a one-shot job (`CronCreate`, `recurring: false`) at
   now plus the clock's `sample-period`, with that prompt. Do this first, so a failed
   cycle still has a next one. A cycle that a job started finds that job past its
   time, so it always arms the next one.
2. **State.** Read the `state` file (`C12`). On the first cycle, create it from
   [state-template.md](state-template.md), with the loop file's `"@base"` copied
   verbatim, and check that the repo's `.gitignore` lists it. It holds each sensor's latest observation (with the task id of a sensor
   agent still running), each gap with the clauses it breaks and its actuation (the
   actuator, the `on-gap` taken, the owner: an agent's task id or a pull request URL,
   and the status), and what was reported to the supervisor.
3. **Sense.** Run each sensor's `reads`. A sensor that is an agent runs in the
   background, at most one per sensor: start it only when the state file holds no
   running task id for it, and record the id.
4. **Compare.** Run each check: its `command` for a verified check, its `judge` for
   an inferred one. A clause holds when every check that covers it passes.
5. **Act.** For each clause that does not hold, and each gap a sensor reported that
   has no owner in the state file, pick the actuator whose `output` fixes it:
   - `on-gap: Act`: start a background agent now, one per gap, with the facts already
     known, the actuator's gate and the clause's text. Use the mid-tier model. Record
     the agent's task id as the gap's owner.
   - `on-gap: Propose`: tell the supervisor what to do and why, and record the gap as
     `proposed`.
   Never do a gated step yourself: the agent stops at its actuator's gate.
6. **Record and report.** Write the state file, then run the check on it (`C18`). Report to the supervisor only what is
   new since the last report: new sensor values that matter, gaps started (with their
   owners), gaps proposed, agents that finished. When nothing is new, say so in one
   line.

## Between cycles

- **A background report** (a sensor agent or a worker agent finishes) is part of the
  loop, not a message to relay. In the same turn, update the state file and run step
  5 for every gap it reports. Do not wait for the next cycle.
- **Every turn** of the session, whatever started it (a user message, a compaction
  summary, a report), runs `CronList` first. When no job for this file is pending,
  run a cycle now. A compaction summary must carry the `start` command and this
  rule, or the next turn forgets the loop is running; the pending job is the
  backstop.
- **To stop** the loop, delete its job with `CronDelete` and record the stop in the
  state file. The loop also stops when the session closes; `start` in a new session
  resumes from the state file.
