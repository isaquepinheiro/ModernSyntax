---
type: plan
kind: artifact
title: "Plano #13 (cycle 029) — TModernInvoker.Invoke dinamico com testes ramificando POR ALVO"
description: "Plano de execucao em um unico slice: novo overload TValue-based no TModernInvoker, backends divergentes por IFDEF, XMLDoc por alvo, cenarios de retorno de valor ramificando por alvo com {$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}, cabecalho da unit reescrito, um commit."
cycle: "029"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/c26861e980aa5045a4f8b7de8b2207c2
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [plan, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, per-target, systeminvoke, issue-13, cycle-029]
---

# Plano #13 (cycle 029) — `TModernInvoker.Invoke` dinamico, fronteira POR ALVO

## Avaliacao de escopo

**`fits`** — uma mudanca coesa, um commit, um PR.

- **TEST 1 (tamanho):** 1 unit de producao (`ModernSyntax.Invoker.pas`) +
  1 arquivo de cenarios compartilhado + 2 cascas de teste. Sem novo
  `resourcestring`, sem nova infraestrutura. Bem dentro do orcamento de um
  implement tipico (~$10-15). O ciclo 028 mediu `21 lines compiled, 0.2 sec`
  para uma implementacao equivalente — o delta deste ciclo (testes ramificam
  por alvo, XMLDoc por alvo) e ainda menor.
- **TEST 2 (independencia):** os passos abaixo formam UMA peca de trabalho —
  sem os dois backends, o cenario compartilhado nao roda em um dos lados;
  sem a ramificacao por alvo nos cenarios de valor, a fabrica levanta
  `ENotImplemented` como falha (e nao como assertiva verde); sem reescrever
  o cabecalho, a unit mergeia com afirmacao superada (padrao #62, D-53.9).
  Nao ha subconjunto mergeavel de forma independente.

**Conclusao:** um slice, um commit, um PR.

## Slice unico — Overload dinamico `TValue`-based com fronteira POR ALVO

### Passo 1 — Reescrever o cabecalho da unit (D-13.7)

`Source/ModernSyntax.Invoker.pas`, cabecalho `(* ... *)` em `:1-53`.

**Remover** os tres blocos superados:

- `:12-18` — bloco *"Por que esta unit e autocontida (`uses SysUtils;`
  apenas): ... Rtti e TypInfo nao sao necessarios: ..."* — sai por
  inteiro.
- `:20-25` — bloco *"Por que nao ha ramificacao por compilador nem
  inclusao do .inc do repositorio: TObject.MethodAddress e o mesmo simbolo
  nos dois compiladores; nao ha divergencia a acomodar. ..."* — sai por
  inteiro.
- `:44-51` — bloco *"Contrato tipado ... Nao existe `Invoke(obj, 'Nome',
  [args]): TValue` nesta entrega — no FPC 3.2.2 nao ha de onde ler os
  tipos dos parametros ..."* — sai por inteiro.

**Manter** os blocos que continuam validos:

- `:1-11` (identificacao, licenca, copyright).
- `:27-35` (limite explicito da guarda SizeOf — continua verdadeiro para
  o overload portavel).
- `:36-42` (armadilha "Global Generic template references static
  symtable" — continua verdadeiro).

**Acrescentar**, em substituicao aos tres blocos removidos, uma nota curta
explicando o novo estado da unit E a fronteira por alvo:

```
  Duas superficies publicas:

  1. Invoke<TSignature>(TObject|TClass, string): TSignature — portavel,
     sobre TObject.MethodAddress. Nucleo entregue pela #10; comportamento
     identico em Delphi e FPC 3.2.2, medido.

  2. Invoke(TObject, string, array of TValue, PTypeInfo): TValue —
     dinamico, assinatura identica cross-compiler, mecanismo divergente:
     * Delphi: TRttiContext.GetType(...).GetMethod(...).Invoke(AInstance, AArgs)
     * FPC 3.2.2: TObject.MethodAddress + Rtti.Invoke livre (rtti.pp:583)
     Alcance: public + published no Delphi; published apenas no FPC.
     Assimetria deliberada (cada compilador entrega o que pode); testes
     Case_InvokeDynamic_PublicWithoutMPlus_{RaisesOnFPC,OKOnDelphi} fixam.

  FRONTEIRA POR ALVO — Rtti.Invoke livre depende de SystemInvoke em
  assembly (packages/rtl-objpas/src/<arch>/invoke.inc). No FPC 3.2.2
  esse assembly SO existe para Windows (x86_64-win64, i386-win32). Em
  outros alvos (ex.: x86_64-linux, SysV AMD64), o fallback levanta
  ENotImplemented com SErrInvokeNotImplemented literal. Nao mascaramos;
  o XMLDoc da declaracao publica documenta as tres classes de alvo, e
  os testes de retorno de valor ramificam com
  {$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}.

  Fronteira metodica (todos os alvos): ccReg apenas; construtor levanta
  ENotImplemented na RTL do FPC (rtti.pp:2334); record grande por
  referencia oculta nao coberto.
