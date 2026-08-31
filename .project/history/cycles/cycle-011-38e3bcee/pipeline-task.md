---
type: task
kind: artifact
title: "Task — feat(rtti): TModernValue.AsType<T> portavel Delphi+FPC (issue #26)"
description: "Implementar TModernValue e TValueOps nos backends, reescrever GetValue<T> via TModernValue, cobrir com 7 cenarios compartilhados + 1 published local FPC para o caso de excecao."
cycle: "011"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernvalue, tvalue, astype, task, issue-26, fpc, delphi, pilar-4, cycle-011]
generated:
  by: "equipe-feature@node:task"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: task-input
    resource: "task-input.md"
    title: "TASK-INPUT — TModernValue.AsType<T> (issue #26)"
  - id: gh-26
    resource: "https://github.com/isaquepinheiro/ModernSyntax/issues/26"
    title: "Issue #26 — TModernValue.AsType<T>"
---

# Task — feat(rtti): TModernValue.AsType<T> portável (issue #26)

## Tracking

**Modo:** MAESTRO MODE — from_maestro: true  
**Issue original:** [#26](https://github.com/isaquepinheiro/ModernSyntax/issues/26) —
*TModernValue.AsType<T>: o membro mais usado do TValue, e o unico ausente no FPC*
(esta issue É a demanda deste ciclo; nenhuma issue ou Epic adicional foi criada).  
**Ciclo:** 011

## Briefing resumido

`TValue.AsType<T>` é o único membro do `TValue` ausente no FPC 3.2.2. Qualquer
consumidor que escreva `LProp.GetValue(LObj).AsType<string>` precisaria ramificar
com `{$IFDEF FPC}` — o que o **CA-5** proíbe.

A solução é `TModernValue` (record na unit pública) + `TValueOps` (record com
`class function AsType<T> ... static` em cada backend):
- **Backend Delphi:** delega diretamente para `TValue.AsType<T>`.
- **Backend FPC:** `IsType(TypeInfo(T))` + `ExtractRawData`, levantando
  `EModernRTTIError` com `SModernValueIncompatibleType` formatada com
  origem e destino quando o tipo não coincidir.

De passagem, `TModernRTTIProperty.GetValue<T>` é reescrito em uma linha via
`TModernValue.FromValue(...).AsType<T>` — fecha o único drift do §7 do API-MAP.
Alargamento de tipos (Integer→Int64, etc.) fica **fora de escopo** — vira issue.

## Arquivos impactados

| Arquivo | Mudança |
|---------|---------|
| `Source/ModernSyntax.RTTI.pas` | Adiciona `TModernValue` na interface; reescreve `GetValue<T>` (remove {$IFDEF FPC} das linhas 385–397) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | Adiciona `TValueOps` — delegacao a `TValue.AsType<T>` |
| `Source/ModernSyntax.RTTI.FPC.pas` | Adiciona `TValueOps` + `resourcestring SModernValueIncompatibleType` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 7 cenarios novos + fixture record/enum; zero `{$IFDEF FPC}` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 8 published (7 delegando + 1 local de excecao) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 7 `[Test]` delegando aos cenarios compartilhados |

### Nao tocar

- `Test FPC/EclbrSystem/PTestRTTI.lpr`, `Test Delphi/EclbrSystem/PTestRTTI.dpr` (runners)
- Arquivos `.lpi`, `.dproj`, `.groupproj`, `DCC.bat`
- `TModernRTTIField.GetValue<T>` — fora de escopo

## Checklist de aceitacao

- [ ] `TModernValue` declarado na `interface` de `Source/ModernSyntax.RTTI.pas`
      com `From<T>`, `FromValue`, `AsType<T>`; estado privado neutro `FValue: TValue`;
      zero `{$IFDEF}` na declaracao publica.
- [ ] XMLDoc de `TModernValue.AsType<T>` declara a divergencia de cobertura
      (alargamento: Delphi suporta, FPC levanta; ver ADR D-6 em [adr](pipeline-adr.md)).
- [ ] Corpo de `TModernValue.AsType<T>` e uma linha:
      `Result := TValueOps.AsType<T>(FValue);` (zero `{$IFDEF}`).
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` declara `TValueOps` com
      `class function AsType<T>(const AValue: TValue): T; static`;
      corpo: `Result := AValue.AsType<T>`.
- [ ] `Source/ModernSyntax.RTTI.FPC.pas` declara `TValueOps` com assinatura identica;
      corpo faz `IsType(TypeInfo(T))` + `ExtractRawData` + raise `EModernRTTIError`
      com `SModernValueIncompatibleType` formatada com origem e destino.
- [ ] Uma unica `resourcestring SModernValueIncompatibleType` no backend FPC.
- [ ] `TModernRTTIProperty.GetValue<T>` reescrito em uma linha via
      `TModernValue.FromValue(...).AsType<T>`; bloco `{$IFDEF FPC}` removido.
- [ ] `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` mostra APENAS a diretiva
      na `uses` da `implementation`.
- [ ] `TModernRTTIField.GetValue<T>` nao e tocado.
- [ ] Sete cenarios em `UScenarios.RTTI.pas`:
      `Scenario_ModernValue_AsType_String`, `_Integer`, `_Boolean`, `_Double`,
      `_Object`, `_Record`, `_Enum`; zero `Assert`; zero `{$IFDEF FPC}` (CA-5).
- [ ] `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` nao aumenta.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas`: 8 published (7 delegando + 1 local
      `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination`).
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`: 7 `[Test]` delegando; sem
      equivalente do teste de excecao local do FPC.
- [ ] `PTestRTTI` compila e passa em x86_64 (fabrica); autor confirma i386 e Delphi 12.
- [ ] Corpo do PR: `Closes #26`.
- [ ] Corpo do PR declara a mutacao: `if not AValue.IsType(TypeInfo(T))` → `if False`
      no backend FPC faz o teste local de excecao falhar.
- [ ] Corpo do PR registra disclaimer sobre `TValueOps` como record com
      `class function ... static` generico no Delphi 12.
- [ ] Corpo do PR registra a proxima issue a abrir (alargamento de tipos).

## Slices de execucao (ver plan.md)

| Slice | Entregavel | Dependencia |
|-------|-----------|-------------|
| S1 | `TModernValue` publico + `TValueOps` backend Delphi | nenhuma |
| S2 | `TValueOps` backend FPC + `resourcestring` + reescrever `GetValue<T>` | S1 |
| S3 | 7 cenarios compartilhados + fixture record/enum em `UScenarios.RTTI.pas` | S2 |
| S4 | 8 published FPC + 7 `[Test]` Delphi + build FPC x86_64 + i386 | S3 |

## Modo de rastreamento

MAESTRO MODE (from_maestro: true). A issue #26 preexiste como intake do maestro
(label `aefos:running`). Nenhuma issue ou Epic adicional criada neste ciclo.
O board de estado esta em [../project-evolution.md](../../../project-evolution.md)
marcado como 🔄 in-pipeline.
