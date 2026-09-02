---
type: cycle-report
kind: report
title: "REPORT-architect — ciclo 025, issue #60 (else raise no PropertyVisibility FPC)"
description: "Arquiteto produziu esp/adr/plan/task-input para a issue #60: guarda fail-loud no PropertyVisibility do backend FPC, com nova convencao SFPCUnknown* e correcao do XMLDoc de TModernVisibility."
cycle: "025"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [report, architect, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025]
---

# REPORT — Arquiteto, ciclo 025, issue #60

## O que este ciclo resolve

A issue #60 fecha o lado FPC da mesma falha que a #51 fechou no Delphi: o `case` de
`PropertyVisibility` sem `else` que, no FPC 3.2.2, compila limpo (sem erro, sem
warning, sem hint) e produz ordinal 0 = `mvPrivate` no x86_64 quando recebe um valor
não mapeado — falha silenciosa e convincente.

## Decisão de escopo

**`fits`.** 4 edições em 2 arquivos Pascal. As 4 edições são interdependentes (a
resourcestring é usada pelo `else raise`; o comentário e o XMLDoc documentam a guarda
inserida) — não são separáveis sem publicar estado incoerente. Custo < $3 de implementação.

## Artefatos produzidos

- [esp](pipeline-esp.md) — especificação formal derivada da issue; critérios de
  aceitação, restrições e riscos.
- [adr](pipeline-adr.md) — ADR D-60.1 derivado do relatório de investigação
  (run `b33995300ee8f88b88df1cf389b6248b`). Registra a nova convenção D-60.3
  (`SFPCNo*` vs `SFPCUnknown*`) e supercede D-51.8 para o site `PropertyVisibility`
  do FPC. Cada decisão está ancorada na volta da investigação em que foi tomada.
- [plan](pipeline-plan.md) — slice único com as 4 edições em ordem; inclui o texto
  aprovado do comentário e do XMLDoc, e os comandos de verificação na fábrica.
- [task-input](pipeline-task-input.md) — handoff operacional com acceptance checklist,
  texto do PR body e restrições críticas de implementação.

## Principais decisões deste ciclo

| ID | Decisão | Fonte |
|----|---------|-------|
| D-60.1 | `else raise EModernRTTIError.CreateFmt` no `PropertyVisibility` do FPC | investigação Q1/Q3 |
| D-60.2 | `SFPCUnknownVisibility` na `implementation`, não na interface | investigação Q2; estende D-51.3 |
| D-60.3 | Nova convenção: `SFPCNo*` = feature indisponível; `SFPCUnknown*` = enum não mapeado | investigação Q2 |
| D-60.4 | Mensagem cópia literal do Delphi, só `#51`→`#60`; medição vai para doc, não runtime | investigação Q3 |
| D-60.5 | XMLDoc de `TModernVisibility` entra no PR (não follow-up) | investigação Q1 |
| D-60.6 | Comentário cita #51 e #60 como dois movimentos da mesma decisão | investigação Q5 |
| D-60.7 | PR body declarativo, sem checklist de cobertura humana | investigação Q4 |
| D-60.8 | Nenhum teste novo; ramo inalcançável declarado explicitamente | investigação implícito |

D-51.8 (FPC intocado, premissa de exaustividade) é supersedido por D-60.1 para o site
`PropertyVisibility`. O site `MethodVisibility` do FPC permanece correto por design.

## Fronteira de implementação

A fábrica roda FPC 3.2.2 x86_64 e valida os 42 testes existentes. i386 e os 4 alvos
Delphi ficam com o autor humano, verificados antes do merge. Nenhuma checklist
bloqueante no pipeline (ver D-60.7).

## Não toca

- `MethodVisibility` do FPC — já levanta com `SFPCNoVisibility` por design.
- `Source/ModernSyntax.RTTI.Delphi.pas` — PR #59 (ciclo 022) já corrigiu.
- Suite de testes — contagem FPC permanece 42; nenhum cenário novo.