```

### Passo 2 — `uses` da interface acrescenta `Rtti` (D-13.1)

`Source/ModernSyntax.Invoker.pas:59-60`:

```pascal
uses
  SysUtils,
  Rtti;
```

Aviso `Unit "Rtti" is experimental` do FPC esperado (`RTTI.FPC.pas:45`
ja o emite hoje). Nao suprimir.

### Passo 3 — Declaracao publica do overload dinamico (D-13.1 / D-29.1)

`Source/ModernSyntax.Invoker.pas`, dentro do `TModernInvoker` (apos os
dois `class function Invoke<TSignature>`, antes do `end;` do record):

```pascal
    /// <summary>
    ///   Invoca dinamicamente <c>AMethodName</c> em <c>AInstance</c>,
    ///   passando <c>AArgs</c> como argumentos e retornando o valor
    ///   como <c>TValue</c>. Assinatura identica nos dois compiladores;
    ///   mecanismo e fronteira de execucao dependem do ALVO.
    /// </summary>
    /// <remarks>
    ///   Alcance por compilador:
    ///   - Delphi: <c>public</c> + <c>published</c>, via
    ///     <c>TRttiContext.GetType(AInstance.ClassType).GetMethod(AName)</c>.
    ///   - FPC 3.2.2: <c>published</c> apenas, via
    ///     <c>TObject.MethodAddress(AName)</c> + <c>Rtti.Invoke</c>
    ///     livre (<c>rtti.pp:583</c>).
    ///
    ///   Fronteira POR ALVO (o overload nao promete alem disso):
    ///   - Delphi (Win32/Win64/Linux/etc): invocacao viva; alcance
    ///     <c>public</c> + <c>published</c>.
    ///   - FPC 3.2.2 Windows (Win32/Win64): invocacao viva via
    ///     <c>SystemInvoke</c> em assembly
    ///     (<c>packages/rtl-objpas/src/x86_64/invoke.inc</c> e
    ///     <c>i386/invoke.inc</c>); alcance <c>published</c>.
    ///   - FPC 3.2.2 outros alvos (ex.: <c>x86_64-linux</c>, SysV AMD64):
    ///     <c>SystemInvoke</c> AUSENTE na RTL; qualquer chamada real
    ///     propaga <c>ENotImplemented</c> com mensagem literal da RTL
    ///     (<c>Invoke functionality is not implemented</c>,
    ///     <c>SErrInvokeNotImplemented</c>). Limite da RTL, nao escolha
    ///     desta unit — nao mascaramos, nao re-embrulhamos.
    ///
    ///   Fronteira metodica (todos os alvos):
    ///   - Convencao de chamada: <c>ccReg</c> apenas. Metodos
    ///     <c>stdcall</c>, <c>cdecl</c> ou <c>pascal</c> nao sao
    ///     cobertos.
    ///   - Construtor: chamar construtor via este overload levanta
    ///     <c>ENotImplemented</c> no FPC (limite da RTL,
    ///     <c>rtti.pp:2334</c>, marcado como TODO pelo proprio
    ///     compilador).
    ///   - Record grande passado por referencia oculta (ABI-dependente):
    ///     nao coberto.
    ///
    ///   Em metodo <c>public</c> nao-<c>published</c>, o FPC levanta
    ///   com a mensagem instrutiva reusada do overload portavel (cita
    ///   <c>{$M+}</c> e <c>published</c>). Assimetria deliberada — cada
    ///   compilador entrega o que pode.
    /// </remarks>
    class function Invoke(const AInstance: TObject; const AMethodName: string;
      const AArgs: array of TValue;
      const AResultType: PTypeInfo = nil): TValue; overload; static;
