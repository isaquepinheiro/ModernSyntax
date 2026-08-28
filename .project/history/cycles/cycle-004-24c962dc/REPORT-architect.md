---
type: cycle-report
kind: report
title: "REPORT — architect (ciclo 004, issue #7 callbacks transversais)"
description: "Dossiê de design entregue (esp, adr, plan, task-input); ADR deriva do investigation report PRESENT (run d8638f50); escopo fits, 4 fatias sequenciais sem independência."
cycle: "004"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/24c962dcc2be1819336ca1fea18ae949
tags: [architect, cycle-004, modernrtti, callbacks, issue-7]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T13:30:00Z"
---

# REPORT — architect (ciclo 004)

## O que entreguei

Quatro documentos em `.project/pipeline/`:

- [esp](pipeline-esp.md) — especificação da unit `ModernSyntax.Callback`,
  três interfaces genéricas `IModern*<T[,R]>` sem GUID, factory
  `Callback.Of` só com sobrecargas de método de objeto neste ciclo, e o
  esquema de teste em três diretórios (`Test Shared/`, `Test Delphi/`,
  `Test FPC/`). Vincula CA-4/CA-5/CA-6/CA-7/R2 do PRD a critérios
  objetivos verificáveis por grep + build.
- [adr](pipeline-adr.md) — **deriva** do investigation report PRESENT
  (run `d8638f50`), restaurando D-1 a D-5 nos termos que a discussão
  fechou. D-A9 responde à decisão pendente do gate (nome dos contratos:
  `IModern*` e não `IMS*`, com divergência declarada). D-A10 registra a
  correção de medição (415, não 451). Zero divergência silenciosa.
- [plan](pipeline-plan.md) — 4 fatias sequenciais: unit, cenários
  compartilhados, casca Delphi + `.dproj`, casca FPC + `.lpi`.
- [task-input](pipeline-task-input.md) — handoff operacional com
  checklist de aceite e greps.

## Investigation report

Status **PRESENT** (run `d8638f50`, comentário na issue #7). O ADR é
uma restauração fiel: as decisões D-1/D-2/D-3/D-4/D-5 do relatório
viram D-A1..D-A11 aqui, com nomes ligeiramente diferentes por já haver
D-1..D-5 do PRD em jogo. **Divergências assumidas** — só duas, ambas
explícitas: (a) o nome `IModern*` no lugar de `IMS*` (D-A9, respondendo
à pergunta do gate) e (b) o número 415 no lugar de 451 (D-A10,
correção de medição).

## Scope estimate

**`fits`.** Test 1 (SIZE): implementação enxuta — três interfaces + um
factory + três wrappers + testes de casca fina. Cabe em orçamento de
implementação normal. Test 2 (INDEPENDENCE): **falha** — nenhuma das
quatro fatias é mergeável sozinha: a unit sem os testes não prova
portabilidade; os testes sem a unit não compilam; a casca FPC sem o
`.lpi` não roda (CA-6 do PRD). Portanto um único ciclo, 4 fatias
sequenciais.

## Pontos de atenção para os próximos nós

1. **Não incluir `ModernSyntax.inc`** na unit nova (D-A5 / D-A11 do
   [adr](pipeline-adr.md)). Bug do `{$IFDEF FCP}` fica intocado.
2. **Nome `IModern*`** — divergência declarada da issue e do PRD; o PR
   precisa explicar (checklist do
   [task-input](pipeline-task-input.md)).
3. **Search path do `.dproj`** (Q2 do relatório de investigação) —
   resolvido em implementação, mesmo commit.
4. **PR declara literalmente** o CA-7 do [esp](pipeline-esp.md) sobre
   R2 do PRD.

## Notas de contexto do ciclo

Este é o 2º ciclo sobre a issue #7 — o cycle-003 já produziu a mesma
substância de design e PR #12 foi mergeado (ver
[REPORT-retrospective](../cycle-003-92fccbce/REPORT-retrospective.md)
do ciclo anterior). O design substantivo foi preservado; os artefatos
são novos e carregam a identidade do ciclo 004. Se downstream detectar
que a implementação já existe no repositório, isso é fato do estado do
código, não decisão de design deste nó.
