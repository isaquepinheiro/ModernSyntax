---
type: cycle-report
kind: report
title: "REPORT-developer — issue #25 implementation cycle 010"
description: "Split de backends RTTI implementado, TModernRTTIMethod/Parameter portáveis, cirurgia do Fail fechando #35, 9/9 testes FPC x86_64 verdes e M1 provada por mutação (exit=2)."
cycle: "010"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/a36e13649de2fc026303074567d63275
tags: [modernrtti, developer, issue-25, cycle-010, fpc, delphi]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
---

# REPORT-developer — cycle 010 (issue #25)

## Sumário

Implementei as quatro slices do [plan](pipeline-plan.md) em um único
commit-set:

1. **Slice 1** — split arquitetural §7 do API-MAP aplicado ao
   `Source/ModernSyntax.RTTI.pas`. `TModernRTTIField` migrado para
   campos neutros (`FOwner`/`FName`/`FToken: Pointer`) + `FromToken`.
   Novos backends `ModernSyntax.RTTI.Delphi.pas` e
   `ModernSyntax.RTTI.FPC.pas`. Único `{$IFDEF}` da unit pública mora
   na `uses` da `implementation`.
2. **Slice 2** — `TModernRTTIMethod` (oito membros) e
   `TModernRTTIParameter` (dois membros) compilam nos dois lados.
   FPC: enumeração pela `vmtMethodTable` com `LTab^.Entry[i]` (sem
   aritmética literal, D-25.2); lookup por `MethodAddress` (sem laço
   próprio, D-25.3); seis membros sem fonte levantam `EModernRTTIError`
   (D-25.4). Delphi: envolve `TRttiMethod`/`TRttiParameter` direto.
   `Invoke<TSignature>` delega a `TModernInvoker` (D-25.9).
3. **Slice 3** — cirurgia do `Fail` em `UScenarios.RTTI.pas`:
   `ETestScenarioFailed = class(Exception)` declarada, `Fail` levanta
   essa classe. **Closes #35** — provado por mutação (§Validações).
4. **Slice 4** — fixture com herança `TMethodBase`/`TMethodDerived`
   (só published, D-25.5), três cenários compartilhados
   (`_Exact`/`_ByName`/`_Invoke_NoArgs`), três published tests em cada
   runner + XMLDoc stale do Delphi runner corrigido.

## Artefatos entregues

- **Código de produção:** `Source/ModernSyntax.RTTI.pas` (refactor),
  `Source/ModernSyntax.RTTI.FPC.pas` (NOVO), `Source/ModernSyntax.RTTI.Delphi.pas` (NOVO).
- **Testes compartilhados:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas`
  (ETestScenarioFailed, fixture, 3 cenários).
- **Runners:** `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (3 published tests),
  `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (3 `[Test]` + fix comentário).
- **Board:** `.project/project-evolution.md` avançado para 🔄 in-review.
- **Traceability:** [pipeline-implement-report](pipeline-implement-report.md).

## Validações executadas

- **Build FPC 3.2.2 x86_64:** 1589 linhas, 0.2 sec, 4 warnings conhecidos
  (2× "Rtti experimental" herdados, 1× false-positive de "managed type
  not initialized" em `GetMethod` que sempre levanta, 1× pré-existente
  em `Invoker.pas:80` não tocado).
- **Testes FPC x86_64:** 9/9 verdes, exit=0 (6 pré-existentes + 3 novos).
- **Mutação M1** (desligar `ClassParent` em `MethodEnumerate`):
  `TestGetMethods_CountsPublishedInherited_Exact` falha com exception
  `ETestScenarioFailed`, exit=2 — **confirma M1 pega a regressão E
  fecha #35 (exit != 0 sobre vermelho)**.
- **i386, Delphi, M2:** ficam com o autor (fábrica não tem `ppc386` nem
  `dcc32`, SKILL.md:16-27, 122-124). Devem ser declarados no corpo do PR.

## Decisão estrutural forçada pelo compilador

`TModernRTTIType.GetMethods`/`GetMethod` foram para o record helper
`TModernRTTITypeHelper` — records Pascal não admitem forward-declaração
entre si, e a mútua referência
`Method.ReturnType ↔ Type.GetMethods` bateu como
`Identifier not found "TModernRTTIMethod"` na primeira compilação. O
helper (declarado após `TModernRTTIMethod`) é o ajuste limpo; consumidor
externo chama `AType.GetMethods` normalmente. Detalhado em
[pipeline-implement-report](pipeline-implement-report.md#nota-estrutural--record-helper-para-tmodernrttitype).

## Handoff

O código está pronto para review + test + verify. A prova de mutação M1
já está fixada por cenário. Autor deve rodar em i386 + Delphi + M2 e
declarar no corpo do PR (SKILL.md:92-97 — "silêncio não é sucesso").

## Referências

- [pipeline-esp](pipeline-esp.md)
- [pipeline-adr](pipeline-adr.md)
- [pipeline-plan](pipeline-plan.md)
- [pipeline-task-input](pipeline-task-input.md)
- [pipeline-implement-report](pipeline-implement-report.md)
- [REPORT-architect](REPORT-architect.md)
- [REPORT-planner](REPORT-planner.md)
