---
type: task-input
kind: artifact
title: "Task-input #53 — GetFields de record (tipo + offset cross-compiler)"
description: "Handoff operacional para o implementador: novo TModernRTTIRecordField + GetFields nos dois backends + fixture mista + cenario compartilhado + duas cascas de uma linha, um commit, um PR."
cycle: "027"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [task-input, rtti, fpc, delphi, record, get-fields, issue-53, cycle-027]
---

# Task-input #53 — `TModernRTTIRecordType.GetFields`

## Titulo

feat(rtti): GetFields de record com tipo e offset cross-compiler (#53)

## Tipo / labels

- `feature`
- `rtti`
- `fpc`
- `delphi`
- `modernrtti`

## Escopo em uma linha

Entregar `TModernRTTIRecordType.GetFields` retornando
`TArray<TModernRTTIRecordField>` (tipo + offset) nos dois backends, com
fixture mista, cenario compartilhado e uma casca de teste por
compilador; `Name` fica fora e vira issue-filha.

## Arquivos impactados

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.RTTI.pas` | Novo `TModernRTTIRecordField`; `TModernRTTIRecordType.GetFields`; XMLDoc reescrito |
| `Source/ModernSyntax.RTTI.FPC.pas` | `RecordGetFields` livre (interface + implementation) — via `TTypeData.TotalFieldCount` + `PManagedField` |
| `Source/ModernSyntax.RTTI.Delphi.pas` | `RecordGetFields` livre com assinatura identica (D-2) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Fixture `TRecordFixture53` + cenario `Scenario_RecordType_GetFields_TipoEOffset` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published procedure TestRecordType_GetFields_TipoEOffset;` (uma linha) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] procedure TestRecordType_GetFields_TipoEOffset;` (uma linha) |

## Pre-condicao — Q1 FECHADA

**Q1 fechada** — caminhada correta verificada em FPC 3.2.2 i386 e x86_64.
`TotalFieldCount` vive em `TTypeData` direta (**NAO** em `RecInitData^`).
O array de `TManagedField` (todos os campos) fica imediatamente apos esse
campo na memoria. Ver D-53.8 no `adr.md` para a medicao completa e o
trecho de codigo correto.

O implementador nao precisa consultar `typinfo.pp` para Q1. Se a
compilacao levantar erro inesperado, cite no PR body.

## Checklist de aceitacao

- [ ] `Source/ModernSyntax.RTTI.pas` declara `TModernRTTIRecordField`
      com `FieldType: PTypeInfo` + `Offset: Integer` publicos, e
      **nada mais** — sem `Name`, sem `GetValue`, sem `SetValue`.
- [ ] `TModernRTTIRecordType.GetFields: TArray<TModernRTTIRecordField>`
      declarado e implementado como delegacao a
      `RecordGetFields(FToken)`.
- [ ] XMLDoc de `TModernRTTIRecordType` (`RTTI.pas:722-738`) reescrito:
      cobre `Name`, `Size` e `GetFields`; cita issue-filha do `Name`;
      **sem** a frase superada "Esta entrega cobre `Name` e `Size`
      apenas".
- [ ] `Source/ModernSyntax.RTTI.FPC.pas`:
  - interface acrescenta
    `function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>;`
  - implementacao chama `RecordRaiseWrongKind(P)` primeiro; le
    `GetTypeData(P)^.TotalFieldCount` (campo de `TTypeData`, **NAO**
    `RecInitData^`); caminha por `PManagedField` imediatamente apos esse
    campo; devolve `TModernRTTIRecordField.Create(LField^.TypeRef, Integer(LField^.FldOffset))`
    para cada item, incrementando o ponteiro.
  - **zero uso de `ManagedFldCount`** no corpo (D-45.7); a mencao em
    comentario (`:656-659`) pode ficar.
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas`:
  - interface acrescenta a **mesma** assinatura (D-2 verifica na
    compilacao).
  - implementacao chama `RecordRaiseWrongKind(P)`, cria `TRttiContext`
    local, materializa o resultado inteiro dentro do `try/finally .Free`.
  - `LField.Name` **NAO** e exposto no resultado (D-53.1).
