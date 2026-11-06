# Mode: create

Write a new `CONTROL-LOOP.md` for a loop. Follow [rules.md](rules.md).

1. Read the loop's live definitions (`C15`): its prompt or skill, its schedule, the
   controllers and agents it starts, the actuators' merge and approval rules, and
   where it keeps memory. Read the repo's `AGENTS.md` files in full first.
2. Choose the directory (`C01`). Refuse if a `CONTROL-LOOP.md` is already there:
   that is the `review` mode's work.
3. Copy [template.md](template.md) to `CONTROL-LOOP.md` there, and this skill's
   [contexts/](contexts/) files into a `contexts/` directory beside it (`C02`).
4. Fill in the template by the rules `C03`–`C14`. Where a part is missing, add it with
   a `status` (`C14`); do not leave it out.
5. Write the body (`C17`).
6. Run the check (`C18`). Fix every row it returns.

Completion criterion: the check returns no rows, and every actuator has an `on-gap`.
Report the file's path, the clauses, and the Coverage section.
