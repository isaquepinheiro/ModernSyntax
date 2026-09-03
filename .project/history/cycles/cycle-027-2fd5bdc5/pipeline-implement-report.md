---
type: implement-report
kind: artifact
title: "Implement-report #53 — GetFields de record (tipo + offset cross-compiler)"
description: "Novo TModernRTTIRecordField + TModernRTTIRecordType.GetFields nos dois backends; fixture mista TRecordFixture53; cenario compartilhado + cascas finas FPC/Delphi; PTestRTTI 43/43 no FPC 3.2.2 x86_64."
cycle: "027"
agent: developer
workflow: equipe-feature
node: implement
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:implement"
  at: "2026-09-03T00:00:00Z"
tags: [implement-report, rtti, fpc, delphi, record, get-fields, issue-53, cycle-027]
---

# Implement-report #53 — `TModernRTTIRecordType.GetFields`

## Resumo

Aplicadas as sete edicoes de codigo do [plan](pipeline-plan.md) sobre os seis arquivos
listados em [task-input](pipeline-task-input.md), na mesma ordem: novo tipo publico
`TModernRTTIRecordField`, novo membro publico `TModernRTTIRecordType.GetFields`,
funcao livre `RecordGetFields` nos dois backends com assinatura identica,
fixture mista `TRecordFixture53`, cenario compartilhado
`Scenario_RecordType_GetFields_TipoEOffset` e cascas de uma linha por
compilador. Zero `{$IFDEF FPC}` novo em `UScenarios.RTTI.pas` (CA-5 preservado).
XMLDoc de `TModernRTTIRecordType` reescrito — a frase superada "Esta entrega
cobre `Name` e `Size` apenas" foi removida e substituida por documentacao dos
tres membros publicos com nota da issue-filha do `Name`.

## Arquivos modificados

| Arquivo | Mudanca |
|---------|---------|
| `Source/ModernSyntax.RTTI.pas` | Novo `TModernRTTIRecordField` (record com `strict private FFieldType/FOffset` e propriedades read-only `FieldType`/`Offset` + `class function Create`); nova declaracao `TModernRTTIRecordType.GetFields` + implementacao delegando a `RecordGetFields(FToken)`; XMLDoc de bloco de `TModernRTTIRecordType` reescrito para cobrir `Name`, `Size` e `GetFields`, citando a issue-filha do `Name` |
| `Source/ModernSyntax.RTTI.FPC.pas` | Interface acrescenta `function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>;`; implementation chama `RecordRaiseWrongKind(P)` primeiro; le `GetTypeData(P)^.TotalFieldCount` (campo de `TTypeData`, **NAO** `RecInitData^`); caminha por `PManagedField` imediatamente apos esse campo; devolve `TModernRTTIRecordField.Create(LField^.TypeRef, Integer(LField^.FldOffset))` para cada item, incrementando o ponteiro. Zero uso NOVO de `ManagedFldCount` no corpo (mencao em comentario de `RecordTypeSize` permanece intacta). |
| `Source/ModernSyntax.RTTI.Delphi.pas` | Interface acrescenta a **mesma** assinatura (D-2 verifica na compilacao); implementation chama `RecordRaiseWrongKind(P)`, cria `TRttiContext` local, materializa o resultado inteiro dentro do `try/finally .Free`. `LField.Name` **NAO** e exposto no resultado (D-53.1). |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Nova fixture `TRecordFixture53 = record A: Integer; S: string; B: Double; T: string; end;` na secao `type` da `interface`, apos `TRecordFixture45M`; nova declaracao `Scenario_RecordType_GetFields_TipoEOffset` perto do bloco de #45; nova implementacao logo apos `Scenario_RecordType_NameAndSize`; cabecalho `--- Issue #45 —` rebatizado para `--- Issue #45 e #53 — TModernRTTIRecordType ---`. |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published procedure TestRecordType_GetFields_TipoEOffset;` na secao `published` de `TTestModernRTTI` + corpo de uma linha `Scenario_RecordType_GetFields_TipoEOffset;` no bloco de implementacao (`grep -c "procedure Test"` = **43**, subiu de 42). |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] procedure TestRecordType_GetFields_TipoEOffset;` no fixture + corpo de uma linha `Scenario_RecordType_GetFields_TipoEOffset;` no bloco de implementacao. |

## Decisoes tecnicas

