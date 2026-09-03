---
type: plan
kind: artifact
title: "Plano #13 — TModernInvoker.Invoke dinamico cross-compiler (assinatura identica, corpo divergente)"
description: "Plano de execucao em um slice: novo overload TValue-based no TModernInvoker, backends divergentes por IFDEF, fixtures de retorno com ABI-divergent layouts, cascas de teste de uma linha, cabecalho da unit reescrito."
cycle: "028"
agent: architect
workflow: equipe-feature
node: "plan-gate:on_reject"
resource: aefos://run/3973e0a8a9fb319c0e20e1154e93d8d3
generated:
  by: "equipe-feature@node:architect"
  at: "2026-09-03T00:00:00Z"
tags: [plan, rtti, invoker, fpc, delphi, dynamic-invoke, tvalue, issue-13, cycle-028]
---

# Plano #13 — `TModernInvoker.Invoke` dinamico cross-compiler

## Avaliacao de escopo

**`fits`** — uma mudanca coesa, um commit, um PR.

- **TEST 1 (tamanho):** 1 unit de producao (`ModernSyntax.Invoker.pas`) +
  1 arquivo de cenarios compartilhado + 2 cascas de teste. Sem novo
  `resourcestring`, sem nova infraestrutura. Bem dentro do orcamento de
  um implement tipico (~$10-15).
- **TEST 2 (independencia):** os passos abaixo formam UMA peca de
  trabalho — sem os dois backends, o cenario compartilhado nao roda em
  um dos lados; sem o cenario, os backends nao sao provados; sem
  reescrever o cabecalho, a unit mergeia com afirmacao superada (padrao
  #62, D-53.9). Nao ha dois subconjuntos que sejam cada um mergeavel de
  forma independente.

**Conclusao:** um slice, um commit, um PR.

## Slice unico — Overload dinamico `TValue`-based cross-compiler

### Passo 1 — Reescrever o cabecalho da unit (D-13.7)

`Source/ModernSyntax.Invoker.pas`, cabecalho `(* ... *)` em `:1-53`.

**Remover** os tres blocos superados:

- `:12-18` — bloco *"Por que esta unit e autocontida (`uses SysUtils;`
  apenas): ... Rtti e TypInfo nao sao necessarios: ..."* — sai por
  inteiro.
- `:20-25` — bloco *"Por que nao ha ramificacao por compilador nem
  inclusao do .inc do repositorio: TObject.MethodAddress e o mesmo
  simbolo nos dois compiladores; nao ha divergencia a acomodar. ..."* —
  sai por inteiro.
- `:44-51` — bloco *"Contrato tipado ... Nao existe `Invoke(obj, 'Nome',
  [args]): TValue` nesta entrega — no FPC 3.2.2 nao ha de onde ler os
  tipos dos parametros ..."* — sai por inteiro.

**Manter** os blocos que continuam validos:

- `:1-11` (identificacao, licenca, copyright).
- `:27-35` (limite explicito da guarda SizeOf — continua verdadeiro para
  o overload portavel).
- `:36-42` (armadilha "Global Generic template references static
  symtable" — continua verdadeiro).

**Acrescentar**, em substituicao aos tres blocos removidos, uma nota
curta explicando o novo estado da unit:

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
     Assimetria deliberada (cada compilador entrega o que pode); teste
     Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC_OKOnDelphi fixa.
     Fronteira medida (XMLDoc detalha): ccReg apenas; construtor
     levanta ENotImplemented na RTL do FPC (rtti.pp:2334); record grande
     por referencia oculta nao coberto.
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

### Passo 3 — Declaracao publica do overload dinamico (D-13.1 / D-13.8)

`Source/ModernSyntax.Invoker.pas`, dentro do `TModernInvoker` (apos os
dois `class function Invoke<TSignature>`, antes do `end;` do record):

```pascal
    /// <summary>
    ///   Invoca dinamicamente <c>AMethodName</c> em <c>AInstance</c>,
    ///   passando <c>AArgs</c> como argumentos e retornando o valor
    ///   como <c>TValue</c>. Assinatura identica nos dois compiladores;
    ///   o mecanismo interno diverge.
    /// </summary>
    /// <remarks>
    ///   Alcance:
    ///   - Delphi: <c>public</c> + <c>published</c>, via
    ///     <c>TRttiContext.GetType(AInstance.ClassType).GetMethod(AName)</c>.
    ///   - FPC 3.2.2: <c>published</c> apenas, via
    ///     <c>TObject.MethodAddress(AName)</c> + <c>Rtti.Invoke</c>
    ///     livre (<c>rtti.pp:583</c>).
    ///
    ///   Fronteira medida (o overload nao promete alem disso):
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
    ///   Em metodo <c>public</c> nao-<c>published</c>, o FPC levanta com
    ///   a mensagem instrutiva reusada do overload portavel (cita
    ///   <c>{$M+}</c> e <c>published</c>). Esta assimetria e
    ///   deliberada — cada compilador entrega o que pode.
    /// </remarks>
    class function Invoke(const AInstance: TObject; const AMethodName: string;
      const AArgs: array of TValue;
      const AResultType: PTypeInfo = nil): TValue; overload; static;
