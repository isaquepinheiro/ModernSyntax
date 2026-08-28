---
okf_version: "0.2"
---

# Project knowledge bundle

This bundle is the living memory of the project, in OKF format. Any agent or human can orient itself from here.

## Navigation

- [log.md](log.md) — the bundle log: what happened, in order (OKF reserved name)
- [history/](history/index.md) — durable History: cycles, decisions, changes, incidents
- [SKILL.md](SKILL.md) — **the executable build and test recipe, per compiler.** Read it before running or judging a build: it carries the FPC command, the two-bitness requirement, and the two traps that make a green result lie.
- [analysis/](analysis/index.md) — the Analyst dossier: intake, structure, stack, architecture, domain, conventions, gaps and risks
- [strategy/](strategy/2026-08-27-modernrtti/PRD.md) — the ModernRTTI PRD and its study

The pipeline adds `project-evolution.md` (the board) as it produces it — link it here once it exists. The current cycle works in `.project/pipeline/`, which is git-ignored and never part of the committed bundle; its durable per-cycle copy is `history/cycles/cycle-NNN/pipeline-*.md`.

RESERVED FILE (OKF SPEC.md §3.1) — the frontmatter block at the top of this file holds `okf_version` and nothing else — SPEC.md:774 calls a bundle-root `index.md` the ONLY place frontmatter is permitted in an `index.md` (see also SPEC.md:509-511). Adding any other key to it, or a frontmatter block to any OTHER `index.md` in the bundle, is itself a conformance failure (floor item 3, SPEC.md:740-741). To link a document once it exists, edit the body above and leave the frontmatter alone.
