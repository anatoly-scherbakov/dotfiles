---
name: retro
description: Turn a concrete mistake or correction from the active conversation into minimal, durable agent guidance. Use when the user asks for a retrospective or when the agent recognizes a mistake worth preventing in future work.
disable-model-invocation: true
---

# Retro

Turn a recognized mistake from the active conversation into the smallest
durable instruction that would have prevented it. This skill is
conversation-native: do not depend on bug-report queues, local feedback files,
or transcript files from another agent.

## Goal

Reduce repeated agent mistakes without turning a one-off incident into broad or
duplicative guidance.

## Workflow

1. Review the active conversation for concrete learning candidates: a user
   correction, a retracted claim, unrequested scope expansion, ignored stored
   context, a repeated mistake, or avoidable workflow friction. Use only facts
   available in the conversation and relevant workspace guidance.
2. For each candidate, identify the underlying cause and formulate one short,
   imperative rule that would have prevented it. Skip incidental details,
   speculation, and lessons already documented.
3. Select the narrowest useful target:
   - Cross-project agent behavior goes in the user-global agent guidance.
   - Project or directory conventions go in the applicable `AGENTS.md`.
   - Instructions relevant only while a skill is active go in that skill's
     `SKILL.md`.
   Inspect the target before proposing an edit; do not create a new guidance
   file when an existing, narrower target applies.
4. Present each proposed lesson separately with the mistake, cause, target, and
   proposed rule. Ask for explicit approval before changing a guidance file.
   The user may apply, skip, dismiss, reword, or redirect the proposal.
5. After an approved write, read the target back and verify the new guidance is
   present. If an `AGENTS.md` exceeds roughly 80 lines, flag it and offer
   consolidation, but never remove existing guidance without approval.
6. Report the applied, skipped, and dismissed proposals. Do not persist a
   backlog, delete external reports, or infer approval from a prior session.

## Constraints

- Extract lessons from the current conversation; do not read or require Claude
  Code feedback drafts or session transcripts.
- Prefer one precise preventative rule per mistake. Do not preserve incident
  history as agent guidance.
- Never write guidance silently. If there is no explicit approval, report the
  proposal and leave the workspace unchanged.
- Do not duplicate guidance already present in the selected target.
