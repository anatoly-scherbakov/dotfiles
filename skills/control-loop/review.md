# Mode: review

Review an existing `CONTROL-LOOP.md`. Follow [rules.md](rules.md). The review reads
and reports; it edits the file only when the user asks for the fixes.

0. Confirm `sparqld` 0.1.7 or newer (skill Prerequisite). Propose install or
   upgrade if missing or outdated; do not run the check until that version is
   available (or the user declines—then report that the check could not run).
1. Run the check (`C18`). Each row is a finding.
2. Check the file against each rule `C01`–`C17`. Each breach is a finding, with its
   rule number.
3. Read the live definitions again (`C15`) and compare. Each difference is a finding:
   a `definition` link to a file that is gone, a limit, gate or schedule that changed,
   a sensor or actuator the loop gained or lost.
4. Compare the project's `contexts/` with this skill's. An older copy is a finding.
5. Look for gaps in the loop's design. Each is a finding:
   - a clause with no verified check;
   - an actuator whose `on-gap` is `Propose` although its gate comes after the work
     starts (the loop waits for a person it does not need);
   - no work-in-progress limit on an actuator whose output waits for people;
   - no `state` file, so the loop forgets what it reported when its session is
     compacted or closed.

Report the findings grouped by kind, each with the line or node it concerns and the
fix. Update the Coverage section (`C17`) only as part of applying fixes.