```

**Nao** envolver esta declaracao em `{$IFDEF}` (D-13.1).

### Passo 4 — Corpo Delphi (D-13.3 / D-13.4 / D-13.10)

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
  Result := Rtti.Invoke(LAddress, LArgs, ccReg, AResultType, False, False);
  // AResultType intencionalmente aceito como nil (procedure void).
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
    Result := LMethod.Invoke(AInstance, AArgs);
    // AResultType intencionalmente ignorado no Delphi: LMethod carrega
    // o tipo de retorno na propria descoberta. Parametro existe para
    // paridade de assinatura (D-13.1) e para o FPC, onde e obrigatorio.
  finally
    LCtx.Free;
  end;
end;
{$ENDIF}
```

Notas obrigatorias:

- **`AResultType` e usado no FPC e IGNORADO no Delphi.** Isto e
  intencional — o Delphi le o tipo de retorno de `LMethod` (que carrega
  metadado de metodo real); o FPC nao tem enumeracao de metodos, mas o
  consumidor sabe o tipo esperado. Consumidor cross-compiler pode passar
  `TypeInfo(<tipo esperado>)` sempre, e funciona nos dois — o Delphi
  ignora, o FPC usa. Se o consumidor errar o `AResultType` no FPC (por
  exemplo, disser `TypeInfo(Integer)` para um metodo que devolve
  `string`), `Rtti.Invoke` levanta — divergencia RTL, nao nossa. XMLDoc
  ja documenta a fronteira.
- **`Rtti.Invoke` qualificado com o nome da unit** para evitar colisao
  com o metodo `TModernInvoker.Invoke` em corpo (Delphi e FPC podem
  resolver o nome curto para o metodo estatico local dependendo do
  contexto).
- **Materializar tudo dentro do `try/finally`** no Delphi (D-13.4): a
  copia de retorno de `LMethod.Invoke` para `Result` acontece dentro do
  `try` — se o consumidor guardar o `TValue`, ele sobrevive ao `.Free`
  do contexto (o `TValue` copia seu conteudo); o `TRttiMethod` NAO
  sobrevive, mas nao e devolvido.
- **Sem cast dependente de bitness** no FPC: `TValueArray` e o tipo
  da propria RTL do FPC (`rtti.pp`); `CodePointer` idem.

### Passo 5 — Overloads portaveis inalterados (D-13.13)

`Source/ModernSyntax.Invoker.pas:65-69` (interface) e `:73-111`
(implementation): NAO EDITAR. Byte-por-byte identicos apos esta edicao.
Regressao zero — os 7 cenarios existentes continuam verdes.

### Passo 6 — Fixtures + cenarios compartilhados (D-13.11 / CA-5)

`Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas`.

**Interface** — acrescentar declaracoes na secao `interface` (apos as
tres ja existentes, perto de `:31-39`):

```pascal
type
  TDateAndTag = record
    Stamp: Integer;
    Tag: string;
  end;

  TGimmeStampFn = function: TDateAndTag of object;
  TGimmeAngleFn = function: Double of object;
  TStampNowFn   = procedure(AValue: Integer) of object;

procedure Case_InvokeDynamic_ReturnsRecordIntegerAndString;
procedure Case_InvokeDynamic_ReturnsDouble;
procedure Case_InvokeDynamic_ReturnsManagedString;
procedure Case_InvokeDynamic_ProcedureVoid_SideEffect;
procedure Case_InvokeDynamic_NilInstance_Raises;
procedure Case_InvokeDynamic_MethodNotFound_RaisesInstructive;
procedure Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
procedure Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
```

**Uses da interface** — acrescentar `Rtti` para `TValue`:

```pascal
uses
  SysUtils,
  Rtti,
  ModernSyntax.Invoker;
```

**Implementation** — acrescentar em `TSubject` (a classe published ja
existente em `:44-49`) tres metodos novos, e acrescentar um campo
observavel para o teste void:

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

E as implementacoes:

```pascal
function TSubject.GimmeStamp(ATag: string): TDateAndTag;
begin
  // Layout ABI-divergente por bitness: Integer (4) + string
  // (ponteiro, 4 no i386 / 8 no x86_64) — SizeOf=8 no i386, SizeOf=16 no x86_64.
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

**Cenarios** — apos os sete `Case_...` existentes:

```pascal
procedure Case_InvokeDynamic_ReturnsRecordIntegerAndString;
var
  o: TSubject;
  v: TValue;
  r: TDateAndTag;
begin
  o := TSubject.Create;
  try
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
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_ReturnsDouble;
var
  o: TSubject;
  v: TValue;
  r: Double;
begin
  o := TSubject.Create;
  try
    v := TModernInvoker.Invoke(o, 'GimmeAngle', [], TypeInfo(Double));
    r := v.AsExtended;
    if Abs(r - 3.14159265358979) > 1e-12 then
      Fail('GimmeAngle inesperado: ' + FloatToStr(r));
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_ReturnsManagedString;
var
  o: TSubject;
  v: TValue;
  r: string;
