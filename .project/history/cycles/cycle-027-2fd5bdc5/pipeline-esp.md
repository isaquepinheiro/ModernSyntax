---
type: spec
kind: artifact
title: "ESP #53 — TModernRTTIRecordType.GetFields (tipo + offset, cross-compiler)"
description: "Especificacao formal: entregar GetFields no record retornando tipo e offset dos campos nos dois backends; Name fica fora e vira issue-filha condicionada a FPC >= 3.3."
cycle: "027"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [spec, rtti, fpc, delphi, record, get-fields, modernrtti, issue-53, cycle-027]
---

# ESP #53 — `TModernRTTIRecordType.GetFields`: tipo + offset cross-compiler

## 1. Objetivo

Fechar a lacuna deixada por #45 entregando `TModernRTTIRecordType.GetFields`
com **tipo e offset** de cada campo — cross-compiler, sem `{$IFDEF FPC}` no
cenario, provado nos seis alvos (FPC 3.2.2 i386/x86_64; Delphi 23.0/37.0 x
Win32/Win64). `Name` fica fora deste ciclo e vai para issue-filha
condicionada a FPC >= 3.3 (onde o dado passa a existir).

## 2. Contexto

A medicao feita no corpo da #53 derrubou a premissa do proprio titulo:
`TRecordElement` **nao existe** como API consumivel no FPC 3.2.2
(`typinfo.pp` nao expoe; so aparece em `rtl/inc/rttidecl.inc`, declaracao
interna do compilador). E `TManagedField` (`typinfo.pp:270-283`) carrega
**apenas** `TypeRef` e `FldOffset` — **sem `Name`**. A boa noticia
medida: `GetTypeData(P)^.TotalFieldCount` (campo de `TTypeData` direta,
**NAO** de `RecInitData^`) + caminhada por `PManagedField` imediatamente
apos esse campo enumera **todos** os campos (managed + unmanaged) com tipo
e offset corretos nos dois bitness (medido com
`TRecMisto = record A: Integer; S: string; B: Double; T: string; end` em
FPC 3.2.2 i386 e x86_64: `TypeData.TotalFieldCount = 4`;
`RecInitData^.ManagedFieldCount = 2` — caminho por `RecInitData^`
descartaria A e B em silencio).

Contrato publico decidido pelo Arquiteto neste ciclo (ver ADR D-53.1/D-53.2):
**opcao (c) da issue** — `GetFields` entrega tipo + offset nos dois backends,
sem `Name`. `TModernRTTIRecordField` e **tipo proprio novo** — nao reusa
`TModernRTTIField` porque este e class-bound (exige `TClass` na factory e
`TObject` no `GetValue`/`SetValue`), enganoso para records.

## 3. Escopo

**6 arquivos, 1 slice, 1 commit.**

