(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
  UTestMS.Callback.Scenarios

  Unit COMUM de cenarios para os testes de ModernSyntax.Callback.

  Regra: NAO usa nenhum framework de teste (nem DUnitX, nem FPCUnit).
  Cada cenario e uma procedure top-level que executa o caso e LEVANTA
  excecao na falha. A excecao E o contrato — a casca fina do lado
  Delphi e do lado FPC apenas invoca o cenario, e deixa a excecao virar
  Fail no framework respectivo.

  NAO contem diretiva de compilacao condicional — CA-4 do ESP;
  verificavel por grep de IFDEF (sem chaves) sobre este diretorio.

  Consumida por:
    - Test Delphi/EclbrSystem/UTestMS.Callback.pas (DUnitX)
    - Test FPC/EclbrSystem/UTestMS.Callback.pas (FPCUnit)
  ------------------------------------------------------------------------------
*)

unit UTestMS.Callback.Scenarios;

interface

uses
  SysUtils,
  ModernSyntax.Callback;

type
  { Excecao levantada pelos cenarios quando o caso falha. A casca fina
    do framework de teste captura via seu proprio try/except e reporta. }
  ETestScenarioFailed = class(Exception);

  { Classe helper de captura — declarada AQUI, na unit de cenarios,
    como demonstracao canonica do padrao CA-3 do ESP (CA-4 do PRD).
    O consumidor Delphi/FPC que precisar de captura de estado usa
    exatamente esta forma: uma classe que carrega o estado em campo,
    implementa a interface, e passa a instancia ao consumidor. }
  TAccumulator = class(TInterfacedObject, IModernFunc<Integer, Integer>)
  private
    FAcc: Integer;
  public
    constructor Create(const AInitial: Integer);
    function Invoke(const AValue: Integer): Integer;
    property Acc: Integer read FAcc;
  end;

  { Classe host com metodos de objeto para exercitar Callback.&Of. }
  THost = class
  private
    FLastSeen: Integer;
  public
    function Double(const AValue: Integer): Integer;
    procedure LogSeen(const AValue: Integer);
    function IsPositive(const AValue: Integer): Boolean;
    property LastSeen: Integer read FLastSeen;
  end;

// Cenarios. Cada procedure executa um caso; levanta ETestScenarioFailed
// (ou qualquer Exception) na falha.

procedure CallbackOf_MethodOfObject_Func_Returns;
procedure CallbackOf_MethodOfObject_Proc_Executes;
procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
procedure Interface_CapturesState_ViaHelperClass;

implementation

{ TAccumulator }

constructor TAccumulator.Create(const AInitial: Integer);
begin
  inherited Create;
  FAcc := AInitial;
end;

function TAccumulator.Invoke(const AValue: Integer): Integer;
begin
  FAcc := FAcc + AValue;
  Result := FAcc;
end;

{ THost }

function THost.Double(const AValue: Integer): Integer;
begin
  Result := AValue * 2;
end;

procedure THost.LogSeen(const AValue: Integer);
begin
  FLastSeen := AValue;
end;

function THost.IsPositive(const AValue: Integer): Boolean;
begin
  Result := AValue > 0;
end;

{ Helpers de assercao locais — sem framework. }

procedure Ensure(const ACondition: Boolean; const AMsg: string);
begin
  if not ACondition then
    raise ETestScenarioFailed.Create(AMsg);
end;

{ ------------------------------------------------------------------
  Cenarios
  ------------------------------------------------------------------ }

procedure CallbackOf_MethodOfObject_Func_Returns;
var
  LHost: THost;
  LCallback: IModernFunc<Integer, Integer>;
begin
  LHost := THost.Create;
  try
    LCallback := Callback.&Of<Integer, Integer>(LHost.Double);
    Ensure(LCallback.Invoke(21) = 42,
      'IModernFunc<Integer,Integer>.Invoke(21) deveria retornar 42');
    Ensure(LCallback.Invoke(-5) = -10,
      'IModernFunc<Integer,Integer>.Invoke(-5) deveria retornar -10');
  finally
    LCallback := nil;
    LHost.Free;
  end;
end;

procedure CallbackOf_MethodOfObject_Proc_Executes;
var
  LHost: THost;
  LCallback: IModernProc<Integer>;
begin
  LHost := THost.Create;
  try
    LCallback := Callback.&Of<Integer>(LHost.LogSeen);
    LCallback.Invoke(7);
    Ensure(LHost.LastSeen = 7,
      'IModernProc<Integer>.Invoke deveria ter chamado LogSeen(7)');
    LCallback.Invoke(99);
    Ensure(LHost.LastSeen = 99,
      'IModernProc<Integer>.Invoke deveria ter chamado LogSeen(99)');
  finally
    LCallback := nil;
    LHost.Free;
  end;
end;

procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
var
  LHost: THost;
  LCallback: IModernPredicate<Integer>;
begin
  LHost := THost.Create;
  try
    LCallback := Callback.&Of<Integer>(LHost.IsPositive);
    Ensure(LCallback.Invoke(5) = True,
      'IModernPredicate<Integer>.Invoke(5) deveria retornar True');
    Ensure(LCallback.Invoke(-1) = False,
      'IModernPredicate<Integer>.Invoke(-1) deveria retornar False');
    Ensure(LCallback.Invoke(0) = False,
      'IModernPredicate<Integer>.Invoke(0) deveria retornar False (nao positivo)');
  finally
    LCallback := nil;
    LHost.Free;
  end;
end;

procedure Interface_CapturesState_ViaHelperClass;
var
  LAccInstance: TAccumulator;
  LAcc: IModernFunc<Integer, Integer>;
  LFirst, LSecond, LThird: Integer;
begin
  { A instancia TAccumulator carrega o estado; devolvemos pela interface
    para o consumidor. O padrao E o mesmo nos dois compiladores — nao ha
    IFDEF no consumidor. }
  LAccInstance := TAccumulator.Create(10);
  LAcc := LAccInstance;
  try
    LFirst := LAcc.Invoke(1);   // 10 + 1 = 11
    LSecond := LAcc.Invoke(2);  // 11 + 2 = 13
    LThird := LAcc.Invoke(3);   // 13 + 3 = 16
    Ensure(LFirst = 11,
      'Primeira invocacao (10+1) deveria retornar 11');
    Ensure(LSecond = 13,
      'Segunda invocacao (11+2) deveria retornar 13');
    Ensure(LThird = 16,
      'Terceira invocacao (13+3) deveria retornar 16');
    Ensure(LAccInstance.Acc = 16,
      'Estado capturado deveria ser 16 apos tres invocacoes');
  finally
    LAcc := nil;
  end;
end;

end.
