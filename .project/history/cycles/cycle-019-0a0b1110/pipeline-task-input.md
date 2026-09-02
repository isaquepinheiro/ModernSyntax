---
type: task-input
kind: artifact
title: "TASK-INPUT — Implementar TModernRTTIArrayType + TModernRTTISetType nos dois compiladores, duas mutacoes obrigatorias com log no PR (issue #46)"
description: "Handoff operacional: dois records novos em ModernSyntax.RTTI.pas (FToken PTypeInfo, FromTypeInfo sem guarda); TModernRTTIArrayType com IsDynamic, ElementType, Size, Length (Length levanta EModernRTTIError em dinamico nos DOIS compiladores); TModernRTTISetType com ElementType. Backend FPC: cinco funcoes livres, tres resourcestrings (texto identico ao Delphi), helper ArrayRaiseWrongKind com guarda combinada [tkArray, tkDynArray] (drift D-46.4), helper SetRaiseWrongKind por tkSet; leituras via properties elType2/ElType/CompType — ZERO leitura de elType2Ref/elTypeRef/CompTypeRef. Backend Delphi: paridade; TRttiDynamicArrayType e TRttiArrayType sao IRMAS (nao descendente) — ramifica por Kind; LCtx local com try/finally onde necessario; ArrayData.Size no estatico, elSize no dinamico; ArrayData.ElCount (nao TotalElementCount) no estatico. Cenarios compartilhados: 7 (TArr5Int46, Length=5), 8 (TDynByteArr46 — Length raises, ElementType.Name por referencia, Size=1 — mata Mutacao 1 e mutacao SizeOf(Pointer) em qualquer bitness), 9 (TDynStrArr46 gerenciado — comentario NAO promete Mutacao 1), 10 (TSetCor46 — mata Mutacao 2). Comparacao de Name sempre por referencia via TModernRTTI.GetType(TypeInfo(...)).Name. +4 publisheds no FPC (37 -> 41), +4 [Test] no Delphi (35 -> 39). Duas mutacoes obrigatorias com log no PR. Checks ancorados a coluna zero para {$IFDEF}."
status: draft
cycle: "019"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/0a0b1110fc1826855542e8d75c65cf65
tags: [modernrtti, task-input, issue-46, fpc, delphi, array, set, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #46"
  - id: adr
    resource: "adr.md"
    title: "ADR — issue #46"
  - id: plan
    resource: "plan.md"
    title: "PLAN — issue #46 em 3 slices"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# TASK-INPUT — issue #46 (TModernRTTIArrayType + TModernRTTISetType)

## Titulo (para commit / PR)

`feat(rtti): TModernRTTIArrayType + TModernRTTISetType nos dois compiladores; Length levanta em dinamico; duas mutacoes obrigatorias (Closes #46, parte de #29)`

## Tipo / labels

- Tipo: `feature`
- Labels sugeridos: `enhancement`, `rtti`, `fpc`, `delphi`
- Milestone / parent: `Parte de #29`
- Fecha: `Closes #46`

## Escopo (o que muda, arquivo por arquivo)

| Arquivo | Natureza | Delta |
|---|---|---|
| `Source/ModernSyntax.RTTI.FPC.pas` | edicao | +5 declaracoes na `interface` (apos bloco Record :129), +3 `resourcestring` (apos `SRecordWrongKind`), +2 helpers (`ArrayRaiseWrongKind`, `SetRaiseWrongKind`) e +5 corpos na `implementation` (apos `RecordTypeSize`, antes de `// --- Context`) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | edicao | +5 declaracoes na `interface` (apos bloco Record :107), +3 `resourcestring` local (texto identico ao FPC), +2 helpers e +5 corpos na `implementation` (`ArrayTypeElementType` e `SetTypeElementType` com `LCtx` local + `try/finally`; demais com leitura direta) |
| `Source/ModernSyntax.RTTI.pas` | edicao | +2 records `TModernRTTIArrayType` e `TModernRTTISetType` (apos `TModernRTTIRecordType` :699-731, antes de `TModernRTTI`); XMLDoc `///` em cada membro; +7 corpos na `implementation` (apos os do `TModernRTTIRecordType` :1195-1214); zero `{$IFDEF}` novo |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | edicao | +4 fixtures publicas (`TArr5Int46`, `TDynByteArr46`, `TDynStrArr46`, `TSetCor46`) apos `TRecordFixture45M` (:218); +4 declaracoes de procedure (apos cenarios #45); +4 implementacoes (`Scenario_ArrayType_Static_LengthAndSize`, `Scenario_ArrayType_Dynamic_LengthRaises`, `Scenario_ArrayType_Dynamic_Managed_ElementType`, `Scenario_SetType_ElementType`) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | edicao | +4 `[Test]` procedures (apos `TestRecordType_NameAndSize` :155), corpo de uma linha cada |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | edicao | +4 `published` procedures (apos `TestRecordType_NameAndSize` :93), corpo de uma linha cada |

**Nenhum arquivo novo. Nenhum arquivo removido.**

## Checklist de aceitacao

- [ ] `TModernRTTIArrayType` declarado apos `TModernRTTIRecordType`
      (:699-731), com `strict private FToken: PTypeInfo`, `FromTypeInfo`,
      `IsDynamic`, `ElementType`, `Size`, `Length` — **e nada mais**.
- [ ] `TModernRTTISetType` declarado logo apos, com `strict private
      FToken: PTypeInfo`, `FromTypeInfo`, `ElementType` — **e nada mais**.
- [ ] XMLDoc `///` do `TModernRTTIArrayType.Length` cita explicitamente:
      *"levanta `EModernRTTIError` (`SArrayDynamicLength`) quando o array
      e dinamico — em ambos os compiladores"*.
- [ ] `FromTypeInfo` **nao** valida `Kind` em nenhum dos dois records
      (D-1/D-43.1/D-44.1/D-45.1). Apenas `Result.FToken := P`.
- [ ] Backend FPC: cinco funcoes livres declaradas na `interface`
      (`ArrayTypeIsDynamic`, `ArrayTypeElementType`, `ArrayTypeSize`,
      `ArrayTypeLength`, `SetTypeElementType`) apos o bloco Record (:129);
      implementadas apos `RecordTypeSize`.
- [ ] Backend FPC: `resourcestring SArrayWrongKind`, `SArrayDynamicLength`,
      `SSetWrongKind` adicionados apos `SRecordWrongKind`. Texto de
      `SArrayDynamicLength`: **`'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.'`** (curto — Q4/D-46.3).
- [ ] Backend FPC: helper `ArrayRaiseWrongKind` com guarda combinada
      `(P = nil) or not (P^.Kind in [tkArray, tkDynArray])`.
- [ ] Backend FPC: helper `SetRaiseWrongKind` com guarda `(P = nil) or
      (P^.Kind <> tkSet)`.
- [ ] Backend FPC: `ArrayTypeIsDynamic` retorna `P^.Kind = tkDynArray`
      apos chamar o helper.
- [ ] Backend FPC: `ArrayTypeElementType` usa `GetTypeData(P)^.elType2`
      no dinamico e `GetTypeData(P)^.ArrayData.ElType` no estatico
      (properties, **nunca** `elType2Ref` ou `elTypeRef`).
- [ ] Backend FPC: `ArrayTypeSize` retorna `GetTypeData(P)^.elSize` no
      dinamico e `GetTypeData(P)^.ArrayData.Size` no estatico.
- [ ] Backend FPC: `ArrayTypeLength` **levanta** `EModernRTTIError` com
      `SArrayDynamicLength` no dinamico; no estatico retorna
      `GetTypeData(P)^.ArrayData.ElCount` (**nao** `TotalElementCount`).
- [ ] Backend FPC: `SetTypeElementType` retorna `GetTypeData(P)^.CompType`
      (property, **nunca** `CompTypeRef`).
- [ ] Backend Delphi: assinaturas espelhadas na `interface` apos o bloco
      Record (:107); `resourcestring` com **texto identico** ao FPC
      (copiar-colar; nao redigitar); helpers com mesmas guardas.
- [ ] Backend Delphi: `ArrayTypeElementType` usa `LCtx: TRttiContext`
      **local** com `try/finally LCtx.Free`. Ramifica por `Kind`:
      dinamico → `TRttiDynamicArrayType(LCtx.GetType(P)).ElementType.Handle`;
      estatico → `TRttiArrayType(LCtx.GetType(P)).ElementType.Handle`.
      **Nao** existe cast comum — sao irmas em `System.Rtti`.
- [ ] Backend Delphi: `ArrayTypeSize` e `ArrayTypeLength` **nao** criam
      `TRttiContext` — leitura direta via `GetTypeData(P)^` (paridade
      objetiva com FPC).
- [ ] Backend Delphi: `SetTypeElementType` usa `LCtx` local com
      `try/finally`; `TRttiSetType(LCtx.GetType(P)).ElementType.Handle`.
- [ ] `UScenarios.RTTI.pas`: quatro fixtures publicas apos
      `TRecordFixture45M`:
      - `TArr5Int46 = array[0..4] of Integer;`
      - **`TDynByteArr46 = array of Byte;`** — **NAO** `TDynIntArr46`; a
        troca por `Byte` foi decidida na volta 2 (D-46.7): `elSize = 1`
        diverge de `SizeOf(Pointer)` nos DOIS bitness.
      - `TDynStrArr46 = array of string;`
      - `TSetCor46 = set of TCor;` (reusa `TCor` de fixtures anteriores).
- [ ] `UScenarios.RTTI.pas`: quatro procedures compartilhadas
      (`Scenario_ArrayType_Static_LengthAndSize`,
      `Scenario_ArrayType_Dynamic_LengthRaises`,
      `Scenario_ArrayType_Dynamic_Managed_ElementType`,
      `Scenario_SetType_ElementType`) com padrao de falha `raise
      ETestScenarioFailed.Create(...)`.
- [ ] Cenario 8 carrega **quatro** asserções: `IsDynamic = True`;
      `Length` levanta `EModernRTTIError`; `ElementType.Name =
      TModernRTTI.GetType(TypeInfo(Byte)).Name`; `Size = 1`. **Nao
      simplificar** para "so raises" — as outras tres matam as mutacoes.
- [ ] Cenario 9 compara `ElementType.Name` por **referencia** a
      `TModernRTTI.GetType(TypeInfo(string)).Name`. Comentario do
      fixture/cenario **NAO** promete cobrir Mutacao 1 (D-46.9).
- [ ] Cenario 10 compara `ElementType.Name` por **referencia** a
      `TModernRTTI.GetType(TypeInfo(TCor)).Name`.
- [ ] Cascas FPC e Delphi cada uma com **quatro** procedures novas
      (`TestArrayType_Static_LengthAndSize`,
      `TestArrayType_Dynamic_LengthRaises`,
      `TestArrayType_Dynamic_Managed_ElementType`,
      `TestSetType_ElementType`), corpo de uma linha cada delegando ao
      cenario compartilhado.
- [ ] **Mutacao 1 verificada** (cenario 8): trocar `elType2` por `elType`
      em `ArrayTypeElementType` do FPC deixa o cenario vermelho/AV.
      **Log copiado ao PR.**
- [ ] **Mutacao 2 verificada** (cenario 10): trocar `CompType` por
      `PTypeInfo(CompTypeRef)` em `SetTypeElementType` do FPC deixa o
      cenario vermelho/AV. **Log copiado ao PR.**
- [ ] **Zero `{$IFDEF}` novo** em `ModernSyntax.RTTI.pas`. Check
      ancorado: `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' Source/ModernSyntax.RTTI.pas` = **1** (hoje 1, tem de continuar 1). **NAO** usar o grep cru (que da 12 por conta de mencoes em comentario).
- [ ] **Zero leitura de refs crus** no backend FPC: `grep -n 'elType2Ref\|elTypeRef\|CompTypeRef' Source/ModernSyntax.RTTI.FPC.pas` = **0** (hoje 0, tem de continuar 0).
- [ ] Zero `{$IFDEF FPC}` em `UScenarios.RTTI.pas` (CA-5).
- [ ] Contagens no PR body: **FPC 37 → 41 publisheds; Delphi 35 → 39
      `[Test]`**. **Nao** afirmar empate absoluto — as duas cascas nao
      empatam no total porque o Delphi hospeda testes que o FPC nao roda.
- [ ] Build FPC 3.2.2 x86_64 e i386 verdes (rodados pelo implementador,
      com `rm -rf /tmp/fpcbuild` antes de cada compilacao).
- [ ] PR body declara: `compiled on FPC 3.2.2 x86_64 e i386; Delphi
      23.0/37.0 x Win32/Win64 compilado pelo Diretor` (nao "assumido");
      fecha `Closes #46`; mantem `Parte de #29`.

## Convencoes obrigatorias

- **CA-4 / D-1 / D-25.1** — nenhum `{$IFDEF}` novo em
  `Source/ModernSyntax.RTTI.pas`. `resourcestring` de guarda vive nos
  backends, nao na unit publica.
- **D-2 / D-43.6** — paridade de assinatura entre backends; texto de
  `SArrayWrongKind`, `SArrayDynamicLength`, `SSetWrongKind` **identico**.
- **D-4** — guarda por `Kind` no ponto de uso. Aqui, dois helpers por
  backend: `ArrayRaiseWrongKind` (guarda combinada — drift D-46.4) e
  `SetRaiseWrongKind` (padrao classico).
- **D-44.5** — `TRttiContext` local; no Delphi com `try/finally .Free`.
  No FPC essa feature nao usa contexto (leitura direta).
- **CA-5** — nenhum `{$IFDEF FPC}` em teste.
- **D-5** — fixture com `TypeInfo()` na secao `type` da `interface` de
  `UScenarios.RTTI.pas`.
- **D-7** — "um cenario, duas cascas". Quatro cenarios novos, quatro
  cascas por lado.
- **Prefixos:** `T` tipo/record, `A` parametros, `L` locais.
- **XMLDoc `///`** em todos os membros publicos novos.
- **`rm -rf /tmp/fpcbuild`** antes de cada compilacao (SKILL trap #2).
- **Nunca `Assert`; nunca `raise Exception` generica.** Usar
  `raise ETestScenarioFailed.Create(...)` em teste;
  `raise EModernRTTIError.Create(...)` em backend.
- **Piso Delphi 23.0** — **nao** adicionar `{$IF CompilerVersion >= ...}`.

## Provaveis pontos de fricao (dicas do arquiteto)

- **Fixture `TDynByteArr46`, nao `TDynIntArr46`, no cenario 8.** Se
  autocompletar sugerir `Integer` "por analogia com #45", ignorar.
  Medicao (volta 2, D-46.7): `elSize(array of Integer) = 4` empata com
  `SizeOf(Pointer) = 4` em i386 — asserção `Size` so mata a mutacao
  `SizeOf(Pointer)` se x86_64 rodar. `Byte` (`elSize = 1`) diverge nos
  dois bitness sozinho. Custo: uma linha no fixture.
- **`TRttiDynamicArrayType` NAO estende `TRttiArrayType` no Delphi.**
  Sao **irmas** em `System.Rtti` (Q1 volta 1). Se voce escrever
  `TRttiArrayType(...)` para o dinamico, nao compila ou compila com AV.
  Ramificar por `Kind` explicitamente — dinamico usa
  `TRttiDynamicArrayType`, estatico usa `TRttiArrayType`.
- **Comparacao de `ElementType.Name` sempre por referencia.**
  `array of string` da `AnsiString` no FPC e `string` no Delphi (Q3
  volta 1). Escreva:
  ```pascal
  if LArr.ElementType.Name <> TModernRTTI.GetType(TypeInfo(string)).Name then
    raise ETestScenarioFailed.Create(...);
  ```
  **Nao** literal `<> 'string'` ou `<> 'AnsiString'`.
- **`Length` no dinamico levanta nos DOIS backends.** Nao "levantar so
  no FPC e devolver algo no Delphi". Paridade semantica e o contrato.
  Consumidor cross-compiler tem que ter comportamento identico.
- **Nao usar `TotalElementCount` no Delphi estatico.** `ArrayData.ElCount`
  ja e o produto de todos os graus (Q2 volta 1). Paridade com FPC
  desempata; o argumento "correto para multidimensional futuro" caiu.
- **Cenario 9 NAO cobre Mutacao 1.** `elType` do gerenciado (`string`)
  nao e nil — trocar `elType2` por `elType` no dinamico faria o cenario
  9 passar VERDE com o codigo errado (volta 1, ponto (a)). O log da
  Mutacao 1 e do **cenario 8** (`TDynByteArr46`). Comentario do fixture
  9 nao pode prometer cobrir a mutacao.
- **Texto `SArrayDynamicLength` curto.** `'TModernRTTIArrayType.Length:
  nao suportado para arrays dinamicos.'` — nao escrever texto longo
  ensinando `System.Length` (Q4 volta 1).
- **Check `{$IFDEF}` ancorado a coluna zero.** `grep -c '{$IFDEF' ...`
  da **12** no main hoje (11 em comentario, 1 real). Use
  `grep -cE '^[[:space:]]*\{\$(IFDEF|IFNDEF)' ...`.
- **Contagens 37 → 41 no FPC, 35 → 39 no Delphi.** Nao repetir "33 → 37"
  da issue: medicao no main de hoje da 37/35 (volta 3). No PR body cite
  as duas contagens explicitamente com a nota de nao-empate.
- **Uma so procedure publicada por cenario.** Quatro cenarios, quatro
  procedures por casca. Nao criar `_Name` e `_Size` separadas.
- **Ordem dos arquivos.** Fazer backends primeiro (slice 1), depois
  casca publica (slice 2), depois testes (slice 3). Ordem inversa
  polui o backend com dependencia de tipo que ainda nao existe.
- **`rm -rf /tmp/fpcbuild` antes de cada `fpc`.** SKILL trap #2.
- **Mutacoes obrigatorias — reverter antes de commitar.** Rodar as duas
  mutacoes localmente, copiar o log da falha para o PR body, e
  **reverter** a alteracao antes de `git add`. Nao commitar codigo
  mutado.

## Fontes

- [esp](pipeline-esp.md) — especificacao formal.
- [adr](pipeline-adr.md) — doze decisoes derivadas do relatorio de investigacao.
- [plan](pipeline-plan.md) — tres slices com codigo de referencia e receita das
  duas mutacoes.
- [/SKILL.md](/SKILL.md) — receita FPC, traps (especialmente #2, sobre
  `.ppu` stale).
- [/analysis/05-conventions.md](/analysis/05-conventions.md) — D-1,
  D-2, D-4, D-25.1, CA-5.
