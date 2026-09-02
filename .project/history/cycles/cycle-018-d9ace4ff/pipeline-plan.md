---
type: plan
kind: artifact
title: "PLAN — TModernRTTIRecordType em 3 slices sequenciais tightly coupled (issue #45)"
description: "Tres slices interdependentes: (1) backends FPC e Delphi com paridade (RecordTypeName, RecordTypeSize, resourcestring SRecordWrongKind, helper RecordRaiseWrongKind; Delphi delega a TRttiRecordType via LCtx local, FPC usa string(P^.Name) + GetTypeData(P)^.RecSize); (2) casca publica em ModernSyntax.RTTI.pas com TModernRTTIRecordType + FromTypeInfo + Name + Size (nada mais), XMLDoc com frase-verbatim do acceptance; (3) duas fixtures obrigatorias (TRecordFixture45 + TRecordFixture45M) + cenario compartilhado com quatro asserções + uma procedure em cada casca. Verdict do split guard: fits (6 arquivos, escopo aditivo mesmo pattern das issues #43/#44, nenhum slice mergeavel isoladamente). Fora do commit: abrir issue-filha para GetFields."
status: draft
cycle: "018"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d9ace4ff9a3af56be91a8f0373cb9475
tags: [modernrtti, plan, issue-45, fpc, delphi, record]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernRTTIRecordType (issue #45)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIRecordType (issue #45)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, traps"
---

# PLAN — issue #45 (TModernRTTIRecordType)

## Verdict do split guard

**`fits`** — 3 slices tightly coupled em 6 arquivos, nenhum mergeavel
sozinho. Mesma forma das issues #43 e #44 (cycle-016 e cycle-017). Ver
[`esp.md`](pipeline-esp.md) §2 para o escopo completo e [`adr.md`](pipeline-adr.md) para o
racional das nove decisoes (D-45.1..D-45.9).

- **Test 1 (SIZE):** 6 arquivos, ~120-130 linhas liquidas estimadas
  (duas funcoes livres + resourcestring + helper por backend = 4
  arquivos backend; +1 record + 3 corpos + XMLDoc na unit publica; +2
  fixtures + 1 cenario + 4 asserções em UScenarios; +1 procedure de
  uma linha por casca). Semelhante a #44 (~110 linhas). Um `implement`
  cobre com folga, estimativa ~30-40% do orçamento $20.
- **Test 2 (INDEPENDENCE):** nao. Slice 2 (casca) declara o record cujo
  metodo chama simbolo declarado na slice 1 (backends). Slice 3
  (fixtures + cenario) afirma sobre comportamento produzido pelas
  slices 1 e 2. Nenhum slice merge sozinho: os backends sem casca nao
  tem chamador publico; a casca sem backend nao liga; o teste sem os
  dois nao tem o que testar.

**Decisao:** `fits`. Continuar neste ciclo.

## Ordem das slices

Slices **estritamente sequenciais**: 1 → 2 → 3.

A ordem `backends → casca → teste` (vez de `casca → backend → teste`
como #44) e uma pequena optimizacao: aqui, cada backend expõe **duas**
funcoes livres (nao uma so como em #44) e o helper de guarda; declarar
os backends primeiro evita o vai-e-vem quando a casca for delegar. Nao
muda contrato, so ordem de escrita.

## Slice 1 — Backends FPC e Delphi com paridade

**Arquivos:** `Source/ModernSyntax.RTTI.FPC.pas`,
`Source/ModernSyntax.RTTI.Delphi.pas`.

### 1.1 Backend FPC (`ModernSyntax.RTTI.FPC.pas`)

1. Na `interface`, apos `PointerTypeReferredType` (:123), declarar:
   ```pascal
   function RecordTypeName(P: PTypeInfo): string;
   function RecordTypeSize(P: PTypeInfo): Integer;
   ```
2. No bloco `resourcestring` (apos `SPointerWrongKind`), adicionar:
   ```pascal
   SRecordWrongKind = 'TModernRTTIRecordType: TypeInfo does not describe a record type (Kind <> tkRecord).';
   ```
   **Texto identico** no backend Delphi (D-2/D-43.6). Ancorar
   verbalmente com "issue #45" no comentario acima do bloco se ja
   houver mesma tabela para #43/#44.
3. Na `implementation`, apos `PointerTypeReferredType` (:586), antes de
   `// --- Context`, adicionar helper e corpos:
   ```pascal
   procedure RecordRaiseWrongKind(P: PTypeInfo);
   begin
     if (P = nil) or (P^.Kind <> tkRecord) then
       raise EModernRTTIError.Create(SRecordWrongKind);
   end;

   function RecordTypeName(P: PTypeInfo): string;
   begin
     RecordRaiseWrongKind(P);
     Result := string(P^.Name);
   end;

   function RecordTypeSize(P: PTypeInfo): Integer;
   begin
     RecordRaiseWrongKind(P);
     Result := GetTypeData(P)^.RecSize;
   end;
   ```
   Guarda **exclusivamente** por nil ou `Kind` — **sem** condicao sobre
   `Size` (`record end` = 0 e valido, D-45.8).

### 1.2 Backend Delphi (`ModernSyntax.RTTI.Delphi.pas`)

1. Na `interface`, apos os pointer helpers (:101), declarar as
   mesmas duas assinaturas (D-2).
2. No bloco `resourcestring` local, adicionar `SRecordWrongKind` com
   **texto identico** ao do FPC.
3. Na `implementation` (apos :481):
   ```pascal
   procedure RecordRaiseWrongKind(P: PTypeInfo);
   begin
     if (P = nil) or (P^.Kind <> tkRecord) then
       raise EModernRTTIError.Create(SRecordWrongKind);
   end;

   function RecordTypeName(P: PTypeInfo): string;
   var
     LCtx: TRttiContext;
   begin
     RecordRaiseWrongKind(P);
     LCtx := TRttiContext.Create;
     try
       Result := TRttiRecordType(LCtx.GetType(P)).Name;
     finally
       LCtx.Free;
     end;
   end;

   function RecordTypeSize(P: PTypeInfo): Integer;
   begin
     RecordRaiseWrongKind(P);
     Result := GetTypeData(P)^.RecSize;
   end;
   ```
   `LCtx` **local** com `try/finally` — nao `FContext` global (padrao
   `EnumMinValue` :364-377). `RecordTypeSize` **nao** cria contexto:
   `GetTypeData(P)^.RecSize` direto (paridade objetiva; mais barato).

**Estado ao fim da slice:** backends compilam entre si; sem casca
publica nem teste, nada chama esses simbolos ainda. Compilar isolado
(`ppcx64` do FPC unidade so, ou build parcial do Delphi) confirma
sintaxe. Rodar suite completa e proibido: ela ainda nao muda.

## Slice 2 — Casca publica `TModernRTTIRecordType`

**Arquivo:** `Source/ModernSyntax.RTTI.pas`.

**O que muda:**

1. Declarar o record na `interface`, apos `TModernRTTIPointerType`
   (:680), antes do `///` de :682:
   ```pascal
   /// <summary>
   ///  Categoria RTTI para <c>tkRecord</c>. Esta entrega cobre `Name` e
   ///  `Size` apenas; `GetFields` fica para issue propria condicionada a
   ///  medir `TRecordElement.Name` num FPC vivo.
   /// </summary>
   TModernRTTIRecordType = record
   strict private
     FToken: PTypeInfo;
   public
     class function FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType; static;
     function Name: string;
     function Size: Integer;
   end;
   ```
   XMLDoc `///` em cada membro publico:
   - `FromTypeInfo`: **nao** valida `Kind` (padrao consagrado; guarda
     vive nos backends, D-45.1).
   - `Name`: identificador do tipo record; levanta `EModernRTTIError`
     para `Kind <> tkRecord`.
   - `Size`: `GetTypeData^.RecSize`; levanta o mesmo erro sob a mesma
     condicao. `record end` com `Size = 0` e valido.
2. Implementacao na `implementation`, apos os metodos de
   `TModernRTTIPointerType` (localizacao analoga a #44 no cycle-017 —
   apos o cluster do pointer type):
   ```pascal
   class function TModernRTTIRecordType.FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType;
   begin
     Result.FToken := P;
   end;

   function TModernRTTIRecordType.Name: string;
   begin
     Result := RecordTypeName(FToken);
   end;

   function TModernRTTIRecordType.Size: Integer;
   begin
     Result := RecordTypeSize(FToken);
   end;
   ```
3. **Zero `{$IFDEF}` novo** — herda o unico condicional que ja seleciona
   backend (`ModernSyntax.RTTI.pas:715-721`). Ver [`adr.md`](pipeline-adr.md)
   §D-45.1.

**Estado ao fim da slice:** unit publica + backends compilam juntos.
Ainda sem teste que chame `TModernRTTIRecordType.FromTypeInfo`.

## Slice 3 — Duas fixtures + cenario compartilhado + cascas

**Arquivos:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`,
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`.

### 3.1 Fixtures publicas em `UScenarios.RTTI.pas`

Na secao `type` da `interface`, apos `PInt44` (~:199):

```pascal
{ Fixtures para issue #45. }
{ (1) Unmanaged: Size = 8 constante nos seis alvos (FPC i386/x86_64,
  Delphi 23.0/37.0 x Win32/Win64) — provada por medicao do relatorio. }
TRecordFixture45 = record
  FieldA, FieldB: Integer;
end;

{ (2) Managed: Size varia 8/16 por bitness (Delphi Win32/FPC i386 = 8;
  Delphi Win64/FPC x86_64 = 16). Bloqueia backend que devolva constante.
  Regra de teste 3: variar a natureza do elemento (unmanaged/managed)
  para nao passar por coincidencia (padrao #29, #44). }
TRecordFixture45M = record
  S: string;
  I: Integer;
end;
```

### 3.2 Uma procedure compartilhada

Declaracao na `interface`, apos os cenarios da issue #44:
```pascal
procedure Scenario_RecordType_NameAndSize;
```

Implementacao na `implementation`, apos o bloco correspondente:
```pascal
procedure Scenario_RecordType_NameAndSize;
var
  LRec, LRecM: TModernRTTIRecordType;
begin
  LRec  := TModernRTTIRecordType.FromTypeInfo(TypeInfo(TRecordFixture45));
  LRecM := TModernRTTIRecordType.FromTypeInfo(TypeInfo(TRecordFixture45M));

  { Quatro asserções — nunca duas. Uma fixture so, com Size = 8
    constante nos seis alvos, e anulada por qualquer backend que devolva
    a constante 8. Ver [adr](pipeline-adr.md) §D-45.4. }
  if LRec.Name  <> 'TRecordFixture45' then
    raise ETestScenarioFailed.Create('Name(TRecordFixture45) inesperado.');
  if LRec.Size  <> SizeOf(TRecordFixture45) then
    raise ETestScenarioFailed.Create('Size(TRecordFixture45) != SizeOf(TRecordFixture45).');
  if LRecM.Name <> 'TRecordFixture45M' then
    raise ETestScenarioFailed.Create('Name(TRecordFixture45M) inesperado.');
  if LRecM.Size <> SizeOf(TRecordFixture45M) then
    raise ETestScenarioFailed.Create('Size(TRecordFixture45M) != SizeOf(TRecordFixture45M).');
end;
```

**So igualdade** — `Size = SizeOf(T)`. `>=` nao prova nada contra
backend constante (`8 >= 8` tambem passa).

### 3.3 Casca Delphi (`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`)

Apos :149, antes do `end;` da classe:
```pascal
[Test] procedure TestRecordType_NameAndSize;
```
Implementacao:
```pascal
procedure TTestMS_RTTI.TestRecordType_NameAndSize;
begin
  Scenario_RecordType_NameAndSize;
end;
```

### 3.4 Casca FPC (`Test FPC/EclbrSystem/UTestMS.RTTI.pas`)

Em `published`, apos :89:
```pascal
procedure TestRecordType_NameAndSize;
```
Implementacao:
```pascal
procedure TTestMS_RTTI.TestRecordType_NameAndSize;
begin
  Scenario_RecordType_NameAndSize;
end;
```

**Estado ao fim da slice:** todos os cenarios verdes nos dois
compiladores e nos dois bitness. Uma unica `[Test]`/`published` por
casca (uma so procedure, quatro asserções internas).

## Ordem e dependencias

Slices **estritamente sequenciais**: 1 → 2 → 3. Nenhuma paralelizacao
util. O runner de teste (`PTestRTTI.lpr` no FPC, `PTestRTTI.dpr` no
Delphi) tem que ser recompilado do zero (SKILL trap #2: `rm -rf` do
outdir antes de compilar; senao FPC reporta verde sobre `.ppu` stale).

## Encerramento

- Build FPC 3.2.2 x86_64 e i386 verdes (obrigatorio; rodados pelo
  implementador).
- Delphi 23.0/37.0 x Win32/Win64: **Diretor mede antes do PR** (nao
  "assumido, confirmar no primeiro build"). PR body cita as medicoes.
- PR unico com `Closes #45` e `Parte de #29`.
- **Fora do commit da entrega:** abrir issue-filha
  *"`TModernRTTIRecordType.GetFields`: medir `TRecordElement.Name` no
  FPC 3.2.2 antes de entregar"* (labels `enhancement`, `rtti`, `fpc`,
  `blocked:medicao`). Descricao carrega o **caveto** vetando
  `ManagedFldCount` como sinal para `tkRecord` puro (ver [`adr.md`](pipeline-adr.md)
  §D-45.7).
