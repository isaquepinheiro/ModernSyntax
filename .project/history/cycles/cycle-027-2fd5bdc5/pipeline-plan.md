---
type: plan
kind: artifact
title: "Plano #53 — GetFields de record (tipo + offset cross-compiler)"
description: "Plano de execucao em um slice coeso: novo tipo publico + backends paritarios + fixture mista + cenario compartilhado + duas cascas de uma linha + XMLDoc + issue-filha do Name."
cycle: "027"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/2fd5bdc50ab343e460eeca5becd7afbf
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [plan, rtti, fpc, delphi, record, get-fields, issue-53, cycle-027]
---

# Plano #53 — `GetFields` de record (tipo + offset cross-compiler)

## Avaliacao de escopo

**`fits`** — uma mudanca coesa, um commit, um PR.

- **TEST 1 (tamanho):** 3 unidades de producao (`RTTI.pas`, `RTTI.FPC.pas`,
  `RTTI.Delphi.pas`) + 1 arquivo de cenarios compartilhado + 2 cascas de
  teste de uma linha cada. Sem novos `resourcestring`. Sem nova
  infraestrutura de token/lifetime (o novo tipo carrega dois campos
  imutaveis; sem contexto RTTI aberto no consumidor). Bem dentro do
  orcamento de um implement tipico.
- **TEST 2 (independencia):** os passos abaixo formam UMA peca de
  trabalho — sem os dois backends, o cenario compartilhado nao compila
  em um dos lados; sem o cenario, os backends nao sao provados; sem o
  XMLDoc, a superficie publica documenta a versao anterior. Nao ha dois
  subconjuntos que sejam cada um mergeavel de forma independente.

**Conclusao:** um slice, um commit, um PR.

## Slice unico — `GetFields` cross-compiler

### Pre-condicao 0 — Q1: FECHADA — caminho correto medido em FPC 3.2.2

Q1 esta **fechada** com medicao verificada em FPC 3.2.2 i386 e x86_64.

`TotalFieldCount` **NAO** vive em `RecInitData^` — vive em `TTypeData`
direta. `TRecInitData` (`typinfo.pp:433-445`) declara apenas `Terminator`,
`Size`, `InitOffsetOp`, `ManagementOp`, `ManagedFieldCount` e o array de
campos MANAGED. Na fixture mista:

```
                              i386   x86_64
TypeData.TotalFieldCount        4       4   <- todos os campos
RecInitData^.ManagedFieldCount  2       2   <- so os managed (S e T)
```

O array de `TManagedField` (com TODOS os campos) fica imediatamente apos
`TotalFieldCount` na memoria do `TTypeData`. O passo 3 usa esse caminho —
ver codigo corrigido abaixo.

O implementador **nao** precisa consultar `typinfo.pp` para Q1. Se a
compilacao levantar erro inesperado, cite no PR body.

### Passo 1 — Novo tipo publico `TModernRTTIRecordField` (D-53.2)

`Source/ModernSyntax.RTTI.pas`, na secao `type` da `interface`, antes de
`TModernRTTIRecordType` (perto de `:722`).

```pascal
/// <summary>
///   Descritor imutavel de um campo de record devolvido por
///   <see cref="TModernRTTIRecordType.GetFields"/>. Carrega tipo e
///   offset — nao carrega `Name` (issue-filha #<NN>, condicionada a
///   FPC >= 3.3). Sem `GetValue`/`SetValue`: record nao tem `TObject`;
///   se um consumidor precisar ler/escrever campo de record via
///   ponteiro, vira issue propria.
/// </summary>
TModernRTTIRecordField = record
strict private
  FFieldType: PTypeInfo;
  FOffset: Integer;
public
  class function Create(AFieldType: PTypeInfo; AOffset: Integer): TModernRTTIRecordField; static;
  property FieldType: PTypeInfo read FFieldType;
  property Offset: Integer read FOffset;
end;
```

Implementacao (`Create` trivial: dois assinments) na secao
`implementation` da propria unit publica — sem `resourcestring`, sem
guarda, sem delegacao a backend (a construcao vem dos backends, que ja
chamam `RecordRaiseWrongKind`).

