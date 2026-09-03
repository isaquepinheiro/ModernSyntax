---
type: review-report
kind: artifact
title: "Review Report #13 (cycle 029) — TModernInvoker.Invoke dinamico com fronteira POR ALVO"
description: "Revisao da entrega do cycle 029: overload dinamico TValue-based aprovado — todos os criterios criticos do ESP satisfeitos, CA-5 preservado, 14/14 verdes na fabrica."
cycle: "029"
agent: quality
workflow: equipe-feature
node: review
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:review"
  at: "2026-09-03T00:00:00Z"
tags: [review-report, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, issue-13, cycle-029]
---

# Review Report #13 (cycle 029) — `TModernInvoker.Invoke` dinamico, fronteira POR ALVO

## Sumario

A entrega cobre os 4 arquivos do escopo declarado no [ESP](pipeline-esp.md), segue o
[ADR](pipeline-adr.md) em todos os pontos mensuráveis na fabrica e passa a suite
14/14 na fabrica FPC 3.2.2 x86_64-linux.

**Veredito: APPROVED.**

---

## Checklist — ESP §6 criterios de aceitacao

| # | Criterio | Status | Nota |
|---|----------|--------|------|
| 1 | Declaracao unica de `Invoke(AInstance, AName, AArgs, AResultType): TValue` na interface, **sem `{$IFDEF}`** em torno | ✅ PASS | Linhas 115-117 do Invoker.pas |
| 2 | `uses` da interface inclui `Rtti` | ✅ PASS | `SysUtils, TypInfo, Rtti` — `TypInfo` acrescido para resolver `PTypeInfo` (ver observacoes) |
| 3 | Corpo FPC: guarda nil → `MethodAddress` → guarda nil → monta `LArgs` com Self em [0] → `Rtti.Invoke` qualificado → sem mascarar RTL | ✅ PASS | Linhas 165-187; `Rtti.Invoke(LAddress, LArgs, ccReg, AResultType, False, False)` |
| 4 | Corpo Delphi: guarda nil → `TRttiContext.Create` + `try/finally .Free` → `GetType.GetMethod` → guarda nil → `LMethod.Invoke` DENTRO do `try` | ✅ PASS | Linhas 188-214 |
| 5 | Tres blocos superados do cabecalho removidos; nota nova cobre as duas superficies e fronteira por ALVO | ✅ PASS | Cabecalho reescrito (`(* ... *)`) com secao FRONTEIRA POR ALVO |
| 6 | XMLDoc declara alcance por compilador E fronteira por ALVO: tres linhas (Delphi / FPC-Windows / FPC-outros), cita `SErrInvokeNotImplemented`, `rtti.pp:583`, `packages/rtl-objpas/src/<arch>/invoke.inc` | ✅ PASS | Linhas 71-114 do Invoker.pas |
| 7 | Overload portavel `Invoke<TSignature>` intocado (regressao zero) | ✅ PASS | Linhas 67-69, 122-160; 7/7 verdes confirmados |
| 8 | `Cases.pas`: `TDateAndTag = record Stamp: Integer; Tag: string; end;` | ✅ PASS | Linhas 40-43 |
| 9 | `Cases.pas`: `TSubject` ganha `FStamped` (private) + `GimmeStamp`, `GimmeAngle`, `StampNow`, `Stamped` (published) | ✅ PASS | Linhas 68-76 |
| 10 | `Cases.pas`: `uses` interface inclui `Rtti` | ✅ PASS | Linha 32 |
| 11 | `Cases.pas`: 8 novos `Case_InvokeDynamic_...`; 4 de valor ramificam por ALVO com `{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}`; 4 de guarda NAO ramificam | ✅ PASS | Todos presentes e corretamente estruturados |
| 12 | `Cases.pas`: **zero `{$IFDEF FPC}`** (CA-5) | ✅ PASS | `grep -c "{\$IFDEF FPC}"` = 0 confirmado |
| 13 | Casca FPC: 7 novos `published procedure InvokeDynamic_...;` (14 total); registra `_RaisesOnFPC`, NAO `_OKOnDelphi` | ✅ PASS | Linhas 40-46 + implementacoes |
| 14 | Casca Delphi: 7 novos `[Test] procedure InvokeDynamic_...;` (14 total); registra `_OKOnDelphi`, NAO `_RaisesOnFPC` | ✅ PASS | Linhas 45-57 + implementacoes |
| 15 | FPC 3.2.2 x86_64-linux: compilacao limpa + suite **14/14** verde | ✅ PASS | `N:14 E:0 F:0 I:0`; 4 cenarios de valor passam asserindo `ENotImplemented` |
| 16 | Sem warnings novos alem de `Unit "Rtti" is experimental` | ✅ PASS | 2 novos "Rtti is experimental" (esperados); 3 "unreachable code" sao pre-existentes (baseline medido via `git stash`) |

