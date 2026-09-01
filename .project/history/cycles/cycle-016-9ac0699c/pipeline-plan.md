---
type: plan
kind: artifact
title: "PLAN — TModernRTTIEnumerationType em 3 slices sequenciais (issue #43)"
description: "Tres slices sequenciais e interdependentes (nao mergeaveis isoladamente): (1) casca publica com TModernRTTIEnumerationType + FromTypeInfo + seis metodos que delegam; (2) backends FPC (seis funcoes livres com guarda por Kind, guards de M-1/M-2, tres resourcestring novas) e Delphi (paridade de assinatura + guards espelhados); (3) quatro cenarios em UScenarios.RTTI.pas + duas cascas de teste + mutacao de sanidade MaxValue-1. Compilacao FPC nos dois bitness fecha o ciclo. Escopo confirmado 'fits' pelo split guard: 6 arquivos, mudancas tightly coupled, nenhum slice deploya sozinho."
status: draft
cycle: "016"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/9ac0699c1b65c18950220f022dfbb179
tags: [modernrtti, plan, issue-43, fpc, delphi, enumeration]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-01T00:00:00Z"
sources:
  - id: esp
    resource: "esp.md"
    title: "ESP — TModernRTTIEnumerationType (issue #43)"
  - id: adr
    resource: "adr.md"
    title: "ADR — TModernRTTIEnumerationType (issue #43)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# PLAN — issue #43 (TModernRTTIEnumerationType)

## Verdict do split guard

**`fits`** — 3 slices tightly coupled em 6 arquivos, nenhum mergeavel
sozinho. Mesma forma da issue #42 (cycle 015). Ver [`esp.md`](pipeline-esp.md)
§2 para o escopo completo e [`adr.md`](pipeline-adr.md) para o racional das
nove decisoes (D-43.1..D-43.9).

- **Test 1 (SIZE):** 6 arquivos, ~250 linhas de mudanca liquida
  estimada, seis funcoes novas por backend + tres `resourcestring`
  novas + quatro cenarios. Um `implement` cobre com folga (bem dentro
  do orcamento $20).
- **Test 2 (INDEPENDENCE):** nao. Slice 1 declara o record com metodos
  que chamam simbolos das slices 2 (backend) — sem elas, a casca nao
  liga. Slice 3 nao afirma nada sem as duas anteriores. Sem corte
  natural em sub-issues.

**Decisao:** `fits`. Continuar neste ciclo.

## Slice 1 — Casca publica: record + fabrica + seis metodos

**Arquivo:** `Source/ModernSyntax.RTTI.pas`.

**O que muda:**

1. Declarar o record na `interface`, **antes de `TModernRTTI` (:561)**:
   ```pascal
   TModernRTTIEnumerationType = record
   strict private
     FToken: PTypeInfo;
   public
     class function FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;
     function Name: string;
     function MinValue: Integer;
     function MaxValue: Integer;
     function GetName(AOrdinal: Integer): string;
     function GetValue(const AName: string): Integer;
     function GetNames: TArray<string>;
   end;
   ```
2. Implementacao no bloco `implementation` (padrao dos demais records):
   `FromTypeInfo` apenas seta `Result.FToken := P`. **Nao** valida
   `Kind` (D-43.1). Cada metodo delega ao backend:
   `Result := EnumName(FToken);`, etc.
3. XMLDoc `///` em cada membro publico:
   - Contrato de erros: `GetName` levanta `EModernRTTIError` para
     ordinal fora de faixa; `GetValue` levanta para nome desconhecido;
     todos os seis levantam para token com `Kind` errado.
   - Ownership: `FToken` e `PTypeInfo` do RTL do compilador; o consumidor
     obtem via `System.TypeInfo(TEnumType)`.

**Estado ao fim da slice:** casca compila **somente** com a slice 2
aterrissada (simbolos `EnumName`, `EnumMinValue`, ... nao existem
ainda). **Nao commitar isoladamente.**

**Convencao verificada:** D-1 (sem `{$IFDEF}` novo em tipo publico).

## Slice 2 — Backends FPC e Delphi

**Arquivos:** `Source/ModernSyntax.RTTI.FPC.pas` e
`Source/ModernSyntax.RTTI.Delphi.pas`.

### FPC (`RTTI.FPC.pas`)