| # | Arquivo | Mudanca |
|---|---------|---------|
| 1 | `Source/ModernSyntax.RTTI.pas` | Novo `TModernRTTIRecordField` (FieldType, Offset); `TModernRTTIRecordType.GetFields`; XMLDoc atualizado |
| 2 | `Source/ModernSyntax.RTTI.FPC.pas` | `RecordGetFields` livre (interface + implementation) via `GetTypeData(P)^.TotalFieldCount` + caminhada `PManagedField` |
| 3 | `Source/ModernSyntax.RTTI.Delphi.pas` | `RecordGetFields` livre com assinatura identica (D-2) via `TRttiRecordType.GetFields` |
| 4 | `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | Fixture `TRecordFixture53` (mista) + `Scenario_RecordType_GetFields_TipoEOffset` |
| 5 | `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | `published procedure TestRecordType_GetFields_TipoEOffset;` (uma linha, D-7) |
| 6 | `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | `[Test] procedure TestRecordType_GetFields_TipoEOffset;` (uma linha, D-7) |

## 4. Fora do escopo

- **`Name` dos campos.** Impossivel no FPC 3.2.2 (medido). Vira
  issue-filha **enhancement + blocked**, sem `aefos:queue`, condicionada a
  FPC >= 3.3 / trunk. Corpo carrega a medicao desta issue.
- **`GetValue`/`SetValue` sobre `TModernRTTIRecordField`.** Ficam **fora**;
  o novo tipo carrega **apenas** `FieldType` e `Offset`. Se um consumidor
  precisar ler/escrever campo de record, vira issue propria com contrato
  proprio (record nao tem `TObject`; a assinatura precisa mudar).
- **Corrigir comentario de `UScenarios.RTTI.pas:1241-1242`.** Ja consumido
  fora da #53, em commit `e81a5a8` (issue #57 / ciclo 023). O texto atual em
  `:1304-1310` ja esta correto — nao editar.
- **Adicionar citacoes de linha novas a este proprio repo** dentro dos
  arquivos de teste/fixture (classe da #64). Preferir simbolo ou RTL externa.
- **Backport para outras units.** Nada em `Source/*.pas` fora dos tres
  arquivos acima muda.

## 5. Regras de negocio e restricoes

1. **Contrato publico** (D-53.1): `GetFields` cross-compiler entrega
   `TArray<TModernRTTIRecordField>` **sem `Name`**. Semantica identica nos
   dois backends — se o Delphi tem o `Name`, ele **nao e exposto** por esta
   API (segue o principio "menor denominador cross-compiler" ja usado em
   `EnumMinValue` e `EnumMaxValue`).
2. **Tipo proprio** (D-53.2): `TModernRTTIRecordField` e novo tipo, com
   apenas dois membros publicos: `FieldType: PTypeInfo` e
   `Offset: Integer`. NAO reusar `TModernRTTIField`.
3. **Paridade de assinatura entre backends** (D-2 do bundle): as funcoes
   livres `RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>`
   sao **identicas** em nome e assinatura nos dois backends. Compilacao e
   o portao.
4. **Guarda por Kind em cada metodo publico** (D-4): `GetFields` chama
   `RecordRaiseWrongKind(P)` como primeira instrucao no backend. Nao
   duplicar guarda inline.
5. **Fixture mista** (nova convencao deste ciclo — ver ADR D-53.4): UMA
   fixture com PELO MENOS dois tipos distintos, contra padding e ordem.
   `TRecordFixture45`/`TRecordFixture45M` **nao servem** para este cenario:
   sao homogeneas ou tem so dois campos, nao exercitam ordem/tipo.
6. **Assertiva de offset** (D-53.5): comparar `Campo.Offset` contra o
   offset **calculado do proprio record em runtime** —
   `NativeInt(@R.<campo>) - NativeInt(@R)`. NAO literal por bitness, NAO
   `{$IFDEF CPU64}`, NAO `SizeOf` acumulado. CA-5 preservado (zero
   diretiva por compilador em `UScenarios.RTTI.pas`).
7. **Assertiva de tipo** (D-53.6): comparar `Campo.FieldType` por
   IDENTIDADE de handle contra `TypeInfo(<tipo>)`. `BoolToStr` tem
   assinatura diferente entre backends — usar `if...then...else` explicito
   nas mensagens.
8. **Proibicao de `ManagedFldCount`** (D-45.7/D-45.8): o backend FPC usa
   `GetTypeData(P)^.TotalFieldCount` (campo de `TTypeData` direta, **NAO**
   de `RecInitData^`) e caminha por `PManagedField` imediatamente apos esse
   campo. **Q1 fechada** — medido em FPC 3.2.2 i386/x86_64:
   `TypeData.TotalFieldCount = 4` (todos os campos),
   `RecInitData^.ManagedFieldCount = 2` (so os managed, S e T). O caminho
   por `RecInitData^` descartaria A e B em silencio — a armadilha exata
   que esta regra barra.
9. **Ordem dos campos**: assertar EXATAMENTE a ordem declarada na fixture,
   nao apenas contagem/conjunto. Ordem e propriedade observavel do
   contrato.
10. **XMLDoc de `TModernRTTIRecordType`** (`RTTI.pas:722-738`): remover a
    frase "Esta entrega cobre `Name` e `Size` apenas; `GetFields` fica
    para issue propria condicionada a medir `TRecordElement.Name`" — a
    ressalva foi superada. XMLDoc novo diz o que ambos os backends fazem
    apos esta entrega, e cita a issue-filha do `Name` como fronteira
    conhecida (nao como ressalva a ser resolvida algum dia).

## 6. Criterios de aceitacao

- [ ] `Source/ModernSyntax.RTTI.pas` declara `TModernRTTIRecordField` com
  `FieldType: PTypeInfo` e `Offset: Integer` publicos e nada mais.
- [ ] `TModernRTTIRecordType.GetFields: TArray<TModernRTTIRecordField>`
  declarado, delegando a `RecordGetFields` do backend.
- [ ] XMLDoc de `TModernRTTIRecordType` reescrito: sem a frase superada,
  citando a issue-filha do `Name` como fronteira.
- [ ] `Source/ModernSyntax.RTTI.FPC.pas` expoe
  `function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>`
  na interface; implementacao chama `RecordRaiseWrongKind(P)` primeiro,
  le `GetTypeData(P)^.TotalFieldCount` (campo de `TTypeData`, **NAO** de
  `RecInitData^`), caminha por `PManagedField` apos esse campo, e para
  cada campo devolve o par `(MF^.TypeRef, Integer(MF^.FldOffset))`.
- [ ] `Source/ModernSyntax.RTTI.Delphi.pas` expoe a **mesma** assinatura;
  implementacao chama `RecordRaiseWrongKind(P)` primeiro, cria
  `TRttiContext` local com `try/finally .Free`, enumera via
  `TRttiRecordType(LCtx.GetType(P)).GetFields` e devolve
  `(LField.FieldType.Handle, LField.Offset)`. **`LField.Name` nao e
  exposto** — descartado deliberadamente pelo contrato (D-53.1).
- [ ] `Test Shared/EclbrSystem/UScenarios.RTTI.pas` declara
  `TRecordFixture53 = record A: Integer; S: string; B: Double; T: string; end;`
  na secao `type` da interface.
- [ ] `Scenario_RecordType_GetFields_TipoEOffset` implementado:
  - Length = 4;
  - `LFields[0].FieldType = TypeInfo(Integer)` e `Offset = NativeInt(@R.A) - NativeInt(@R)`;
  - `LFields[1].FieldType = TypeInfo(string)` e `Offset = NativeInt(@R.S) - NativeInt(@R)`;
  - `LFields[2].FieldType = TypeInfo(Double)` e `Offset = NativeInt(@R.B) - NativeInt(@R)`;
  - `LFields[3].FieldType = TypeInfo(string)` e `Offset = NativeInt(@R.T) - NativeInt(@R)`.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` acrescenta uma `published
  procedure TestRecordType_GetFields_TipoEOffset;` chamando o cenario
  compartilhado. Contagem FPC sobe de 42 para 43.
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` acrescenta um `[Test]
  procedure TestRecordType_GetFields_TipoEOffset;` chamando o mesmo
  cenario.
- [ ] `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
  retorna zero (CA-5).
- [ ] `grep -c "ManagedFldCount" "Source/ModernSyntax.RTTI.FPC.pas"`
  permanece zero de USO (D-45.7); a mencao existente em comentario
  (`:656-659`) pode ser mantida.
- [ ] Nenhuma citacao NOVA de linha do proprio repo em teste/fixture
  (classe #64). Simbolo ou RTL externa apenas.
- [ ] `Test FPC/EclbrSystem/PTestRTTI.lpr` compila limpo nos dois bitness
  (i386 fica com o autor; x86_64 e provado na fabrica). `--all` passa 43/43.
- [ ] PR body declara: "compilado em FPC 3.2.2 x86_64; i386 e os 4 alvos
  Delphi ficam com o autor."
- [ ] Issue-filha do `Name` aberta separadamente, com labels `enhancement`
  + `blocked`, **sem** `aefos:queue`, corpo carregando a medicao desta
  issue.

## 7. Riscos

| Risco | Prob | Impacto | Mitigacao |
|-------|------|---------|-----------|
| Layout de `TTypeData` / `TManagedField` divergir entre releases do FPC | Baixa | Alto (nao compila) | Q1 fechada: caminhada `PManagedField` confirmada em FPC 3.2.2 i386/x86_64; se nova versao mudar layout, `typinfo.pp` do ambiente e a fonte verdade |
| Consumidor esperar `Name` no retorno de `GetFields` | Baixa | Medio | XMLDoc explicito diz "sem `Name` neste ciclo — issue-filha condicionada a FPC >= 3.3" |
| Ordem de campos divergir entre FPC e Delphi | Baixa | Alto | Fixture mista com quatro campos ordenados; cenario assere ordem exata, nao conjunto |
| Offset por bitness escrito literal no cenario | Media | Alto (falsa segurança) | Regra 6 acima: usar `NativeInt(@R.<campo>) - NativeInt(@R)`; mutacao em constante nao passa em nenhum bitness |
| `TModernRTTIField` reaproveitado por engano | Baixa | Alto | Tipo novo com nome distinto (`TModernRTTIRecordField`) e sem `GetValue`/`SetValue` |
| `TRttiContext` local no Delphi vazar handle | Baixa | Medio | `try/finally .Free` (padrao `RecordTypeName`); a colecao e materializada dentro do bloco |
| `ManagedFldCount` reaparecer em novo codigo | Baixa | Alto | D-45.7/D-45.8 registradas; `grep` do CA fecha o portao |
