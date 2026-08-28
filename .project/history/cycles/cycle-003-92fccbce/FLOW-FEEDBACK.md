---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — SKILL.md absent; quality-review node has no conventions reference"
description: "The quality-review prompt references .project/SKILL.md as a review target, but the file does not exist in the bundle; reviewer fell back to ESP/ADR/plan only."
cycle: "003"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/92fccbce1ddb8c2d37df799793017636
tags: [flow-feedback, cycle-003, pipeline]
generated:
  by: "equipe-feature@node:review"
  at: "2026-08-28T11:15:00Z"
---

# FLOW-FEEDBACK — Missing `.project/SKILL.md`

## Problem

The `review` node prompt instructs the quality reviewer to review against
*"the conventions in `.project/SKILL.md`"*. The file does not exist anywhere
in the bundle (confirmed: `find .project -name "SKILL.md"` → no output).

The `implement` node's [implement-report](pipeline-implement-report.md) also
records this: *"`.project/SKILL.md` **não existe** (verificado). O documento
`.project/analysis/05-conventions.md` confirma 'None found' para CI/lint/formatter."*

The reviewer fell back to `05-conventions.md` (which documents the absence
of a convention layer) and the pipeline documents (esp, adr, plan). This is
fine for this cycle, but the mismatch generates a dead reference on every
review run.

## Suggested workflow change

One of:

1. **Remove the `SKILL.md` reference from the `review` node prompt** if the
   bundle does not carry a SKILL.md for this project. Replace with the specific
   bundle paths that actually exist (e.g., `analysis/05-conventions.md`).

2. **Create `.project/SKILL.md`** as a bundle-level conventions document
   (coding style, naming rules, file-header format, lint commands) derived
   from the intake/structure/conventions analysis files. If this is meant to
   be a per-project living document that the analyst node populates, the
   analyst prompt should include creating it as a deliverable.

Do NOT modify the workflow without human review — this note is for the human
who owns the pipeline configuration.
