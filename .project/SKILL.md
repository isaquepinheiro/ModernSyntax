---
type: skill-config
title: "Project SKILL — ModernSyntax"
description: "Active stacks and quality thresholds for the ModernSyntax project."
---

# Project SKILL — ModernSyntax

## Active stacks

- Pascal/Delphi (Delphi 10.x+)
- FPC 3.2.2 (x86_64, i386)

## Quality thresholds

| Gate | Threshold |
|------|-----------|
| Static analysis errors | 0 |
| Warnings | allowed, counted |

## Toolchain & quality commands

> agent-discovered 2026-08-28 (verify node, cycle-004)

No compiler or lint tool is scriptable in the factory for this Pascal/Delphi/FPC
stack. Compilation runs author-side (R2 do PRD). Static analysis is performed via
grep-based acceptance-criteria checks defined in each cycle's ESP and task-input.

### Grep checks (all cycles)

```bash
# No {$I ModernSyntax.inc} in a production unit
grep -n '{\$I ModernSyntax.inc}' Source/ModernSyntax.RTTI.pas

# No FCP token in a production unit
grep -n 'FCP' Source/ModernSyntax.RTTI.pas

# No banned units in interface (Windows, Classes, Variants, SyncObjs)
grep -n 'Windows\|Classes\|Variants\|SyncObjs' Source/ModernSyntax.RTTI.pas

# No {$IFDEF FPC} branching in test files (CA-5)
grep -rn '{\$IFDEF FPC}' "Test Shared/EclbrSystem/" "Test Delphi/EclbrSystem/" "Test FPC/EclbrSystem/"
```

If `fpc` or `dcc32` become scriptable in CI, add static analysis commands here.