### Passo 2 — `TModernRTTIRecordType.GetFields` (D-53.1)

Em `Source/ModernSyntax.RTTI.pas`, dentro de `TModernRTTIRecordType`
(`:739-771`), acrescentar entre `Size` e `end`:

```pascal
/// <summary>
///   Enumera os campos do record devolvendo tipo e offset de cada um,
///   na ordem de declaracao. Cross-compiler: mesmo shape nos dois
///   backends. `Name` do campo nao e exposto — vive na issue-filha
///   #<NN>, condicionada a FPC >= 3.3.
/// </summary>
/// <remarks>
///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
///   de `tkRecord` (D-4). No Delphi delega a `TRttiRecordType.GetFields`;
///   no FPC 3.2.2 le `GetTypeData(P)^.TotalFieldCount` e caminha por
///   `PManagedField` (Q1 fechada — ver D-53.8) — nunca `ManagedFldCount`
///   (D-45.7). `record end` (Size = 0) devolve array
///   vazio, valido nos seis alvos.
/// </remarks>
function GetFields: TArray<TModernRTTIRecordField>;
```

Implementacao (delega ao backend):

```pascal
function TModernRTTIRecordType.GetFields: TArray<TModernRTTIRecordField>;
begin
  Result := RecordGetFields(FToken);
end;
```

E reescrever o XMLDoc de bloco em `:722-738` conforme D-53.9 — remover
a frase superada, cobrir os tres metodos publicos, citar a issue-filha
do `Name`.

### Passo 3 — Backend FPC: `RecordGetFields` livre (D-2 / D-4 / D-45.7)

`Source/ModernSyntax.RTTI.FPC.pas`:

**Interface** (`:127-128`, junto das outras assinaturas livres de record):

```pascal
function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>;
```

**Implementation** (apos `RecordTypeSize` em `:662`, antes de
`--- Array ---` em `:664`):

```pascal
function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>;
var
  LTypeData: PTypeData;
  LCount, I: Integer;
  LField: PManagedField;
begin
  // D-4/D-45.5: guarda por Kind aberta primeiro. `record end` valido:
  // TotalFieldCount pode ser 0 e o array vazio e correto.
  RecordRaiseWrongKind(P);
  // Q1 fechada (D-53.8): TotalFieldCount vive em TTypeData direta,
  // NAO em RecInitData^. RecInitData^.ManagedFieldCount = 2/4 na fixture
  // mista — descartaria A e B em silencio.
  LTypeData := GetTypeData(P);
  LCount    := LTypeData^.TotalFieldCount;  // D-45.7: todos os campos
  LField    := PManagedField(PByte(@LTypeData^.TotalFieldCount) + SizeOf(Integer));
  SetLength(Result, LCount);
  for I := 0 to LCount - 1 do
  begin
    Result[I] := TModernRTTIRecordField.Create(LField^.TypeRef, Integer(LField^.FldOffset));
    Inc(LField);
  end;
end;
```

Notas obrigatorias:
- **Sem `ManagedFldCount`** em ponto algum do corpo (D-45.7/D-45.8).
- **Sem `try/finally`**: `TRttiContext` nao e usado neste backend (o dado
  vem direto de `TTypeData` via `PManagedField`). Consistente com
  `RecordTypeName` / `RecordTypeSize` que tambem nao criam contexto.
- **Sem cast dependente de bitness**: `LField^.FldOffset` e do tipo
  nativo da plataforma (`PtrInt`/`SizeInt`); e convertido a `Integer`
  inline na criacao de `TModernRTTIRecordField`. Se um record ultrapassar
  `MaxInt` em offset isso e alarme — nao acontece em record real, e o
  `Integer` preserva o padrao ja usado por `RecSize`.

### Passo 4 — Backend Delphi: `RecordGetFields` livre (D-2)

`Source/ModernSyntax.RTTI.Delphi.pas`:

**Interface** (`:105-106`, junto das outras assinaturas livres de record):

```pascal
function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>;
```

**Implementation** (apos `RecordTypeSize` em `:596`, antes de
`--- Array ---` em `:598`):

