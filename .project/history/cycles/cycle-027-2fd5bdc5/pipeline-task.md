---
type: task
kind: artifact
title: "Task #53 — feat(rtti): GetFields de record (tipo + offset cross-compiler)"
description: "Entregar TModernRTTIRecordType.GetFields retornando TArray<TModernRTTIRecordField> (FieldType + Offset) nos dois backends, com fixture mista, cenario compartilhado e cascas finas; Name fica fora."
cycle: "027"
agent: planner
workflow: equipe-feature
node: task
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:task"
  at: "2026-09-03T00:00:00Z"
tags: [task, feature, rtti, fpc, delphi, record, get-fields, issue-53, cycle-027]
---

# Task — Ciclo 027 / Issue #53

## Tracking

- **Modo:** MAESTRO MODE
- **Issue original:** [#53](https://github.com/isaquepinheiro/ModernSyntax/issues/53)
  (demanda criada pelo maestro — `aefos:investigated`)
- **Epic:** nenhum Epic criado (MAESTRO MODE — não criar Epic sem correspondência óbvia pré-existente)
- **Board local:** 🔄 in-pipeline

## Demanda em uma linha

Implementar `TModernRTTIRecordType.GetFields: TArray<TModernRTTIRecordField>` (com
`FieldType: PTypeInfo` e `Offset: Integer`) nos backends FPC e Delphi; fixture mista
`TRecordFixture53`; cenário compartilhado `Scenario_RecordType_GetFields_TipoEOffset`;
casca de uma linha em cada compilador. `Name` fica fora do commit — vira issue-filha.

## Arquivos impactados

| Arquivo | Mudança |
|---------|---------|
| `Source/ModernSyntax.RTTI.pas` | Novo `TModernRTTIRecordField` (FieldType + Offset); `TModernRTTIRecordType.GetFields`; XMLDoc reescrito |
| `Source/ModernSyntax.RTTI.FPC.pas` | `RecordGetFields` livre — via `TTypeData.TotalFieldCount` + `PManagedField` imediatamente após |
| `Source/ModernSyntax.RTTI.Delphi.pas` | `RecordGetFields` livre com mesma assinatura (D-2) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Fixture `TRecordFixture53` + `Scenario_RecordType_GetFields_TipoEOffset`; cabeçalho Issue #45 rebatizado para #45 e #53 |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published procedure TestRecordType_GetFields_TipoEOffset;` (grep -c = 43) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] procedure TestRecordType_GetFields_TipoEOffset;` |

## Pré-condição

**Q1 FECHADA** — `TotalFieldCount` em `TTypeData` direta (**NÃO** em `RecInitData^`).
Array de `TManagedField` fica imediatamente após esse campo na memória. Ver D-53.8 no ADR.

## Checklist de aceitação (síntese)

- [ ] `TModernRTTIRecordField` com `FieldType: PTypeInfo` + `Offset: Integer` — sem `Name`, `GetValue`, `SetValue`
- [ ] `TModernRTTIRecordType.GetFields` delega a `RecordGetFields(FToken)`
- [ ] XMLDoc em `RTTI.pas:722-738` reescrito cobrindo `Name`, `Size`, `GetFields`
- [ ] FPC: `RecordGetFields` lê `TTypeData.TotalFieldCount`, caminha `PManagedField`, zero `ManagedFldCount` no corpo
- [ ] Delphi: `RecordGetFields` com `TRttiContext` local, `try/finally .Free`, sem `LField.Name`
- [ ] Fixture `TRecordFixture53 = record A: Integer; S: string; B: Double; T: string; end;`
- [ ] Assertivas de offset por `NativeInt(@R.campo) - NativeInt(@R)` — sem literal por bitness
- [ ] Assertivas de tipo por identidade (`TypeInfo(tipo)`) — sem `.Name`
- [ ] `grep -c "{\$IFDEF FPC}" UScenarios.RTTI.pas` = 0 (CA-5)
- [ ] FPC 3.2.2 x86_64: `--all` passa 43/43
- [ ] PR declara: "compilado em FPC 3.2.2 x86_64; i386 e 4 alvos Delphi ficam com o autor"
- [ ] Commit único; issue-filha `Name` aberta separadamente com labels `enhancement` + `blocked`

## Traps já pagas

1. `ManagedFldCount` / `RecInitData^` mente para records mistos → usar `TotalFieldCount` em `TTypeData` direta
2. `SizeOf` acumulado como offset → quebra por padding (S mora em offset 8 no x86_64, não 4)
3. `{$IFDEF CPU64}` com literal → quebra CA-5
4. Comparar `.Name` do `PTypeInfo` → Delphi: "Integer", FPC: "LongInt" → usar identidade de handle
5. `BoolToStr` → assinatura divergente FPC vs Delphi → usar `if..then..else` explícito
6. FPC compila green sobre `.ppu` velhos → sempre `rm -rf` o `-FU` antes
7. Reusar `TModernRTTIField` → class-bound → não reusar (D-53.2)

## Referências

- [task-input](pipeline-task-input.md)
- [esp](pipeline-esp.md)
- [adr](pipeline-adr.md) — 12 decisões D-53.1..D-53.12
- Investigação: run `b3a9b3f28bf31199daa9dc3328d95100`, issue #53 comentário
- Antecessora: PR #52 / issue #45 (`Name` + `Size`)
- Convivente: commit `e81a5a8` / issue #57 (não reeditar `:1241-1242`)
