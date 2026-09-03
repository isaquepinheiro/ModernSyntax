---
type: cycle-report
kind: report
title: "Release Report — cycle 029 — TModernInvoker.Invoke dinamico cross-compiler"
description: "Cycle 029 entregou o overload dinamico TValue-based em TModernInvoker com fronteira por alvo, 8 novos cenarios de teste e cascas assimetricas — todos os tres gates de qualidade APROVADOS."
cycle: "029"
agent: release
workflow: equipe-feature
node: closing-record
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:closing-record"
  at: "2026-09-03T00:00:00Z"
tags: [release-report, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, issue-13, cycle-029]
---

# Release Report — Cycle 029

## O que este ciclo entregou

A issue #13 demandava um overload dinâmico de `TModernInvoker` com assinatura
pública idêntica em Delphi e FPC 3.2.2, mecanismo interno divergente por
`{$IFDEF FPC}`, e testes que documentam honestamente a fronteira por alvo.

O ciclo entregou:

- **`Source/ModernSyntax.Invoker.pas`** — novo overload
  `Invoke(AInstance, AName, AArgs, AResultType): TValue` declarado uma única
  vez na interface (sem `{$IFDEF}`). O corpo FPC usa `TObject.MethodAddress` +
  `Rtti.Invoke` livre (`rtti.pp:583`); o corpo Delphi usa
  `TRttiContext.GetType.GetMethod.Invoke`. O cabeçalho da unit foi reescrito:
  três blocos superados foram removidos e a seção FRONTEIRA POR ALVO foi
  acrescentada, explicando as três classes de alvo (Delphi, FPC-Windows,
  FPC-outros). O XMLDoc da declaração pública documenta alcance por compilador
  e a propagação deliberada de `ENotImplemented` nos alvos FPC sem `SystemInvoke`.

- **`Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`** — record fixture
  `TDateAndTag`, quatro novos métodos `published` em `TSubject`, e 8 novos
  `Case_InvokeDynamic_*`. Os 4 cenários de retorno de valor ramificam por alvo
  com `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}` (não por
  compilador — CA-5 preservado): no ramo linux sem `SystemInvoke` assertam
  `ENotImplemented`; no ramo else assertam o valor correto. Os 4 cenários de
  guarda (nil, método não encontrado, público sem `{$M+}`) não precisam ramificar.

- **`Test FPC/EclbrSystem/UTestMS.Invoker.pas`** — 7 novos `published
  procedure InvokeDynamic_*`, totalizando 14 métodos. Registra
  `_PublicWithoutMPlus_RaisesOnFPC`, não `_OKOnDelphi` (assimetria deliberada
  por compilador, documentada em D-13.3).

- **`Test Delphi/EclbrSystem/UTestMS.Invoker.pas`** — 7 novos `[Test]
  procedure InvokeDynamic_*`, totalizando 14 métodos. Registra
  `_PublicWithoutMPlus_OKOnDelphi`, não `_RaisesOnFPC`.

O overload portátil `Invoke<TSignature>` da issue #10 permanece byte-a-byte
inalterado (regressão zero — 7/7 verdes confirmados).

## Work branch

- **Branch:** `aefos/cycle-c26861e9-maestro-repo-isaquepinheiro-modernsyntax`
- **Base:** `main`

## Três vereditos de qualidade

| Gate | Agente | Veredito |
|------|--------|----------|
| Review | quality / review | **APPROVED** — todos os 16 critérios do ESP §6 satisfeitos; sem questões críticas |
| Test | quality / test | **APPROVED** — 14/14 verdes (N:14 E:0 F:0 I:0); CA-5 confirmado (grep `{$IFDEF FPC}` = 0) |
| Verify | quality / verify | **PASSED** — compilação limpa (0 warnings novos); suite 14/14; CA-5 confirmado |

Detalhes completos em [review-report](pipeline-review-report.md),
[test-report](pipeline-test-report.md) e [verify-report](pipeline-verify-report.md).

## Notas de entrega

- FPC 3.2.2 x86_64-linux (fábrica): compilado com 923 linhas, 5 warnings
  (2 `Unit "Rtti" is experimental` esperados; 3 `unreachable code`
  pré-existentes confirmados via stash). Suite 14/14 passou.
- FPC i386 e Delphi Win32/Win64 ficam com o autor (ferramentas ausentes na
  fábrica — documentado em SKILL.md).
- `TypInfo` foi acrescentado ao `uses` além do `Rtti` previsto no plano:
  o FPC 3.2.2 não reexporta `PTypeInfo` de `Rtti`. Decisão registrada no
  implement-report (OBS-1 do review-report).
- O commit hash e a URL do PR não estão neste documento; eles vivem no
  `committer-report.md`, escrito após o commit.