1. **Interface**: novo grupo `// --- Enumeration (issue #43) ---` (apos
   `// --- Properties (issue #42) ---` em :108) com as seis assinaturas:
   ```pascal
   function EnumName(P: PTypeInfo): string;
   function EnumMinValue(P: PTypeInfo): Integer;
   function EnumMaxValue(P: PTypeInfo): Integer;
   function EnumGetName(P: PTypeInfo; AOrdinal: Integer): string;
   function EnumGetValue(P: PTypeInfo; const AName: string): Integer;
   function EnumGetNames(P: PTypeInfo): TArray<string>;
   ```
2. **Bloco `resourcestring` (`:125`)**: adicionar tres constantes novas
   (D-43.5) — `SEnumWrongKind`, `SEnumOrdinalOutOfRange`,
   `SEnumNameUnknown`. Formato e escopo do `%s` conforme ESP §2.2.
3. **Implementation**: novo grupo `// --- Enumeration (issue #43) ---`
   com as seis funcoes. Cada uma abre com guarda por `Kind` (D-4/D-43.2):
   ```pascal
   if (P = nil) or (P^.Kind <> tkEnumeration) then
     raise EModernRTTIError.CreateFmt(SEnumWrongKind, [...]);
   ```
4. **`EnumGetName`**: apos o guard de `Kind`, valida
   `(AOrdinal < GetTypeData(P)^.MinValue) or (AOrdinal >
   GetTypeData(P)^.MaxValue)` e levanta `SEnumOrdinalOutOfRange`
   **antes** de `TypInfo.GetEnumName` (D-43.3, M-1).
5. **`EnumGetValue`**: apos o guard, captura
   `TypInfo.GetEnumValue(P, AName)`; se `= -1` levanta
   `SEnumNameUnknown` (D-43.4, M-2). Caso contrario `Result := <valor>`.
6. **`EnumGetNames`**: apos o guard,
   `for i := GetTypeData(P)^.MinValue to GetTypeData(P)^.MaxValue do
   Result[i - GetTypeData(P)^.MinValue] := TypInfo.GetEnumName(P, i);`
   (M-3 justifica o laco; nao "otimizar").

### Delphi (`RTTI.Delphi.pas`)

1. **Interface**: mesmo grupo `// --- Enumeration (issue #43) ---` (apos
   `// --- Properties (issue #42) ---` em :86) com as **mesmas seis
   assinaturas** (D-2/D-43.6).
2. **Bloco `resourcestring`**: duplicar as tres constantes com o mesmo
   texto do FPC (padrao vigente: cada backend tem seu proprio bloco).
3. **Implementation**: cada funcao **espelha os guards** antes de
   delegar a `TRttiEnumerationType`:
   ```pascal
   function EnumGetName(P: PTypeInfo; AOrdinal: Integer): string;
   var LType: TRttiEnumerationType;
   begin
     if (P = nil) or (P^.Kind <> tkEnumeration) then
       raise EModernRTTIError.CreateFmt(SEnumWrongKind, [...]);
     LType := TRttiEnumerationType(TModernRTTI.FContext.GetType(P));
     if (AOrdinal < LType.MinValue) or (AOrdinal > LType.MaxValue) then
       raise EModernRTTIError.CreateFmt(SEnumOrdinalOutOfRange, [...]);
     Result := GetEnumName(P, AOrdinal);
   end;
   ```
   E analogamente para `EnumGetValue` (captura retorno, `-1` levanta),
   e assim por diante. `EnumName`/`EnumMinValue`/`EnumMaxValue`/`EnumGetNames`
   delegam direto apos o guard.
4. Se nome de metodo em `TRttiEnumerationType` divergir do esperado,
   resolver com `{$IF Declared(...)}` **dentro deste backend** (D-1
   segue honrado).

**Estado ao fim da slice:** casca + backends compilam. Suite existente
nao acusa regressao. Suite nova ainda nao existe.

**Convencao verificada:** D-4 (guarda por `Kind`), D-2 (paridade),
D-26 (M-1/M-2).

## Slice 3 — Cenarios + cascas de teste + mutacao

**Arquivos:** `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`,
`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`.

### `UScenarios.RTTI.pas` (compartilhado, zero `{$IFDEF}` por CA-5)

1. **`uses` da `interface`**: adicionar `TypInfo` (necessario para
   `TypeInfo(TCor)`/`TypeInfo(TDia)` dos cenarios). Verificar antes:
   se ja estiver na `implementation`, mover; se ja estiver na
   `interface`, nada a fazer.
