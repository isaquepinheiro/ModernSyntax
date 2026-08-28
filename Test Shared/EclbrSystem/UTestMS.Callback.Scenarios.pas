{
  ------------------------------------------------------------------------------
  ModernSyntax — test scenarios (framework-agnostic)
  Shared callback test scenarios used by both compilers.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{
  UTestMS.Callback.Scenarios — logic of the callback tests, written ONCE.

  Consumed by two thin shells living under Test Delphi/EclbrSystem/ and
  Test FPC/EclbrSystem/ (each named UTestMS.Callback.pas). Each scenario is a
  plain top-level procedure that executes the case and raises
  ETestScenarioFailed on failure. The shells convert that exception into a
  Fail on whichever framework is in use.

  This unit MUST NOT contain any {$IFDEF} (CA-4 of ESP) and MUST NOT reference
  any test framework (D-A7 of ADR).
}

unit UTestMS.Callback.Scenarios;

{ NOTE: no {$IFDEF} in this unit (CA-4 of ESP, gated by grep). Compiler mode
  on the FPC side is set by the surrounding project (PTestModernCallback.lpi
  declares SyntaxMode=Delphi at project scope). On the Delphi side the source
  is already parsed in Delphi mode by default. }

interface

uses
  SysUtils,
  ModernSyntax.Callback;

type
  { Failure sentinel raised by any scenario when an assertion does not hold.
    The thin shells let this exception propagate so the framework in use
    converts it into a `Fail`. }
  ETestScenarioFailed = class(Exception);

  { Canonical helper class demonstrating variable capture via a stateful
    IModernFunc<T,R> implementation. Reference for consumers that need
    capture without `reference to` (CA-3 of ESP, CA-4 of PRD). }
  TAccumulator = class(TInterfacedObject, IModernFunc<Integer, Integer>)
  private
    FAcc: Integer;
  public
    function Invoke(const AValue: Integer): Integer;
    property Acc: Integer read FAcc;
  end;

  { Host with method-of-object samples used by the Callback.&Of scenarios. }
  THost = class
  private
    FLastSeen: Integer;
    FSeenCount: Integer;
  public
    function Double(const AValue: Integer): Integer;
    procedure LogSeen(const AValue: Integer);
    function IsPositive(const AValue: Integer): Boolean;
    property LastSeen: Integer read FLastSeen;
    property SeenCount: Integer read FSeenCount;
  end;

procedure CallbackOf_MethodOfObject_Func_Returns;
procedure CallbackOf_MethodOfObject_Proc_Executes;
procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
procedure Interface_CapturesState_ViaHelperClass;

implementation

{ TAccumulator }

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
  Inc(FSeenCount);
end;

function THost.IsPositive(const AValue: Integer): Boolean;
begin
  Result := AValue > 0;
end;

{ ---------------- Scenario helpers ---------------- }

procedure AssertEqualInt(const AExpected, AActual: Integer; const AWhere: string);
begin
  if AExpected <> AActual then
    raise ETestScenarioFailed.CreateFmt(
      '%s: expected %d, got %d', [AWhere, AExpected, AActual]);
end;

procedure AssertTrue(const ACondition: Boolean; const AWhere: string);
begin
  if not ACondition then
    raise ETestScenarioFailed.Create(AWhere + ': expected True, got False');
end;

procedure AssertFalse(const ACondition: Boolean; const AWhere: string);
begin
  if ACondition then
    raise ETestScenarioFailed.Create(AWhere + ': expected False, got True');
end;

{ ---------------- Scenarios ---------------- }

procedure CallbackOf_MethodOfObject_Func_Returns;
var
  LHost: THost;
  LFunc: IModernFunc<Integer, Integer>;
begin
  LHost := THost.Create;
  try
    LFunc := Callback.&Of<Integer, Integer>(LHost.Double);
    AssertEqualInt(42, LFunc.Invoke(21),
      'CallbackOf_MethodOfObject_Func_Returns');
  finally
    LHost.Free;
  end;
end;

procedure CallbackOf_MethodOfObject_Proc_Executes;
var
  LHost: THost;
  LProc: IModernProc<Integer>;
begin
  LHost := THost.Create;
  try
    LProc := Callback.&Of<Integer>(LHost.LogSeen);
    LProc.Invoke(7);
    AssertEqualInt(7, LHost.LastSeen,
      'CallbackOf_MethodOfObject_Proc_Executes: LastSeen');
    AssertEqualInt(1, LHost.SeenCount,
      'CallbackOf_MethodOfObject_Proc_Executes: SeenCount');
  finally
    LHost.Free;
  end;
end;

procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
var
  LHost: THost;
  LPred: IModernPredicate<Integer>;
begin
  LHost := THost.Create;
  try
    LPred := Callback.&Of<Integer>(LHost.IsPositive);
    AssertTrue(LPred.Invoke(3),
      'CallbackOf_MethodOfObject_Predicate_ReturnsBoolean: Invoke(3)');
    AssertFalse(LPred.Invoke(-1),
      'CallbackOf_MethodOfObject_Predicate_ReturnsBoolean: Invoke(-1)');
  finally
    LHost.Free;
  end;
end;

procedure Interface_CapturesState_ViaHelperClass;
var
  LCapture: IModernFunc<Integer, Integer>;
  LFirst, LSecond, LThird: Integer;
begin
  LCapture := TAccumulator.Create;
  LFirst := LCapture.Invoke(2);
  LSecond := LCapture.Invoke(3);
  LThird := LCapture.Invoke(5);
  AssertEqualInt(2, LFirst,  'Interface_CapturesState_ViaHelperClass: first');
  AssertEqualInt(5, LSecond, 'Interface_CapturesState_ViaHelperClass: second');
  AssertEqualInt(10, LThird, 'Interface_CapturesState_ViaHelperClass: third');
end;

end.