- [ ] `Test Shared/EclbrSystem/UScenarios.RTTI.pas`:
  - `TRecordFixture53 = record A: Integer; S: string; B: Double; T: string; end;`
    na secao `type` da interface, apos `TRecordFixture45M`.
  - `procedure Scenario_RecordType_GetFields_TipoEOffset;` declarada
    na interface perto de `:329` e implementada logo apos
    `Scenario_RecordType_NameAndSize`.
  - Cabecalho da secao `--- Issue #45 —` (`:1295`) rebatizado para
    `--- Issue #45 e #53 — TModernRTTIRecordType ---`.
  - Assertivas de offset via `NativeInt(@R.<campo>) - NativeInt(@R)` —
    **NAO** literal por bitness, **NAO** `{$IFDEF CPU64}`, **NAO**
    `SizeOf` acumulado.
  - Assertivas de tipo por **identidade** contra `TypeInfo(<tipo>)` —
    **NAO** por `.Name`.
  - Ordem posicional **exata** dos quatro campos (nao apenas contagem/
    conjunto).
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` acrescenta
      `published procedure TestRecordType_GetFields_TipoEOffset;` e
      corpo de uma linha; `grep -c "procedure Test"` = **43**
      (subiu de 42).
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` acrescenta
      `[Test] procedure TestRecordType_GetFields_TipoEOffset;` e
      corpo de uma linha.
- [ ] `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      retorna 0 (CA-5).
- [ ] Nenhuma citacao NOVA de linha do proprio repo em teste/fixture
      (classe #64). Simbolo ou RTL externa somente.
- [ ] **NAO** editar `UScenarios.RTTI.pas:1241-1242` — ja consumido por
      commit `e81a5a8` (issue #57).
- [ ] `PTestRTTI` compila limpo no FPC 3.2.2 x86_64; `--all` passa 43/43.
- [ ] i386 e os 4 alvos Delphi: **nao** verificados na fabrica; ficam
      com o autor (D-53.12).
- [ ] PR body declara: "compilado em FPC 3.2.2 x86_64; i386 e os 4 alvos
      Delphi ficam com o autor". (Q1 fechada no ADR — nao e necessario
      citar `typinfo.pp` novamente.)
- [ ] Commit unico; mensagem no formato do plano.
- [ ] Issue-filha do `Name` aberta separadamente, labels `enhancement` +
      `blocked`, **sem** `aefos:queue`; corpo carrega a medicao desta
      #53.

## Traps ja pagas (nao repetir)

1. **`ManagedFldCount` / `RecInitData^` mente para records mistos** —
   `RecInitData^.ManagedFieldCount` devolve 2 quando o record tem 4
   campos (medido: fixture mista i386/x86_64, S e T sao os managed).
   `TotalFieldCount` vive em `TTypeData` direta, **NAO** em `RecInitData^`
   (Q1 fechada — ver D-53.8 no `adr.md`). Caminho por `RecInitData^`
   descarta A e B em silencio.
2. **`SizeOf` acumulado como esperado de offset** — quebra por padding.
   `SizeOf(A) = 4`, mas `S` mora em **8** no x86_64. Tabela medida no
   corpo da issue.
3. **Literal por bitness com `{$IFDEF CPU64}`** — quebra CA-5 e mantem
   um alvo desligado sempre.
4. **Comparar `.Name` do `PTypeInfo`** — Delphi diz `Integer`, FPC diz
   `LongInt` (D-57.3). Use identidade de handle.
5. **`BoolToStr`** — assinatura divergente FPC vs Delphi
   (`E2010 Incompatible types` no Delphi). Use `if..then..else`
   explicito.
6. **FPC compila green sobre `.ppu` velhos** — sempre `rm -rf` o `-FU`
   antes de compilar (SKILL.md, trap 2).
7. **Reusar `TModernRTTIField`** — class-bound; `GetValue<T>(AInstance:
   TObject)` vira enganoso. **NAO reusar** (D-53.2).

## Contexto de referencia

- ESP: `esp.md` (irmao neste diretorio).
- ADR: `adr.md` (irmao neste diretorio) — 12 decisoes (D-53.1..D-53.12).
- Investigacao: run `b3a9b3f28bf31199daa9dc3328d95100`, comentario na
  issue #53 (o `investigation` node ja o leu; ESP/ADR/plano derivam).
- Antecessora: PR #52 / issue #45 (entrega de `Name` + `Size`).
- Convivente: commit `e81a5a8` / issue #57 (consumiu o item "corrigir
  comentario de `:1241-1242`" desta issue — nao reeditar).
- Toolchain: `.project/SKILL.md`.
