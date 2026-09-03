---
type: cycle-report
kind: report
title: "REPORT architect — cycle 029 (issue #13) — dinamico com fronteira POR ALVO"
description: "Ciclo 029 corrige os dois criterios do ciclo 028 que a fabrica nao podia satisfazer (prova em i386 e assertiva de valor de retorno no FPC), ancorando a fronteira em ALVO (existencia de SystemInvoke) em vez de BITNESS; assinatura identica e demais decisoes D-13.* preservadas."
cycle: "029"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [cycle-report, architect, rtti, invoker, fpc, delphi, dynamic-invoke, per-target, systeminvoke, issue-13, cycle-029]
---

# REPORT architect — cycle 029 (issue #13)

## Escopo entregue

`fits`. Um slice, um commit, um PR. Quatro artefatos escritos em
`.project/pipeline/`:

- [pipeline-esp](pipeline-esp.md) — objetivo, escopo, regras, criterios de
  aceitacao, riscos.
- [pipeline-adr](pipeline-adr.md) — carrega D-13.1..D-13.13 do ciclo 028;
  acrescenta D-29.1 (XMLDoc por alvo), D-29.2 (testes de valor ramificam
  por alvo com `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}`)
  e D-29.3 (fabrica prova o que o ambiente dela permite).
- [pipeline-plan](pipeline-plan.md) — dez passos, um slice.
- [pipeline-task-input](pipeline-task-input.md) — handoff operacional para
  o implementador com checklist e 18 traps.

## Correcao central deste ciclo

O ciclo 028 foi rejeitado nove vezes com `REJECTED · causa: spec` porque
dois criterios do ESP anterior eram **impossiveis de satisfazer na
fabrica**:

1. *"Prova nos DOIS bitness do FPC (i386 e x86_64)"* — `ppc386` ausente
   na fabrica (SKILL.md).
2. *"O backend FPC assere valor de retorno"* — `SystemInvoke` da RTL nao
   esta implementado em `x86_64-linux` (SysV AMD64) no FPC 3.2.2; medido
   dentro do container. O `Rtti.Invoke` livre cai em
   `ENotImplemented` / `SErrInvokeNotImplemented`.

Este ciclo ancora a fronteira em **ALVO** (existencia de `SystemInvoke`),
nao em bitness — conforme a **CORRECAO 2** que o dono registrou no
proprio corpo da issue #13 em 03/09. Assinatura identica cross-compiler,
alcance por compilador (D-13.3), tres blocos superados do cabecalho
removidos (D-13.7) e demais decisoes D-13.* seguem valendo.

## Decisoes novas (D-29.*)

- **D-29.1** — XMLDoc declara alcance por compilador E fronteira POR ALVO:
  Delphi | FPC-Windows | FPC-outros. A linha de FPC-outros cita
  `SErrInvokeNotImplemented` literal e `packages/rtl-objpas/src/<arch>/invoke.inc`.
- **D-29.2** — Os 4 cenarios `Case_InvokeDynamic_Returns...` ramificam com
  `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}`. No ramo
  verdadeiro, asserem `ENotImplemented`; no `{$ELSE}`, asserem valor. Os
  4 cenarios de guarda (`Nil`, `MethodNotFound`, `PublicWithoutMPlus_*`)
  NAO ramificam — a guarda dispara antes da RTL.
- **D-29.3** — Fabrica prova `PTestInvoker` verde 14/14 em x86_64-linux
  (com `ENotImplemented` visivel nos 4 cenarios de valor); FPC Windows,
  FPC i386 e Delphi ficam com o autor. Consistente com D-60.7 / D-62.4
  (fabrica entrega, autor prova depois).

## Fonte da decisao (sem `investigate`)

Status NONE — a #13 chegou a esta fabrica com 1 comentario; nenhum abre
com marcador `investigate`. O desenho vem do **corpo da propria issue**,
secao *"CORRECAO 2 — 03/09/2026, medida DENTRO da fabrica"*, mais o ADR e
implement-report do ciclo 028 (que mediu `SystemInvoke` ausente em
`x86_64-linux`).

## Escopo estimado — `fits`

- **TEST 1 (tamanho):** 1 unit de producao + 1 arquivo compartilhado + 2
  cascas. Dentro do orcamento de um implement (~$10-15). O ciclo 028
  entregou implementacao equivalente em `21 lines compiled, 0.2 sec`.
- **TEST 2 (independencia):** um slice unico; nao ha subconjunto
  mergeavel de forma independente (backends, cenarios ramificados e
  cabecalho reescrito formam UMA peca).

Nao ha `split-proposal.md`.
