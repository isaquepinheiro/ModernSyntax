---
type: task-input
kind: artifact
title: "Task input — Pilar 1 ModernRTTI: criar Source/ModernSyntax.RTTI.pas e as cascas de teste (issue #8)"
description: "Handoff operacional: Source/ModernSyntax.RTTI.pas (TModernRTTI, TModernRTTIProperty portável; TModernRTTIField Delphi-only em {$IFNDEF FPC}; EModernRTTIError); UScenarios.RTTI.pas (cenários portáveis); cascas DUnitX + FPCUnit; runner Delphi (.dpr/.dproj); PTestRTTI.lpr + .lpi standalone FPC (padrão commit 7114cdc); entradas em groupproj/DCC.bat. Compile FPC antes de entregar."
status: draft
cycle: "006"
agent: architect
workflow: equipe-feature
node: plan-gate:on_reject
resource: aefos://run/0432fa58eb504d5fa522f3e710649a41
tags: [modernrtti, task-input, issue-8, pilar-1, fpc, delphi]
generated:
  by: "equipe-feature@node:plan-gate:on_reject"
  at: "2026-08-28T16:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — Pilar 1"
  - id: adr
    resource: "adr.md"
    title: "ADR — Pilar 1"
  - id: plan
    resource: "plan.md"
    title: "Plan — Pilar 1"
---

# Task Input — Pilar 1 ModernRTTI (issue #8)

## Título

`feat(rtti): implementa Pilar 1 — leitura portável de RTTI
(TModernRTTI, TModernRTTIType, TModernRTTIProperty, TModernRTTIField)`

## Tipo / labels

- `enhancement`
- `pilar-1`
- `modernrtti`
- `fpc`
- `delphi`

## Escopo (arquivos)

### Novos
- `Source/ModernSyntax.RTTI.pas`
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas`
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`
- `Test Delphi/EclbrSystem/PTestRTTI.dpr`
- `Test Delphi/EclbrSystem/PTestRTTI.dproj`
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas`
- `Test FPC/EclbrSystem/PTestRTTI.lpr` — runner FPCUnit (padrão
  `PTestModernCallback.lpr`, commit `7114cdc`).
- `Test FPC/EclbrSystem/PTestRTTI.lpi` — projeto Lazarus (padrão
  `PTestModernCallback.lpi`, commit `7114cdc`; `<SyntaxMode Value="Delphi"/>`
  em `Debug-i386` e `Debug-x86_64`).

### Modificados
- `Test Delphi/EclbrSystem/TestMSGroup.groupproj` — adiciona
  `PTestRTTI.dproj` (13 → 14).
- `Test Delphi/EclbrSystem/DCC.bat` — adiciona `PTestRTTI` (13 → 14).

### **Não** tocar
- `Source/ModernSyntax.inc` — o typo `FCP:256` **não** é consertado
  aqui (R3 do PRD; contorne, não conserte).
- `Source/ModernSyntax.Objects.pas` — não estender `Factory` (D5 do
  PRD; STUDY §C-3: arrasta `SyncObjs`/`Variants`/`Classes`/`TProc<T>`).
- Qualquer outra unit de `Source/` (STUDY §C-4).

## Checklist de aceitação (mapa 1-para-1 com o ESP)

- [ ] **CA-1.** `TModernRTTI.GetType(T).GetProperties` funciona nos dois
      compiladores com a mesma chamada — `Scenario_GetProperties_ReturnsPublishedProps`.
- [ ] **CA-2 (Delphi-only).** No Delphi, `TModernRTTI.GetType(T).GetFields`
      devolve campos de `T` — `[Test] TestGetFields` em
      `Test Delphi/EclbrSystem/UTestMS.RTTI.pas`. No FPC, `TModernRTTIField`
      e `GetFields` **não existem** (ausência por compilação via
      `{$IFNDEF FPC}`). Verificação: `grep -n 'TModernRTTIField\|GetFields'
      Source/ModernSyntax.RTTI.pas` → todas as ocorrências dentro de
      `{$IFNDEF FPC}`.
- [ ] **CA-3.** `GetValue<T>`/`SetValue<T>` cobrindo `Integer`, `string`,
      record simples — `Scenario_GetValue_Integer_Roundtrip`,
      `Scenario_GetValue_String_Roundtrip`,
      `Scenario_GetValue_Record_Roundtrip`.
- [ ] **CA-4.** `EModernRTTIError` levantada quando `{$M+}` está ausente
      no FPC (e quando a classe realmente não tem propriedades expostas
      no Delphi), com a mensagem instrutiva do RN-7 —
      `Scenario_MissingM_RaisesEModernRTTIError`.
- [ ] **CA-5.** `grep -rn '{\$IFDEF FPC}'` nos três arquivos de teste →
      **zero linhas**.
- [ ] **CA-6.** `Source/ModernSyntax.RTTI.pas` não contém
      `{\$I ModernSyntax.inc}` nem o token `FCP`.
- [ ] **CA-7.** A cláusula `uses` da unit nova só cita `SysUtils`,
      `TypInfo`, `Rtti` (grep restrito).
- [ ] **CA-8.** O FPC 3.2.2 constrói `PTestRTTI.lpr` em `i386` **e** `x86_64`
      na máquina do autor. Comando (SKILL.md — LIMPAR output antes de cada
      run):
      ```
      rm -rf <out> && fpc -Mdelphi -Fu"Source" \
          -Fu"Test Shared/EclbrSystem" -FU<out> -FE<out> \
          "Test FPC/EclbrSystem/PTestRTTI.lpr"
      ```
      Não depende do merge da #7.
- [ ] **CA-9.** `PTestRTTI` aparece em `TestMSGroup.groupproj` (agora com
      14 entradas) e em `DCC.bat` (14 projetos).
- [ ] **CA-10.** O corpo do PR declara: *"compilado em FPC 3.2.2 x86_64
      e i386; não compilado em Delphi — Delphi permanece com o autor"*.
- [ ] **CA-11.** Esta issue cria `PTestRTTI.lpr` + `PTestRTTI.lpi` próprios
      e não depende do merge da #7. CA-8 não fica pendente. O PR sempre
      declara resultado real de compilação FPC (não "bloqueado por #7").

## Ordem de execução (do [plan.md](pipeline-plan.md))

1. **F1** — `Source/ModernSyntax.RTTI.pas` skeleton + valores.
2. **F2** — R4: detecção de `{$M+}` ausente + `EModernRTTIError`.
3. **F3** — `UScenarios.RTTI.pas` + casca DUnitX + runner Delphi +
   entradas em `groupproj` / `DCC.bat`.
4. **F4** — casca FPCUnit + `PTestRTTI.lpr` + `PTestRTTI.lpi` standalone.

## Regras estruturais críticas (não negociáveis)

- **Zero `{$I ModernSyntax.inc}`** na unit nova (R3 do PRD; typo em `:261`
  em `main`).
- **Zero `{$mode objfpc}` na unit de produção** (RN-4a do ESP; defeito medido
  no PR #17: derruba `strict private` em records e sobrescreve `-Mdelphi`).
  Se precisar de diretiva de modo explícita: `{$mode delphi}{$H+}`.
- **`TModernRTTIField` e `GetFields` dentro de `{$IFNDEF FPC}…{$ENDIF}`**
  na unit de produção (D12 do ADR; `TRttiField` não existe no FPC 3.2.2).
- **Zero `{$IFDEF FPC}` no consumidor** e nos três arquivos de teste (CA-5
  do PRD). `TestGetFields` no arquivo Delphi não precisa de guard — o tipo
  simplesmente existe no Delphi.
- **Zero units de `Source/` no `uses`** de `ModernSyntax.RTTI.pas`
  (STUDY §C-4).
- **Cabeçalho SPDX-MIT em `(* … *)`** — nunca `{ … }` (RN-11 do ESP;
  defeito medido no PR #12 do ciclo #7).
- **API pública NÃO expõe `TValue` como caminho principal** —
  `GetValue<T>`/`SetValue<T>` genéricos, `TValue` só como overload
  documentado (`/// <remarks>` marcando escape hatch).