```

**Nao** envolver esta declaracao em `{$IFDEF}` (D-13.1).

### Passo 4 — Corpo Delphi + FPC (D-13.3 / D-13.4 / D-13.5 / D-13.10)

`Source/ModernSyntax.Invoker.pas`, `implementation`, apos as duas
implementacoes generic:

```pascal
class function TModernInvoker.Invoke(const AInstance: TObject;
  const AMethodName: string; const AArgs: array of TValue;
  const AResultType: PTypeInfo): TValue;
{$IFDEF FPC}
var
  LAddress: CodePointer;
  LArgs: TValueArray;
  I: Integer;
begin
  if AInstance = nil then
    raise Exception.Create('AInstance e nil');
  LAddress := AInstance.MethodAddress(AMethodName);
  if LAddress = nil then
    raise Exception.CreateFmt(
      'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
      [AMethodName, AInstance.ClassName]);
  SetLength(LArgs, Length(AArgs) + 1);
  LArgs[0] := TValue.From<TObject>(AInstance);
  for I := 0 to High(AArgs) do
    LArgs[I + 1] := AArgs[I];
  // Rtti.Invoke qualificado — evita colisao com o metodo estatico local.
  // Em alvo sem SystemInvoke (ex.: x86_64-linux), esta linha propaga
  // ENotImplemented (SErrInvokeNotImplemented) da propria RTL. NAO
  // mascarar (D-13.2 / D-29.1).
  Result := Rtti.Invoke(LAddress, LArgs, ccReg, AResultType, False, False);
end;
{$ELSE}
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  if AInstance = nil then
    raise Exception.Create('AInstance e nil');
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(AInstance.ClassType);
    LMethod := LType.GetMethod(AMethodName);
    if LMethod = nil then
      raise Exception.CreateFmt(
        'metodo "%s" nao encontrado em %s; no FPC isso exige {$M+} e secao published',
        [AMethodName, AInstance.ClassName]);
    // Materializa Result DENTRO do try (D-13.4): TValue copia o
    // conteudo e sobrevive ao .Free do contexto; TRttiMethod nao.
    // AResultType ignorado no Delphi — LMethod carrega o tipo de
    // retorno. Parametro existe por paridade de assinatura (D-13.1) e
    // porque o FPC precisa dele.
    Result := LMethod.Invoke(AInstance, AArgs);
  finally
    LCtx.Free;
  end;
end;
{$ENDIF}
```

Notas obrigatorias:

- **`Rtti.Invoke` qualificado** com o nome da unit para evitar recursao
  infinita ou erro de tipo (Delphi e FPC podem resolver o nome curto
  `Invoke(...)` para o metodo estatico local).
- **Nao acrescentar guarda para o `ENotImplemented` do RTL** — ele deve
  aflorar (D-13.2 / D-29.1).
- **Sem cast dependente de bitness**: `TValueArray`, `CodePointer` e
  `ccReg` sao da propria `Rtti` (FPC) / `System.Rtti` (Delphi).

### Passo 5 — Overloads portaveis inalterados (D-13.13)

`Source/ModernSyntax.Invoker.pas:65-69` (interface) e `:73-111`
(implementation): **NAO EDITAR**. Byte-por-byte identicos apos esta
edicao. Regressao zero — os 7 cenarios existentes continuam verdes.

### Passo 6 — Fixtures + cenarios compartilhados (D-13.11 / D-29.2 / CA-5)

`Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`.

**Uses da interface** — acrescentar `Rtti` para `TValue`:

```pascal
uses
  SysUtils,
  Rtti,
  ModernSyntax.Invoker;
