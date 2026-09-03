(*
  ------------------------------------------------------------------------------
  UTestMS.Invoker.Cases — cenarios portaveis do TModernInvoker (issues #10 + #13)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Unit comum aos dois compiladores. Zero framework de teste. Zero
  ramificacao por compilador (a diretiva IFDEF-por-compilador e proibida
  aqui — CA-5).
  Cada cenario e uma procedure livre que levanta Exception na falha — a
  casca (DUnitX no Delphi, FPCUnit no FPC) transforma essa excecao em Fail.

  Classes-alvo (TSubject, TSubjectWithClassMethod, TNoM) sao LOCAIS a esta
  unit. TSubject e TSubjectWithClassMethod tem {$M+} + secao published;
  TNoM NAO tem {$M+} — MethodAddress nao acha metodos publicos sem
  informacao de RTTI publicada (CA-6 do esp, heranca da familia #8).

  Ramificacao permitida por ALVO: {$IF defined(FPC) and defined(CPUX86_64)
  and defined(UNIX)} nos 4 cenarios de retorno de valor do overload
  dinamico, porque a RTL do FPC 3.2.2 nao implementa SystemInvoke para
  SysV AMD64 e Rtti.Invoke livre cai em ENotImplemented (D-29.2).
  ------------------------------------------------------------------------------
*)

unit UTestMS.Invoker.Cases;

interface

uses
  SysUtils,
  Rtti,
  ModernSyntax.Invoker;

type
  TEchoFn   = function(const s: string): string of object;
  TSumFn    = function(a, b: Integer): Integer of object;
  TAnswerFn = function: Integer of object;

  TDateAndTag = record
    Stamp: Integer;
    Tag: string;
  end;

procedure Case_Invoke_InstanceMethod_ReturnsValue;
procedure Case_TypedMethod_CalledWithArgs_ReturnsExpected;
procedure Case_Invoke_ClassMethod_Works;
procedure Case_Invoke_MethodNotFound_RaisesWithActionableMessage;
procedure Case_Invoke_NilInstance_Raises;
procedure Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
procedure Case_Invoke_NonMethodSignature_Raises;

procedure Case_InvokeDynamic_ReturnsRecordIntegerAndString;
procedure Case_InvokeDynamic_ReturnsDouble;
procedure Case_InvokeDynamic_ReturnsManagedString;
procedure Case_InvokeDynamic_ProcedureVoid_SideEffect;
procedure Case_InvokeDynamic_NilInstance_Raises;
procedure Case_InvokeDynamic_MethodNotFound_RaisesInstructive;
procedure Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
procedure Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;

implementation

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

  TSubjectWithClassMethod = class
  published
    class function Answer: Integer;
  end;
{$M-}

type
  TNoM = class
  public
    function Echo(const s: string): string;
  end;

function TSubject.Echo(const s: string): string;
begin
  Result := 'echo:' + s;
end;

function TSubject.Sum(a, b: Integer): Integer;
begin
  Result := a + b;
end;

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

class function TSubjectWithClassMethod.Answer: Integer;
begin
  Result := 42;
end;

function TNoM.Echo(const s: string): string;
begin
  Result := 'nom:' + s;
end;

procedure Fail(const AMsg: string);
begin
  raise Exception.Create(AMsg);
end;

procedure Case_Invoke_InstanceMethod_ReturnsValue;
var
  o: TSubject;
  fn: TEchoFn;
  r: string;
begin
  o := TSubject.Create;
  try
    fn := TModernInvoker.Invoke<TEchoFn>(o, 'Echo');
    r := fn('x');
    if r <> 'echo:x' then
      Fail('esperado "echo:x", obtido "' + r + '"');
  finally
    o.Free;
  end;
end;

procedure Case_TypedMethod_CalledWithArgs_ReturnsExpected;
var
  o: TSubject;
  fn: TSumFn;
  r: Integer;
begin
  o := TSubject.Create;
  try
    fn := TModernInvoker.Invoke<TSumFn>(o, 'Sum');
    r := fn(2, 3);
    if r <> 5 then
      Fail('esperado 5, obtido ' + IntToStr(r));
  finally
    o.Free;
  end;
end;

procedure Case_Invoke_ClassMethod_Works;
var
  fn: TAnswerFn;
  r: Integer;
begin
  fn := TModernInvoker.Invoke<TAnswerFn>(TSubjectWithClassMethod, 'Answer');
  r := fn();
  if r <> 42 then
    Fail('esperado 42, obtido ' + IntToStr(r));
end;

procedure Case_Invoke_MethodNotFound_RaisesWithActionableMessage;
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
      TModernInvoker.Invoke<TEchoFn>(o, 'NaoExiste');
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then
      Fail('esperava excecao para metodo inexistente');
    if Pos('{$M+}', msg) = 0 then
      Fail('mensagem nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then
      Fail('mensagem nao cita published: ' + msg);
  finally
    o.Free;
  end;
end;

procedure Case_Invoke_NilInstance_Raises;
var
  raised: Boolean;
begin
  raised := False;
  try
    TModernInvoker.Invoke<TEchoFn>(TObject(nil), 'Echo');
  except
    on E: Exception do
      raised := True;
  end;
  if not raised then
    Fail('esperava excecao para AInstance = nil');
end;

procedure Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
var
  o: TNoM;
  raised: Boolean;
  msg: string;
begin
  o := TNoM.Create;
  try
    raised := False;
    msg := '';
    try
      TModernInvoker.Invoke<TEchoFn>(o, 'Echo');
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then
      Fail('esperava excecao para metodo public sem {$M+}');
    if Pos('{$M+}', msg) = 0 then
      Fail('mensagem nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then
      Fail('mensagem nao cita published: ' + msg);
  finally
    o.Free;
  end;
end;

procedure Case_Invoke_NonMethodSignature_Raises;
var
  o: TSubject;
  raised: Boolean;
  msg: string;
  dummy: Integer;
begin
  o := TSubject.Create;
  try
    raised := False;
    msg := '';
    try
      dummy := TModernInvoker.Invoke<Integer>(o, 'Echo');
      if dummy = 0 then ; // silencia hint de variavel nao usada
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then
      Fail('esperava excecao da guarda SizeOf');
    if Pos('TSignature nao e um tipo de metodo-de-objeto', msg) = 0 then
      Fail('mensagem inesperada da guarda: ' + msg);
  finally
    o.Free;
  end;
end;

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
      { A CLASSE e a assertiva; a mensagem e conferencia secundaria.
        Capturar 'Exception' e olhar so o texto deixa passar qualquer
        excecao generica com texto parecido — exigido no plan-gate. }
      on E: ENotImplemented do
      begin
        raised := True;
        msg := E.Message;
      end;
      on E: Exception do
        Fail('classe inesperada no alvo sem SystemInvoke: ' +
          E.ClassName + ' | ' + E.Message);
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

procedure Case_InvokeDynamic_ReturnsDouble;
var
  o: TSubject;
  v: TValue;
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
  raised: Boolean;
  msg: string;
{$ELSE}
  r: Double;
{$ENDIF}
begin
  o := TSubject.Create;
  try
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
    raised := False;
    msg := '';
    try
      v := TModernInvoker.Invoke(o, 'GimmeAngle', [], TypeInfo(Double));
    except
      { A CLASSE e a assertiva; a mensagem e conferencia secundaria.
        Capturar 'Exception' e olhar so o texto deixa passar qualquer
        excecao generica com texto parecido — exigido no plan-gate. }
      on E: ENotImplemented do
      begin
        raised := True;
        msg := E.Message;
      end;
      on E: Exception do
        Fail('classe inesperada no alvo sem SystemInvoke: ' +
          E.ClassName + ' | ' + E.Message);
    end;
    if not raised then
      Fail('esperava ENotImplemented da RTL em alvo FPC sem SystemInvoke');
    if Pos('not implemented', msg) = 0 then
      Fail('mensagem RTL inesperada: ' + msg);
{$ELSE}
    v := TModernInvoker.Invoke(o, 'GimmeAngle', [], TypeInfo(Double));
    r := v.AsExtended;
    if Abs(r - 3.14159265358979) > 1e-12 then
      Fail('GimmeAngle inesperado: ' + FloatToStr(r));
{$ENDIF}
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_ReturnsManagedString;
var
  o: TSubject;
  v: TValue;
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
  raised: Boolean;
  msg: string;
{$ELSE}
  r: string;
{$ENDIF}
begin
  o := TSubject.Create;
  try
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
    raised := False;
    msg := '';
    try
      v := TModernInvoker.Invoke(
        o, 'Echo',
        [TValue.From<string>('din')],
        TypeInfo(string)
      );
    except
      { A CLASSE e a assertiva; a mensagem e conferencia secundaria.
        Capturar 'Exception' e olhar so o texto deixa passar qualquer
        excecao generica com texto parecido — exigido no plan-gate. }
      on E: ENotImplemented do
      begin
        raised := True;
        msg := E.Message;
      end;
      on E: Exception do
        Fail('classe inesperada no alvo sem SystemInvoke: ' +
          E.ClassName + ' | ' + E.Message);
    end;
    if not raised then
      Fail('esperava ENotImplemented da RTL em alvo FPC sem SystemInvoke');
    if Pos('not implemented', msg) = 0 then
      Fail('mensagem RTL inesperada: ' + msg);
{$ELSE}
    v := TModernInvoker.Invoke(
      o, 'Echo',
      [TValue.From<string>('din')],
      TypeInfo(string)
    );
    r := v.AsString;
    if r <> 'echo:din' then
      Fail('Echo dinamico inesperado: ' + r);
{$ENDIF}
  finally
    o.Free;
  end;
end;

procedure Case_InvokeDynamic_ProcedureVoid_SideEffect;
var
  o: TSubject;
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
  raised: Boolean;
  msg: string;
{$ENDIF}
begin
  o := TSubject.Create;
  try
{$IF defined(FPC) and defined(CPUX86_64) and defined(UNIX)}
    raised := False;
    msg := '';
    try
      TModernInvoker.Invoke(o, 'StampNow', [TValue.From<Integer>(6)], nil);
    except
      { A CLASSE e a assertiva; a mensagem e conferencia secundaria.
        Capturar 'Exception' e olhar so o texto deixa passar qualquer
        excecao generica com texto parecido — exigido no plan-gate. }
      on E: ENotImplemented do
      begin
        raised := True;
        msg := E.Message;
      end;
      on E: Exception do
        Fail('classe inesperada no alvo sem SystemInvoke: ' +
          E.ClassName + ' | ' + E.Message);
    end;
    if not raised then
      Fail('esperava ENotImplemented da RTL em alvo FPC sem SystemInvoke');
    if Pos('not implemented', msg) = 0 then
      Fail('mensagem RTL inesperada: ' + msg);
{$ELSE}
    TModernInvoker.Invoke(o, 'StampNow', [TValue.From<Integer>(6)], nil);
    if o.Stamped <> 42 then
      Fail('StampNow: efeito colateral esperado 42, obtido ' + IntToStr(o.Stamped));
{$ENDIF}
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
    TModernInvoker.Invoke(TObject(nil), 'Echo',
      [TValue.From<string>('x')], TypeInfo(string));
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
    if not raised then
      Fail('esperava excecao para metodo inexistente');
    if Pos('{$M+}', msg) = 0 then
      Fail('mensagem nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then
      Fail('mensagem nao cita published: ' + msg);
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
  // Assimetria D-13.3: este Case existe para o LADO FPC. A casca DUnitX
  // NAO o registra; ela registra o par _OKOnDelphi.
  o := TNoM.Create;
  try
    raised := False;
    msg := '';
    try
      TModernInvoker.Invoke(o, 'Echo',
        [TValue.From<string>('x')], TypeInfo(string));
    except
      on E: Exception do
      begin
        raised := True;
        msg := E.Message;
      end;
    end;
    if not raised then
      Fail('FPC: esperava excecao para public sem {$M+}');
    if Pos('{$M+}', msg) = 0 then
      Fail('mensagem nao cita {$M+}: ' + msg);
    if Pos('published', msg) = 0 then
      Fail('mensagem nao cita published: ' + msg);
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
    v := TModernInvoker.Invoke(o, 'Echo',
      [TValue.From<string>('din')], TypeInfo(string));
    r := v.AsString;
    if r <> 'nom:din' then
      Fail('Delphi: TNoM.Echo dinamico inesperado: ' + r);
  finally
    o.Free;
  end;
end;

end.
