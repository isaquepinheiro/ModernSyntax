---
type: cycle-report
kind: report
cycle: "006"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
title: "REPORT-architect — cycle 006 (issue #8, Pilar 1 ModernRTTI)"
description: "Ciclo 006: esp/adr/plan/task-input para o Pilar 1 do ModernRTTI, derivando integralmente do REPORT do investigate run 6326ac737a75; escopo fits (não split); zero divergência do que foi acordado com o dono."
status: draft
tags: [modernrtti, architect, cycle-006, issue-8, pilar-1]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-28T14:45:00Z"
---

# REPORT-architect — ciclo 006 (issue #8)

## O que este ciclo entrega

Quatro artefatos de desenho para a issue #8 (Pilar 1 do ModernRTTI):

- [pipeline-esp.md](pipeline-esp.md) — especificação com 14 regras de
  negócio e 11 critérios de aceitação.
- [pipeline-adr.md](pipeline-adr.md) — 11 decisões, todas registradas em
  concordância com o REPORT do `investigate` (nenhuma divergência).
- [pipeline-plan.md](pipeline-plan.md) — 4 fatias sequenciais (F1→F2→F3→F4).
- [pipeline-task-input.md](pipeline-task-input.md) — handoff operacional
  com checklist de 11 itens mapeados 1-para-1 ao ESP.

## Origem das decisões

O ADR **deriva integralmente** do `REPORT — Issue #8` do `investigate`
run `6326ac737a7550e0c239b5b28be40624`, entregue verbatim no prompt do
`architect`. As 11 decisões (D1–D11) instanciam a volta 1 daquela
conversa: nome da unit, exceção obrigatória em vez de opt-in, mensagem
instrutiva unificada, API genérica com `TValue` de escape hatch,
`TArray<T>` com contrato de ownership, infra FPC herdada da #7 sem
inventar `.lpi`, `{$IFDEF FPC}` direto sem `.inc`, casca fina, header
`(* … *)`, e prefixo de interface fora do escopo do Pilar 1.

**Nenhuma decisão silenciosa** — o ADR abre com uma nota explícita:
"nenhuma divergência do REPORT."

## Escopo e por que é `fits`

- **Tamanho:** uma unit de produção (~200 linhas) + três testes finos
  + edits em `groupproj`/`DCC.bat`/`.lpi`. Cabe folgadamente num
  implement budget.
- **Independência:** as fatias F1→F2→F3→F4 **não** stand-alone. F2
  substitui código de F1; F3 depende da exceção de F2 para o cenário
  R4 passar; F4 espelha F3 no FPC. Cortar em N cycles pagaria o overhead
  fixo N vezes por um trabalho que é um pilar coerente.

Portanto: **fits**.

## Dependências e fallback

Depende da **#7** (que criou `Test Shared/EclbrSystem/` e
`Test FPC/EclbrSystem/` + `.lpi` FPCUnit) mergeada. Se não estiver:
fallback CA-11 do ESP — PR desta declara *"compilado em Delphi; não
compilado em FPC — bloqueado por #7"* e CA-8 fica pendente. **Nunca
inventar `.lpi`** (lição do commit rejeitado `06fccea`).

## Cross-check com irmãs

- Pilar 2 (issue #9, [ADR](../cycle-004-e936cbe6/pipeline-adr.md)) já
  entregou `ModernAttributes.GetAttributes`. A fachada
  `ModernRTTI.GetType(T).GetAttributes` (CA-2 do PRD **na letra**) fica
  para issue irmã — não entra aqui.
- Pilar 3 (issue #10, [ADR](../cycle-005-2ef372d9/pipeline-adr.md)) já
  entregou `TModernInvoker`. Não muda.
- Convenções compartilhadas com #7/#9/#10: casca fina, `Test Shared/`
  para cenários, FPCUnit no FPC, sem `{$I ModernSyntax.inc}`, header
  `(* … *)`, número de callbacks/tokens = 415.

## Sub-decisões pendentes do dono (registradas, não bloqueantes)

Repetidas do ADR §"Sub-decisões pendentes do dono":

1. Texto exato da mensagem R4 (rascunho unificado em RN-7).
2. Prefixo `IModern*` vs bare `I*` vs `IMS*` (afeta próxima issue com
   interface, não esta).
3. Portabilidade real de `PropCount == 0` no FPC 3.2.2.
4. Limites de `TValue.AsType<T>` no FPC 3.2.2 para `T` não trivial.

## StructuredOutput deste nó

- `scope: fits`
- `summary`: entrega de desenho do Pilar 1 do ModernRTTI (issue #8):
  unit `Source/ModernSyntax.RTTI.pas` + testes portáveis em três
  diretórios, deriva integral do REPORT do investigate; 4 fatias
  sequenciais e dependentes; sem divergências.