- **Zero `{$IFDEF FPC}` novo no cenario compartilhado** (CA-5). O offset
  esperado vem do proprio compilador via `NativeInt(@R.<campo>) - NativeInt(@R)`
  — NAO literal por bitness, NAO `{$IFDEF CPU64}`, NAO `SizeOf` acumulado
  (que quebra por padding: `SizeOf(A) = 4`, mas `S` mora em **8** no x86_64).
- **Assercao de tipo por identidade** contra `TypeInfo(<tipo>)` — NAO por
  `.Name` (Delphi diz `Integer`, FPC diz `LongInt`, D-57.3).
- **Ordem posicional exata** (D-53.7): quatro assercoes de tipo + quatro de
  offset, indexadas de 0 a 3.
- **`RecordGetFields` FPC** le `TotalFieldCount` DIRETO de `TTypeData` (Q1
  fechada — D-53.8). `RecInitData^.ManagedFieldCount` mente para records
  mistos (mede 2 na fixture com 4 campos); caminho descartado pela
  medicao gravada no ADR.
- **`RecordGetFields` Delphi** delega a `TRttiRecordType.GetFields` dentro
  de `try/finally .Free`; os `PTypeInfo` sobrevivem ao `.Free` (RTTI
  persistente do modulo) mas os `TRttiField` NAO — logo a iteracao inteira
  acontece dentro do bloco.
- **`LField.Name` do Delphi NAO e exposto** no resultado (D-53.1) — contrato
  cross-compiler; FPC 3.2.2 nao tem `Name` em `TManagedField`. Vai para a
  issue-filha condicionada a FPC >= 3.3.
- **`TModernRTTIRecordField` sem `GetValue`/`SetValue`** (D-53.2) — record
  nao tem `TObject` e reusar `TModernRTTIField` (class-bound) tornaria
  `GetValue<T>(AInstance: TObject)` enganoso.

## Validacoes executadas

Toolchain do projeto (`.project/SKILL.md` — secao "Toolchain & quality
commands"):

1. `rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild` — pre-condicao obrigatoria
   (trap 2 do SKILL.md: FPC reporta verde sobre `.ppu` velhos).
2. `fpc -Mdelphi -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" -Fi"Test Shared/EclbrSystem" -FU/tmp/fpcbuild -FE/tmp/fpcbuild "Test FPC/EclbrSystem/PTestRTTI.lpr"` — **verde**, `4827 lines compiled, 1.1 sec`.
3. `/tmp/fpcbuild/PTestRTTI --all -a --format=plain` — **43/43** (subiu de 42);
   `TestRTTIType.TestRecordType_GetFields_TipoEOffset` verde.
4. `grep -c "procedure Test" "Test FPC/EclbrSystem/UTestMS.RTTI.pas"` = **43**.

Alvos NAO exercitados na fabrica (D-53.12): FPC 3.2.2 i386 e os 4 alvos
Delphi ficam com o autor. Deve constar no corpo do PR.

## Caveats

- **FPC 3.2.2 emite `Warning: Converting pointers to signed integers may
  result in wrong comparison results and range errors, use an unsigned type
  instead.`** oito vezes em `UScenarios.RTTI.pas:1363-1366` (as quatro
  linhas `NativeInt(@R.X) - NativeInt(@R)` do cenario novo). E a formula
  explicitamente prescrita pelo plano (D-53.5) para nao literalizar
  offset por bitness. Warning permanece; nao promove-se a erro. Considerar
  substituir por `PtrUInt` em uma iteracao futura se o barulho incomodar
  (mudaria o texto do plano em D-53.5).
- Dois `grep -c "{$IFDEF FPC}"` em `UScenarios.RTTI.pas` (linhas 1283 e
  1407) sao COMENTARIOS pre-existentes com a string literal "zero
  {$IFDEF FPC} neste arquivo". Nenhuma diretiva por compilador foi
  introduzida — CA-5 preservado. Se a intencao da checklist for
  `grep -c "^\s*{\$IFDEF FPC}"`, um refinamento no criterio elimina
  o falso positivo.
- Issue-filha do `Name` (passo 8 do plano) NAO foi aberta neste nodo — a
  tarefa `implement` toca apenas codigo/documentacao no repo. A abertura
  fica com o nodo/passo que orquestra `gh` (ou com o autor humano no
  merge). O rastreio esta em [plan](pipeline-plan.md) passo 8.

## Links do bundle

- Especificacao: [esp](pipeline-esp.md)
- Decisoes arquiteturais: [adr](pipeline-adr.md)
- Plano de execucao: [plan](pipeline-plan.md)
- Handoff operacional: [task-input](pipeline-task-input.md)
- Conducao operacional: [/analysis/02-stack.md](/analysis/02-stack.md)