```

**Interface** — acrescentar declaracoes na secao `type` (junto de
`TDateAndTag`) e as procedures Case:

```pascal
type
  TDateAndTag = record
    Stamp: Integer;
    Tag: string;
  end;

procedure Case_InvokeDynamic_ReturnsRecordIntegerAndString;
procedure Case_InvokeDynamic_ReturnsDouble;
procedure Case_InvokeDynamic_ReturnsManagedString;
procedure Case_InvokeDynamic_ProcedureVoid_SideEffect;
procedure Case_InvokeDynamic_NilInstance_Raises;
procedure Case_InvokeDynamic_MethodNotFound_RaisesInstructive;
procedure Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
procedure Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
```

**Implementation** — acrescentar em `TSubject` (a classe published ja
existente) os metodos novos + campo observavel:

```pascal
{$M+}
type
  TSubject = class
  private
    FStamped: Integer;
  published
    function Echo(const s: string): string;
    function Sum(a, b: Integer): Integer;
    function GimmeStamp(ATag: string): TDateAndTag;
    function GimmeAngle: Double;
    procedure StampNow(AValue: Integer);
    function Stamped: Integer;
  end;
  // ... TSubjectWithClassMethod inalterado
{$M-}
```

E as implementacoes das fixtures:

```pascal
function TSubject.GimmeStamp(ATag: string): TDateAndTag;
begin
  // Integer (4) + string (ponteiro 4 no i386 / 8 no x86_64) — SizeOf
  // diverge: 8 no i386, 16 no x86_64. D-13.11.
  Result.Stamp := 1234567890;
  Result.Tag := 'stamped:' + ATag;
end;

function TSubject.GimmeAngle: Double;
begin
  // Retorno em xmm0 no x86_64, ST(0) no i386 — ABIs diferentes.
  Result := 3.14159265358979;
end;

procedure TSubject.StampNow(AValue: Integer);
begin
  FStamped := AValue * 7;
end;

function TSubject.Stamped: Integer;
begin
  Result := FStamped;
end;
```

**Cenarios** — os quatro que exercitam `Rtti.Invoke` de verdade **ramificam
por alvo** (D-29.2):

```pascal
procedure Case_InvokeDynamic_ReturnsRecordIntegerAndString;
var
  o: TSubject;
  v: TValue;
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
  raised: Boolean;
  msg: string;
{$ELSE}
  r: TDateAndTag;
{$ENDIF}
begin
  o := TSubject.Create;
  try
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
    raised := False;
    msg := '';
    try
      v := TModernInvoker.Invoke(
        o, 'GimmeStamp',
        [TValue.From<string>('lote')],
        TypeInfo(TDateAndTag)
      );
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then
      Fail('esperava ENotImplemented da RTL em alvo FPC sem SystemInvoke');
    if Pos('not implemented', msg) = 0 then
      Fail('mensagem RTL inesperada: ' + msg);
{$ELSE}
    v := TModernInvoker.Invoke(
      o, 'GimmeStamp',
      [TValue.From<string>('lote')],
      TypeInfo(TDateAndTag)
    );
    v.ExtractRawData(@r);
    if r.Stamp <> 1234567890 then
      Fail('GimmeStamp.Stamp inesperado: ' + IntToStr(r.Stamp));
    if r.Tag <> 'stamped:lote' then
      Fail('GimmeStamp.Tag inesperado: ' + r.Tag);
{$ENDIF}
  finally
    o.Free;
  end;
end;
```

Aplicar a MESMA estrutura em `Case_InvokeDynamic_ReturnsDouble` (retorno
`Double`, extraido com `v.AsExtended`), `Case_InvokeDynamic_ReturnsManagedString`
(retorno `string`, `v.AsString`) e `Case_InvokeDynamic_ProcedureVoid_SideEffect`
(passa `nil` como `AResultType`; no ramo com valor, assere `o.Stamped = 42`).

**Cenarios que NAO ramificam** (guarda dispara antes da RTL):

```pascal
procedure Case_InvokeDynamic_NilInstance_Raises;
var
  raised: Boolean;
