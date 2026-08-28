(*
  ------------------------------------------------------------------------------
  UTestMS.Invoker.Cases — cenarios portaveis do TModernInvoker (issue #10)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Unit comum aos dois compiladores. Zero framework de teste. Zero
  ramificacao por compilador.
  Cada cenario e uma procedure livre que levanta Exception na falha — a
  casca (DUnitX no Delphi, FPCUnit no FPC) transforma essa excecao em Fail.

  Classes-alvo (TSubject, TSubjectWithClassMethod, TNoM) sao LOCAIS a esta
  unit. TSubject e TSubjectWithClassMethod tem {$M+} + secao published;
  TNoM NAO tem {$M+} — MethodAddress nao acha metodos publicos sem
  informacao de RTTI publicada (CA-6 do esp, heranca da familia #8).
  ------------------------------------------------------------------------------
*)

unit UTestMS.Invoker.Cases;

interface

uses
  SysUtils,
  ModernSyntax.Invoker;

type
  TEchoFn   = function(const s: string): string of object;
  TSumFn    = function(a, b: Integer): Integer of object;
  TAnswerFn = function: Integer of object;

procedure Case_Invoke_InstanceMethod_ReturnsValue;
procedure Case_TypedMethod_CalledWithArgs_ReturnsExpected;
procedure Case_Invoke_ClassMethod_Works;
procedure Case_Invoke_MethodNotFound_RaisesWithActionableMessage;
procedure Case_Invoke_NilInstance_Raises;
procedure Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
procedure Case_Invoke_NonMethodSignature_Raises;

implementation

{$M+}
type
  TSubject = class
  published
    function Echo(const s: string): string;
    function Sum(a, b: Integer): Integer;
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

end.
