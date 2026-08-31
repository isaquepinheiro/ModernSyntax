---
type: cycle-report
kind: report
title: "REPORT — developer (cycle 011, issue #26)"
description: "Implementacao das 3 slices do plan: TValueOps nos dois backends, TModernValue publico, GetValue<T> em uma linha, 7 cenarios compartilhados + 1 published local FPC. PTestRTTI verde (17/0/0). Mutacao provada (exit=2)."
cycle: "011"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, cycle-011, issue-26, fpc, delphi, tvalue, astype, developer]
generated:
  by: "equipe-feature@node:implement"
  at: "2026-08-31T00:00:00Z"
---

# REPORT — developer (ciclo 011)

## O que foi feito

Executadas as tres slices do [plan](pipeline-plan.md) num unico commit-set,
seguindo o [adr](pipeline-adr.md) e cumprindo os criterios do
[esp](pipeline-esp.md).

- **Slice 1** — `TValueOps` adicionado nos dois backends
  (`Source/ModernSyntax.RTTI.Delphi.pas` e `Source/ModernSyntax.RTTI.FPC.pas`)
  com a MESMA assinatura publica de `class function AsType<T>(const AValue: TValue): T; static`.
  Delphi: delegacao pura ao nativo. FPC: `IsType(TypeInfo(T))` + `ExtractRawData`
  + raise `EModernRTTIError` nomeando origem e destino via 1 nova resourcestring
  `SModernValueIncompatibleType`.
- **Slice 2** — `TModernValue` adicionado na interface de
  `Source/ModernSyntax.RTTI.pas` com surface minima (`From<T>`, `FromValue`,
  `AsType<T>`) e XMLDoc D-6 declarando a divergencia em voz alta.
  `TModernRTTIProperty.GetValue<T>` reescrito para UMA linha
  (`Result := TModernValue.FromValue(FProp.GetValue(AInstance)).AsType<T>`).
  Bloco `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` das linhas 385–397 removido —
  a unica `{$IFDEF}` fora de comentario na unit publica agora e a diretiva
  da clausula `uses` da `implementation` (linha 376). `TModernRTTIField.GetValue<T>`
  intacto (fora de escopo).
- **Slice 3** — 7 cenarios `Scenario_ModernValue_AsType_*` adicionados a
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas` (String/Integer/Boolean/
  Double/Object/Record/Enum), zero `{$IFDEF}`. `Math` entrou no uses da
  implementation para `SameValue` (Double roundtrip perde precisao
  bit-a-bit passando por Extended). 8 published em
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (7 delegando + 1 LOCAL
  `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination`
  para checar `Pos('TPonto', ...) > 0` e `Pos('AnsiString', ...) > 0`
  na `Message` do `EModernRTTIError`). 7 `[Test]` em
  `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — SEM equivalente ao teste
  de excecao FPC (D-9 do ADR).

Board local avancado: `project-evolution.md` marker do ciclo 011 flipado
de `🔄 in-pipeline` para `🔄 in-review`. Kanban do GitHub nao movido
neste no (o `mirror`/`committer` fazem o move quando o PR abre).

## Validacoes

- `PTestRTTI` — **17 tests / 0 errors / 0 failures / exit=0** em
  `x86_64-linux` na fabrica.
- **Prova de mutacao**: `if not AValue.IsType(TypeInfo(T))` → `if False`
  em `Source/ModernSyntax.RTTI.FPC.pas` → `TestModernValue_AsType_DifferentType_...`
  falha com `EAccessViolation`, runner devolve `exit=2`. Mutacao revertida.
- **Regressao dos runners FPC vizinhos** (nao devem quebrar pela adicao
  do `TValueOps`/`TModernValue`): `PTestAttributes`, `PTestInvoker`,
  `PTestModernCallback` compilam.
- **CA-5**: `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
  = **0** (baseline preservado).
- **§7 do API-MAP**: `grep "\{\$IFDEF" Source/ModernSyntax.RTTI.pas`
  fora de comentarios devolve APENAS a diretiva `{$IFDEF FPC}` na
  clausula `uses` da `implementation` (linha 376).

Detalhes adicionais em [pipeline-implement-report](pipeline-implement-report.md).

## Decisoes tomadas na implementacao

- **D-IMPL-1** — o backend FPC nao pode literalmente ter o corpo mostrado
  no ADR (`raise EModernRTTIError.CreateFmt(SModernValueIncompatibleType, ...)`
  dentro do generico): o FPC 3.2.2 devolve "Global Generic template
  references static symtable". Solucao aplicada: expor
  `class procedure TValueOps.RaiseIncompatible(AOrigin, ADestination: PTypeInfo); static`
  como sibling no mesmo record — assinatura no `interface`, corpo no
  `implementation`. A funcao generica `AsType<T>` chama a nao-generica e
  fica limpa de simbolos estaticos. Nenhuma alteracao das outras decisoes
  do ADR; o consumidor externo nao ve `TValueOps` (so ve `TModernValue`).
- **D-IMPL-2** — `SameValue(...)` obrigatorio para `_Double` (medido: `<>`
  falha por drift Extended→Double). `Math` entrou no uses da
  implementation do shared.
- **D-IMPL-3** — `TValueObj` no shared para o cenario `_Object`; assercao
  dupla: identidade de referencia + estado do objeto.

## Caveats

- **Delphi (dcc32) nao exercitado na fabrica**. Risco R1 do ESP (record
  com `class function ... static` generico) permanece aberto; se falhar,
  o remedio esta no Slice 1 do plan (`TValueOps` vira `class`). Registrar
  literal no corpo do PR.
- **FPC i386 nao exercitado** (fabrica so tem `ppcx64`). O autor confirma.
- **Consoletestrunner exit code** — comportado corretamente
  (`exit=2` sob mutacao); leitura inicial via `tail` deu a impressao de
  `exit=0` por confusao de shell, resolvido com redirecionamento a
  arquivo. Documentado no implement-report.

## Referencias

- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md)
- [plan](pipeline-plan.md)
- [task-input](pipeline-task-input.md)
- [implement-report](pipeline-implement-report.md)
- [REPORT-architect](REPORT-architect.md)
- [REPORT-planner](REPORT-planner.md)
- [SKILL — toolchain e traps](/SKILL.md)