begin
  raised := False;
  try
    TModernInvoker.Invoke(TObject(nil), 'Echo', [TValue.From<string>('x')], TypeInfo(string));
  except
    on E: Exception do
      raised := True;
  end;
  if not raised then
    Fail('esperava excecao para AInstance = nil no overload dinamico');
end;

procedure Case_InvokeDynamic_MethodNotFound_RaisesInstructive;
var
  o: TSubject;
  raised: Boolean;
  msg: string;
begin
  o := TSubject.Create;
  try
    raised := False;
    msg := '';
    try
      TModernInvoker.Invoke(o, 'NaoExiste', [], TypeInfo(Integer));
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then Fail('esperava excecao para metodo inexistente');
    if Pos('{$M+}', msg) = 0 then Fail('mensagem nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then Fail('mensagem nao cita published: ' + msg);
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
var
  o: TNoM;                        // classe SEM {$M+} ja existente no arquivo
  raised: Boolean;
  msg: string;
begin
  // Assimetria D-13.3: este Case existe para o LADO FPC. A casca DUnitX
  // NAO o registra; ela registra o par _OKOnDelphi.
  o := TNoM.Create;
  try
    raised := False;
    msg := '';
    try
      TModernInvoker.Invoke(o, 'Echo', [TValue.From<string>('x')], TypeInfo(string));
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then Fail('FPC: esperava excecao para public sem {$M+}');
    if Pos('{$M+}', msg) = 0 then Fail('mensagem nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then Fail('mensagem nao cita published: ' + msg);
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
var
  o: TNoM;
  v: TValue;
  r: string;
begin
  // Assimetria D-13.3: este Case existe para o LADO DELPHI. A casca
  // FPCUnit NAO o registra; ela registra o par _RaisesOnFPC.
  o := TNoM.Create;
  try
    v := TModernInvoker.Invoke(o, 'Echo', [TValue.From<string>('din')], TypeInfo(string));
    r := v.AsString;
    if r <> 'nom:din' then
      Fail('Delphi: TNoM.Echo dinamico inesperado: ' + r);
  finally
    o.Free;
  end;
end;
```

Notas obrigatorias:

- **CA-5**: `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = **0**. A ramificacao permitida
  neste arquivo e por ALVO — `{$IF defined(FPC) and defined(CPUX86_64) and
  defined(UNIX)}` — o que NAO viola CA-5 (a regra proibe separar backend
  por COMPILADOR, o que mascara divergencia silenciosa; separar por ALVO
  quando a divergencia e por alvo e o oposto disso).
- **Pegadinha `BoolToStr` (D-53.6)**: nao usar. `if..then..else` explicito.
- **Sem citacao nova de linha do proprio repo em teste** (classe #64):
  comentar simbolo, RTL externa, ou nada.
- **`AsType<T>` e Delphi-only** (medido; FPC 3.2.2 nao compila): usar
  `v.ExtractRawData(@r)` para record, `v.AsExtended` para `Double`,
  `v.AsString` para `string`.
- **`TNoM`** ja existe no arquivo `.Cases.pas` (classe SEM `{$M+}`
  usada pelos cenarios `PublicWithoutMPlus_...` do overload portavel);
  reusar.

### Passo 7 — Casca FPCUnit (D-7 / CA-5)

`Test FPC/EclbrSystem/UTestMS.Invoker.pas`.

**Interface** — dentro de `TInvokerTests`, apos os 7 metodos existentes:

```pascal
    procedure InvokeDynamic_ReturnsRecordIntegerAndString;
    procedure InvokeDynamic_ReturnsDouble;
    procedure InvokeDynamic_ReturnsManagedString;
    procedure InvokeDynamic_ProcedureVoid_SideEffect;
    procedure InvokeDynamic_NilInstance_Raises;
    procedure InvokeDynamic_MethodNotFound_RaisesInstructive;
    procedure InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
```

**Implementation** — 7 procedures, cada uma com corpo de UMA linha
delegando ao `Case_...` correspondente.

**Assimetria**: **NAO** declarar `InvokeDynamic_PublicWithoutMPlus_OKOnDelphi`
neste arquivo — esse Case e do lado Delphi (D-13.3).

Contagem final FPC: **14** metodos published na `TInvokerTests`
(7 existentes + 7 novos).

### Passo 8 — Casca DUnitX (D-7 / CA-5)

`Test Delphi/EclbrSystem/UTestMS.Invoker.pas`.

**Interface** — dentro da classe de teste DUnitX, apos os 7 metodos
existentes:

```pascal
    [Test] procedure InvokeDynamic_ReturnsRecordIntegerAndString;
    [Test] procedure InvokeDynamic_ReturnsDouble;
    [Test] procedure InvokeDynamic_ReturnsManagedString;
    [Test] procedure InvokeDynamic_ProcedureVoid_SideEffect;
    [Test] procedure InvokeDynamic_NilInstance_Raises;
    [Test] procedure InvokeDynamic_MethodNotFound_RaisesInstructive;
    [Test] procedure InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
```

**Assimetria**: **NAO** declarar `InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC`
aqui — esse Case e do lado FPC (D-13.3).

Cada procedure, corpo de UMA linha delegando ao `Case_...` correspondente.

### Passo 9 — Verificacao local (fabrica; x86_64-linux apenas)

Segundo `SKILL.md` (trap 2 do FPC):

```
rm -rf /tmp/fpcbuild
mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

**Esperado na fabrica (x86_64-linux):**

- Compila com zero erros, zero warnings novos (o `Unit "Rtti" is
  experimental` — se emitido — ja e emitido por `RTTI.FPC.pas:45`).
- Suite passa **14/14** — os 4 cenarios de valor passam VERDES asserindo
  `ENotImplemented` (D-29.2).
- `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = 0 (CA-5).
- `grep -c "{\$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = 4 (um por
  cenario de valor).

**FPC i386 + FPC Windows Win32/Win64 + Delphi Win32/Win64** ficam com o
autor (D-29.3). Se o autor rodar em FPC Windows, os 4 cenarios de valor
passam pelo caminho `{$ELSE}` e asserem o valor de retorno — path vivo
verdadeiro.

### Passo 10 — Commit e PR

Um unico commit. Mensagem:

```
feat(invoker): overload dinamico TValue-based cross-compiler, fronteira por alvo (#13)

- Novo TModernInvoker.Invoke(AInstance, AName, AArgs, AResultType): TValue
- Assinatura publica identica em Delphi e FPC 3.2.2; corpo divergente por IFDEF
- FPC: TObject.MethodAddress + Rtti.Invoke livre (rtti.pp:583); alcance published
- Delphi: TRttiContext.GetMethod.Invoke; alcance public + published
- Cabecalho da unit reescrito — tres blocos superados removidos (D-13.7)
- XMLDoc declara alcance E fronteira POR ALVO (D-29.1):
  Delphi | FPC-Windows | FPC-Linux (ENotImplemented da RTL — SystemInvoke ausente)
- 8 novos cenarios em UTestMS.Invoker.Cases; os 4 de retorno de valor ramificam
  por alvo com {$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)} (D-29.2)
- Assimetria deliberada em teste executavel (public sem {$M+}): Case dividido
  por casca; CA-5 preservado
- Overload portavel Invoke<TSignature> byte-por-byte inalterado (regressao zero)
```

PR body carrega:

- Frase declarativa: *"compilado em FPC 3.2.2 x86_64-linux (fabrica, com
  o path RTL vivo caindo em ENotImplemented — comportamento documentado);
  Delphi (Win32/Win64) e FPC Windows (Win32/Win64) ficam com o autor."*
- Log da execucao FPC da fabrica em `<details>` (`PTestInvoker --all -a
  --format=plain`, 14/14 verdes).
- Referencia a `rtti.pp:583` e a
  `packages/rtl-objpas/src/<arch>/invoke.inc` como fontes da divergencia
  por alvo.
- Referencia a secao *"CORRECAO 2 — 03/09/2026, medida DENTRO da fabrica"*
  do corpo da issue como origem das decisoes deste ciclo.