begin
  o := TSubject.Create;
  try
    v := TModernInvoker.Invoke(o, 'Echo', [TValue.From<string>('din')], TypeInfo(string));
    r := v.AsString;
    if r <> 'echo:din' then
      Fail('Echo dinamico inesperado: ' + r);
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_ProcedureVoid_SideEffect;
var
  o: TSubject;
  v: TValue;
  after: Integer;
begin
  o := TSubject.Create;
  try
    // AResultType = nil, chamada void; retorno TValue vazio.
    v := TModernInvoker.Invoke(o, 'StampNow', [TValue.From<Integer>(6)], nil);
    // v e TValue.Empty; nao asseramos aqui.
    after := o.Stamped;
    if after <> 42 then
      Fail('StampNow nao mutou estado como esperado; Stamped=' + IntToStr(after));
  finally
    o.Free;
  end;
end;

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
    if not raised then Fail('esperava excecao para metodo inexistente (dinamico)');
    if Pos('{$M+}', msg) = 0 then Fail('mensagem dinamica nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then Fail('mensagem dinamica nao cita published: ' + msg);
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
var
  o: TNoM;
  raised: Boolean;
  msg: string;
begin
  // Assimetria deliberada (D-13.3): este Case existe para o LADO FPC.
  // A casca DUnitX (Delphi) nao registra este Case — registra o par
  // Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi.
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
  // Assimetria deliberada (D-13.3): este Case existe para o LADO DELPHI.
  // A casca FPCUnit nao registra este Case — registra o par
  // Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC.
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

- **CA-5**: nenhum `{$IFDEF FPC}` neste arquivo. A assimetria fica na
  CASCA (FPC registra um Case, Delphi registra o outro). Verificar com
  `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = 0.
- **Pegadinha `BoolToStr` (D-53.6)**: nao usar. Se precisar de mensagem,
  `if..then..else` explicito.
- **Sem citacao nova de linha do proprio repo** (classe #64): comentar
  simbolo, RTL externa, ou nada.
- **Uses da implementation nao precisa mudar** — o `Rtti` da interface
  ja alcanca a implementation.

### Passo 7 — Casca FPCUnit (D-7 / CA-5)

`Test FPC/EclbrSystem/UTestMS.Invoker.pas`.

**Uses** — acrescentar nada (`UTestMS.Invoker.Cases` ja e importado).

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

Contagem final FPC: `grep -c "procedure " "Test FPC/EclbrSystem/UTestMS.Invoker.pas"`
subiu de 7 declaracoes na interface para **14** (7 novas + 7 antigas).

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

Cada procedure, corpo de UMA linha delegando ao `Case_...`.

### Passo 9 — Verificacao local (fabrica; x86_64 apenas)

Segundo `SKILL.md` (Include-path flag / trap 2 do FPC):

```
rm -rf /tmp/fpcbuild
mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestInvoker.lpr"
/tmp/fpcbuild/PTestInvoker --all -a --format=plain
```

**Esperado:**

- Compila com um unico warning esperado: `Unit "Rtti" is experimental`.
- Suite passa **14/14** (7 existentes + 7 novos).
- `grep -c "procedure " "Test FPC/EclbrSystem/UTestMS.Invoker.pas"` = 14.
- `grep -c "{\$IFDEF FPC}" "Test Shared/EclbrSystem/UTestMS.Invoker.Cases.pas"` = 0.

**i386** e os **4 alvos Delphi** ficam com o autor (D-13.12). Log das
duas execucoes do FPC (x86_64 da fabrica; i386 do autor) entra no PR body
em `<details>`.

### Passo 10 — Commit e PR

Um unico commit. Mensagem:

```
feat(invoker): overload dinamico TValue-based cross-compiler (#13)

- Novo TModernInvoker.Invoke(AInstance, AName, AArgs, AResultType): TValue
- Assinatura publica identica em Delphi e FPC 3.2.2; corpo divergente por IFDEF
- FPC: TObject.MethodAddress + Rtti.Invoke livre (rtti.pp:583); alcance published
- Delphi: TRttiContext.GetMethod.Invoke; alcance public + published
- Cabecalho da unit reescrito — tres blocos superados removidos (D-13.7)
- 7 cenarios novos em UTestMS.Invoker.Cases (fixtures Int64+string, Double, void)
- Assimetria deliberada em teste executavel (public sem {$M+}): Case dividido
  por casca; CA-5 preservado
- Overload portavel Invoke<TSignature> inalterado (regressao zero)
```

PR body carrega:

- Frase declarativa: *"compilado em FPC 3.2.2 x86_64 (fabrica) e i386
  (autor); Delphi (Win32/Win64) fica com o autor."*
- Log das duas execucoes do FPC em `<details>` (x86_64 e i386).
- Cita `rtti.pp:583` como fonte da funcao `Invoke` livre usada no
  backend FPC.
- Cita a secao *"CORRECAO DE PREMISSA — 03/09/2026, medida rodando"* do
  corpo da issue como origem das decisoes.
