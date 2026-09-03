---
type: cycle-report
kind: report
title: "REPORT quality-verify — ciclo 028"
description: "Compilacao FPC limpa; 10/14 passam; 4 ENotImplemented sao limite RTL documentado; veredicto PASSED."
cycle: "028"
agent: quality
workflow: equipe-feature
node: verify
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:verify"
  at: "2026-09-03T00:00:00Z"
tags: [quality, verify, fpc, rtti, invoker, issue-13, cycle-028]
---

# REPORT quality-verify — ciclo 028

## Resumo

Gate FPC 3.2.2 x86_64-linux: compilacao limpa (0 erros, 0 warnings).
Suite: 14 testes, 10 passam, 0 falhas, 4 erros `ENotImplemented`.

Os 4 erros correspondem ao limite documentado da RTL FPC (`Rtti.Invoke` livre
nao implementada para SysV AMD64 ABI em FPC 3.2.2). A tarefa os nomeia
explicitamente como "fronteira medida" e declara que nao serao mascarados (D-13.2).

Detalhes completos em [pipeline-verify-report.md](pipeline-verify-report.md).

## Veredicto

**PASSED**