```pascal
function RecordGetFields(P: PTypeInfo): TArray<TModernRTTIRecordField>;
var
  LCtx: TRttiContext;
  LType: TRttiRecordType;
  LFields: TArray<TRttiField>;
  I: Integer;
begin
  // D-4: guarda antes de qualquer alocacao ou criacao de contexto.
  RecordRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    LType := TRttiRecordType(LCtx.GetType(P));
    LFields := LType.GetFields;
    SetLength(Result, System.Length(LFields));
    for I := 0 to System.Length(LFields) - 1 do
      // D-53.1: Name existe aqui, MAS NAO E EXPOSTO — contrato cross-compiler.
      Result[I] := TModernRTTIRecordField.Create(
        LFields[I].FieldType.Handle,
        LFields[I].Offset
      );
  finally
    LCtx.Free;
  end;
end;
```

Notas:
- Materializar em `Result` **antes** de sair do `try/finally`: os
  `PTypeInfo` sobrevivem ao `.Free` do contexto (sao ponteiros para o
  RTTI persistente do modulo), mas os `TRttiField` nao — logo a
  iteracao inteira acontece dentro do bloco.
- **Nao** expor `LFields[I].Name` no resultado (D-53.1). Se algum
  reviewer perguntar por que, aponte esta ADR e a issue-filha.

### Passo 5 — Fixture mista + cenario compartilhado (D-53.4 / D-53.5 / D-53.6 / D-53.7)

`Test Shared/EclbrSystem/UScenarios.RTTI.pas`:

**Fixture** — na secao `type` da `interface`, apos `TRecordFixture45M`
(`:216-219`):

```pascal
  // Fixture para issue #53 (TModernRTTIRecordType.GetFields).
  // MISTA por construcao (D-53.4 do ADR): quatro campos, tres tipos
  // distintos, offsets divergentes por bitness em tres das quatro
  // posicoes (medicao no corpo da issue #53):
  //
  //   alvo       A    S    B    T
  //   i386       0    4    8   16
  //   x86_64     0    8   16   24
  //
  // Mata mutacao "backend devolve ordem fixa", "backend nao le padding"
  // e "backend confunde managed com contagem". Reusar TRecordFixture45
  // ou TRecordFixture45M seria homogeneo demais (ver ADR D-53.4).
  TRecordFixture53 = record
    A: Integer;
    S: string;
    B: Double;
    T: string;
  end;
```

**Declaracao da procedure** — apos a declaracao dos cenarios da #45,
perto de `:329`:

```pascal
procedure Scenario_RecordType_GetFields_TipoEOffset;
```

**Implementation** — apos `Scenario_RecordType_NameAndSize`
(`:1322`), dentro da secao `--- Issue #45 —`; rebatizar o cabecalho da
secao para `--- Issue #45 e #53 — TModernRTTIRecordType ---`:

```pascal
procedure Scenario_RecordType_GetFields_TipoEOffset;
var
  LFields: TArray<TModernRTTIRecordField>;
  R: TRecordFixture53;
  LEspA, LEspS, LEspB, LEspT: NativeInt;
begin
  // D-53.5: offset esperado vem do proprio compilador em uso, sobre o
  // proprio record — nao literal por bitness, nao {$IFDEF CPU64}, nao
  // SizeOf acumulado (que quebra por padding: SizeOf(A)=4, mas S em 8
  // no x86_64 — tabela medida no corpo da issue #53).
  LEspA := NativeInt(@R.A) - NativeInt(@R);
  LEspS := NativeInt(@R.S) - NativeInt(@R);
  LEspB := NativeInt(@R.B) - NativeInt(@R);
  LEspT := NativeInt(@R.T) - NativeInt(@R);

  LFields := TModernRTTIRecordType.FromTypeInfo(TypeInfo(TRecordFixture53)).GetFields;

  if System.Length(LFields) <> 4 then
    Fail('GetFields(TRecordFixture53) devolveu contagem inesperada.');

  // D-53.6: identidade de handle contra TypeInfo(<tipo>). NAO comparar
  // .Name do PTypeInfo (Delphi diz "Integer", FPC diz "LongInt" — D-57.3).
  if LFields[0].FieldType <> TypeInfo(Integer) then Fail('Campo 0: tipo <> Integer.');
  if LFields[1].FieldType <> TypeInfo(string)  then Fail('Campo 1: tipo <> string.');
  if LFields[2].FieldType <> TypeInfo(Double)  then Fail('Campo 2: tipo <> Double.');
  if LFields[3].FieldType <> TypeInfo(string)  then Fail('Campo 3: tipo <> string.');

  // D-53.7: ordem posicional exata.
  if LFields[0].Offset <> LEspA then Fail('Campo 0 (A): offset diverge do medido.');
  if LFields[1].Offset <> LEspS then Fail('Campo 1 (S): offset diverge do medido.');
  if LFields[2].Offset <> LEspB then Fail('Campo 2 (B): offset diverge do medido.');
  if LFields[3].Offset <> LEspT then Fail('Campo 3 (T): offset diverge do medido.');
end;
```