- **Contrato de ownership em `<remarks>`** de
  `GetType`/`GetProperties`/`GetFields` — texto integral em RN-9 do ESP.
- **`initialization`/`finalization`** para `class var TModernRTTI.FContext`
  (RN-5).
- **Não** reutilizar `TModernObject.FContext` (D1 do ADR).
- **`PTestRTTI.lpi` com `<SyntaxMode Value="Delphi"/>` em ambos os build
  modes** (D7, D8 do ADR); `.lpr` pode usar `{$MODE OBJFPC}` (apenas
  o programa de entrada).
- **Compilar FPC antes de abrir o PR** — `rm -rf <out>` antes de cada run
  (SKILL.md trap 2). Não compilar `Source/` inteiro (trap 1).

## Riscos declarados (do ESP §6)

- **RSK-1** — mecanismo exato de detecção `PropCount == 0` no FPC 3.2.2
  precisa de confirmação no primeiro build (R2 do PRD). Se exigir
  ramificação, fica dentro da unit.
- **RSK-2** — `TValue.AsType<T>` no FPC 3.2.2 pode falhar para `T` não
  trivial. Fallback: overload `TValue` cru vira o caminho recomendado
  para esses tipos. Decisão do autor no primeiro build.
- **RSK-3** — aviso `experimental` no build da unit e no consumidor do
  overload `TValue`.
- **RSK-4** — build incremental mentiroso no FPC: `.ppu` reusado pode
  mascarar erro real. Mitigação: `rm -rf <out>` obrigatório antes de cada
  build de prova (SKILL.md trap 2). Sem fallback — falhar o clean é engano.
- **RSK-5** — não arrastar dependência transitiva. Grep na cláusula `uses`
  cobre.
- **RSK-6** — prefixo de interface pendente do dono não afeta esta
  entrega (Pilar 1 não introduz interface).

## Referências

- [esp.md](pipeline-esp.md)
- [adr.md](pipeline-adr.md)
- [plan.md](pipeline-plan.md)
- [../strategy/2026-08-27-modernrtti/PRD.md](../../../strategy/2026-08-27-modernrtti/PRD.md)
- [../strategy/2026-08-27-modernrtti/STUDY.md](../../../strategy/2026-08-27-modernrtti/STUDY.md)
- [../analysis/03-architecture.md](../../../analysis/03-architecture.md)
- [../analysis/05-conventions.md](../../../analysis/05-conventions.md)
- [../history/cycles/cycle-004-e936cbe6/pipeline-adr.md](../cycle-004-e936cbe6/pipeline-adr.md)
- [../history/cycles/cycle-005-2ef372d9/pipeline-adr.md](../cycle-005-2ef372d9/pipeline-adr.md)
