---
type: cycle-report
kind: report
title: "REPORT-planner — ciclo 025, issue #60 (else raise no PropertyVisibility FPC)"
description: "Planejador registrou demanda do ciclo 025: fix fail-loud no PropertyVisibility do backend FPC, 4 edicoes em 2 arquivos, MAESTRO MODE, issue #60."
cycle: "025"
agent: planner
workflow: equipe-bug
node: task
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:task"
  at: "2026-09-02T00:00:00Z"
tags: [report, planner, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025]
---

# REPORT — Planejador, ciclo 025, issue #60

## O que este ciclo planeja

A issue #60 fecha o lado FPC da falha silenciosa em `PropertyVisibility`: o `case`
sem `else` que compila limpo no FPC 3.2.2 e devolve ordinal 0 = `mvPrivate` no x86_64
para qualquer valor não mapeado — exatamente o padrão que a #51 / PR #59 corrigiu no
Delphi. Este ciclo replica a guarda `else raise EModernRTTIError` no backend FPC e
corrige o XMLDoc de `TModernVisibility` que, sem a fix, publicaria afirmação falsa
sobre exaustividade do compilador FPC.

## Modo de rastreamento

**MAESTRO MODE** — issue #60 já existe no GitHub como demanda oficial deste ciclo
(`aefos:investigated`). Nenhuma issue ou Epic adicional criada. Board card de #60
movido para `in_progress`.

## Decisão de escopo (herdada do arquiteto)

**`fits`** — 4 edições em 2 arquivos Pascal. As edições são interdependentes
(a resourcestring é usada pelo `else raise`; o comentário e o XMLDoc documentam a guarda
inserida) e não são separáveis sem publicar estado incoerente. Custo < $3 de implementação.

## Artefatos referenciados

- [pipeline-task-input.md](pipeline-task-input.md) — handoff operacional com acceptance checklist, texto do PR body e restrições críticas.
- [pipeline-esp.md](pipeline-esp.md) — especificação formal.
- [pipeline-adr.md](pipeline-adr.md) — ADR D-60.1; supercede D-51.8 para o site `PropertyVisibility` do FPC.
- [pipeline-plan.md](pipeline-plan.md) — slice único com as 4 edições em ordem e texto aprovado.
- [REPORT-architect.md](REPORT-architect.md) — relatório do arquiteto deste ciclo.

## Board local atualizado

| Ciclo | Issue | Estado |
|-------|-------|--------|
| 025 | [#60](https://github.com/isaquepinheiro/ModernSyntax/issues/60) | 🔄 in-pipeline |

## Entregáveis esperados do implementador

1. `Source/ModernSyntax.RTTI.FPC.pas` — `resourcestring SFPCUnknownVisibility` na `implementation` + comentário reescrito em `PropertyVisibility` + `else raise` no `case`.
2. `Source/ModernSyntax.RTTI.pas` — XMLDoc de `TModernVisibility` (linhas 79–85) reescrito: dois backends levantam `EModernRTTIError`; medição no passado; sem afirmação de exaustividade em compile-time no FPC.
3. Suite FPC 3.2.2 x86_64 verde; contagem permanece 42.
4. Commit único; PR com body verbatim do [task-input](pipeline-task-input.md).

## Não toca

- `MethodVisibility` do backend FPC — já levanta com `SFPCNoVisibility` por design.
- `Source/ModernSyntax.RTTI.Delphi.pas` — PR #59 corrigiu; nenhum diff esperado.
- Suite de testes — ramo `else raise` inalcançável por dado real; nenhum cenário novo.