Notas obrigatorias:
- **CA-5**: nenhum `{$IFDEF FPC}` neste arquivo. Verificar com
  `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` = 0.
- **Pegadinha `BoolToStr` (D-53.6)**: se precisar montar mensagem
  descrevendo o esperado, use `if ... then ... else` explicito — nao
  `BoolToStr` (assinatura diverge FPC vs Delphi).
- **Sem citacao nova de linha do proprio repo** (classe #64): se um
  comentario descrever origem, cite simbolo ou RTL externa.

### Passo 6 — Cascas de teste de uma linha (D-7 / D-53.11)

`Test FPC/EclbrSystem/UTestMS.RTTI.pas`, apos `:93`:

```pascal
published procedure TestRecordType_GetFields_TipoEOffset;
```

E o corpo, no bloco de implementacao correspondente, com uma unica linha
que chama `Scenario_RecordType_GetFields_TipoEOffset;`.

`Test Delphi/EclbrSystem/UTestMS.RTTI.pas`, apos `:155`:

```pascal
[Test]
procedure TestRecordType_GetFields_TipoEOffset;
```

Idem no corpo — uma linha chamando o cenario compartilhado.

### Passo 7 — Verificacao local (fabrica; x86_64 apenas)

```
rm -rf /tmp/fpcbuild
mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -Fi"Test Shared/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain
```

**Esperado:** 43/43 (a contagem sobe de 42 para 43). `grep -c "procedure
Test" "Test FPC/EclbrSystem/UTestMS.RTTI.pas"` = 43.

i386 e os 4 alvos Delphi ficam com o autor (D-53.12).

### Passo 8 — Issue-filha do `Name`

Abrir issue nova em `isaquepinheiro/ModernSyntax`, titulo sugerido:

> "`TModernRTTIRecordField.Name`: expor quando FPC >= 3.3 tornar
> `TManagedField.Name` (ou equivalente) disponivel"

Labels: `enhancement` + `blocked`. **Sem** `aefos:queue`.

Corpo carrega:
- Referencia a esta #53 e ao PR desta #53 como origem.
- A medicao desta #53 (`TManagedField` em FPC 3.2.2 tem so `TypeRef` +
  `FldOffset`; `TRecordElement` nao existe como API consumivel).
- Criterio de desbloqueio: FPC >= 3.3 / trunk expondo `Name` na
  estrutura de campo de record.
- Nota que a mudanca sera aditiva (novo `Name: string` no
  `TModernRTTIRecordField`); nao quebra clientes existentes.

### Passo 9 — Commit e PR

Um unico commit. Mensagem:

```
feat(rtti): GetFields de record com tipo e offset cross-compiler (#53)

- Novo TModernRTTIRecordField (FieldType + Offset)
- TModernRTTIRecordType.GetFields nos dois backends via TTypeData.TotalFieldCount + PManagedField (FPC) e TRttiRecordType.GetFields (Delphi)
- XMLDoc atualizado; ressalva de #45 removida
- Fixture mista TRecordFixture53 + Scenario_RecordType_GetFields_TipoEOffset (uma casca por compilador)
- Name dos campos fica de fora — issue-filha #<NN> condicionada a FPC >= 3.3
```

PR body carrega frase declarativa: "compilado em FPC 3.2.2 x86_64; i386
e os 4 alvos Delphi ficam com o autor." Cita a linha de
`rtl/inc/typinfo.pp` que confirmou Q1.