2. **Bloco `type` da `interface`, apos `TColor` (:134)**:
   ```pascal
   TCor = (cA, cB, cC);
   TDia = (dSeg, dTer, dQua, dQui, dSex, dSab, dDom);
   ```
3. **Implementation, apos :997**: quatro procedures compartilhadas:
   - `Scenario_EnumerationType_NameAndBounds` — `TDia`, afirma
     `Name='TDia'`, `MinValue=0`, `MaxValue=6` (M-4 autoriza absoluto).
   - `Scenario_EnumerationType_GetNameGetValue` — `TDia`, roundtrip por
     presenca: `for i := 0 to LEnum.MaxValue do begin LName :=
     LEnum.GetName(i); if LName = '' then Fail(...); if
     LEnum.GetValue(LName) <> i then Fail(...); end;`.
   - `Scenario_EnumerationType_GetNames_LengthAndPresence` — `TDia`,
     afirma `Length(LNames) = 7` e presenca dos 7 nomes esperados.
     **Este e o cenario que a mutacao `MaxValue-1` deve quebrar.**
   - `Scenario_EnumerationType_OutOfRangeAndUnknownRaises` — tres
     afirmacoes **independentes** com `try/except`:
     ```pascal
     try LEnum.GetName(-1); Fail('...'); except on EModernRTTIError do; end;
     try LEnum.GetName(LEnum.MaxValue + 1); Fail('...'); except on EModernRTTIError do; end;
     try LEnum.GetValue('naoExiste'); Fail('...'); except on EModernRTTIError do; end;
     ```

### `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (FPCUnit)

Quatro metodos `published` em `TTestModernRTTI` (padrao `:88–95`), cada
um chamando o cenario correspondente:

```pascal
published
  procedure TestEnumerationType_NameAndBounds;
  procedure TestEnumerationType_GetNameGetValue;
  procedure TestEnumerationType_GetNames_LengthAndPresence;
  procedure TestEnumerationType_OutOfRangeAndUnknownRaises;
```

### `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (DUnitX)

Quatro metodos `[Test]` em `TTestModernRTTI`, mesmos nomes.

### Mutacao de sanidade (D-43.8 / CA-12)

Antes de fechar o PR:

1. `rm -rf /tmp/fpcbuild && fpc ...` (SKILL Trap #2) — suite verde.
2. Em `RTTI.FPC.pas`, trocar em `EnumGetNames`:
   ```pascal
   for i := GetTypeData(P)^.MinValue to GetTypeData(P)^.MaxValue do
   ```
   por
   ```pascal
   for i := GetTypeData(P)^.MinValue to GetTypeData(P)^.MaxValue - 1 do
   ```
3. `rm -rf /tmp/fpcbuild && fpc ...` novamente.
   `Scenario_EnumerationType_GetNames_LengthAndPresence` deve ficar
   **vermelho** (`Length = 6, esperado 7`).
4. Reverter a mutacao, `rm -rf`, recompilar, confirmar verde.
5. Registrar o resultado no PR body (diff + log vermelho + log verde).

**Estado ao fim da slice:** compila FPC nos dois bitness; suite verde;
mutacao documentada.

## Portao de compilacao

Para cada bitness FPC (SKILL §"Compilar o binario de testes"):

```
rm -rf /tmp/fpcbuild && mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" \
    -Fu"Test Shared/EclbrSystem" \
    -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    -o/tmp/fpcbuild/PTestRTTI \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

Trap #2: **sempre `rm -rf`**. Trap #1 nao se aplica — nao compilamos a
arvore inteira.

## Files impactados (resumo)

| Arquivo | Slice | Natureza |
|---------|-------|----------|
| `Source/ModernSyntax.RTTI.pas` | 1 | edicao (record novo + 6 metodos) |
| `Source/ModernSyntax.RTTI.FPC.pas` | 2 | edicao (6 funcoes + 3 resourcestring) |
| `Source/ModernSyntax.RTTI.Delphi.pas` | 2 | edicao (6 funcoes + 3 resourcestring) |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 3 | edicao (TCor + TDia + 4 cenarios + TypInfo em uses) |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 3 | edicao (4 metodos published) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 3 | edicao (4 metodos [Test]) |