---

## Questoes criticas

Nenhuma. Todos os criterios do ESP §6 sao satisfeitos.

---

## Observacoes nao-bloqueantes

### OBS-1 — `TypInfo` no `uses` (nao previsto no plano)

O plano indicava `uses SysUtils, Rtti;`. O FPC 3.2.2 nao reexporta
`PTypeInfo` de `Rtti`, obrigando adicionar `TypInfo`. A decisao esta
documentada no [implement-report](pipeline-implement-report.md) §"Decisoes tecnicas".
Correto e necessario; zero impacto no Delphi.

### OBS-2 — ESP §6 vs ADR D-29.2: guard `defined(FPC)` ausente no ESP

O criterio de aceitacao do ESP §6 escreve:
`{$IF defined(CPUX86_64) and defined(UNIX)}` (sem `defined(FPC)`).
O ADR D-29.2 adiciona `defined(FPC)` para excluir Delphi Linux (LSB).
A implementacao segue o ADR — que e correto. O texto do ESP tem omissao
tipografica. Nao bloqueante; o ADR e a fonte de autoridade para decisoes.

### OBS-3 — Notes "Local variable 'v' is assigned but never used" (3x)

Tres `Note:` do FPC (nao warnings) refletem que `v` e declarado no bloco
`{$ELSE}` (ramo de valor) mas nunca alcancado no alvo da fabrica (RTL levanta
antes). Intencional e documentado no [implement-report](pipeline-implement-report.md).
Silenciar via `{$PUSH/$POP}` nao e justificado — a estrutura deve permanecer
legivel para quando o alvo Windows/i386 entrar no ramo correto.

### OBS-4 — `v` declarado no ramo FPC-linux em `ProcedureVoid_SideEffect`

Este cenario NAO declara `v: TValue` no ramo FPC-linux — correto, pois e
procedimento void. Consistente com a especificacao.

### OBS-5 — `StampNow(6)` → `Stamped = 42`

Aritmetica: `6 * 7 = 42`. O fixture e determinista. OK.

---

## Scope

Mudancas revisadas:
- `Source/ModernSyntax.Invoker.pas` (modificado, rastreado)
- `Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas` (modificado, rastreado)
- `Test FPC/EclbrSystem/UTestMS.Invoker.pas` (modificado, rastreado)
- `Test Delphi/EclbrSystem/UTestMS.Invoker.pas` (modificado, rastreado)
- `.project/project-evolution.md` (modificado, rastreado — linha 40 `in-pipeline` → `in-review`)

Arquivos nao rastreados no escopo desta entrega:
- `.project/history/cycles/cycle-029-c26861e9/` — artefatos de pipeline do ciclo
- `.project/pipeline/` — workspace do pipeline

Nada fora do escopo declarado no ESP §3.

---

## Links

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [implement-report](pipeline-implement-report.md)
- [task-input](pipeline-task-input.md)
