(*
  ------------------------------------------------------------------------------
  ModernSyntax — FPCUnit shell for ModernSyntax.Attributes tests (FPC).

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Casca fina. Cada metodo published delega ao cenario compartilhado em uma
  linha. Teste FPC-only (afirmando divergencia silenciosa `[MyAttr]` nativo
  sozinho -> vazio) atras de {$IFDEF NO_NATIVE_ATTRS}.
  ------------------------------------------------------------------------------
*)

unit UTestMS.Attributes;

interface

{$I UTestMS.Attributes.Symbols.inc}
{$IF NOT DEFINED(HAS_NATIVE_ATTRS) AND NOT DEFINED(NO_NATIVE_ATTRS)}
  {$MESSAGE FATAL 'UTestMS.Attributes.Symbols.inc nao foi incluido'}
{$IFEND}

uses
  SysUtils,
  fpcunit,
  testregistry,
  UTestMS.Attributes.Scenarios,
  ModernSyntax.Attributes;

type
  {$IFDEF NO_NATIVE_ATTRS}
  TAlvoFpcNativeAlone = class(TObject);
  {$ENDIF}

  TAttributesTests = class(TTestCase)
  published
    procedure Register_ThenGetAttributes_ReturnsRegistered;
    procedure GetAttributes_NeverRegistered_ReturnsEmpty;
    procedure Register_SameInstanceTwice_IsDeduplicated;
    procedure Register_TwoInstances_BothAppear;
    procedure NativePlusRegister_IsIdentical;
    {$IFDEF NO_NATIVE_ATTRS}
    procedure TestFPC_NativeAlone_NoRegister_ReturnsEmpty;
    {$ENDIF}
  end;

implementation

{ TAttributesTests }

procedure TAttributesTests.Register_ThenGetAttributes_ReturnsRegistered;
begin
  Scenario_Register_ThenGetAttributes_ReturnsRegistered;
end;

procedure TAttributesTests.GetAttributes_NeverRegistered_ReturnsEmpty;
begin
  Scenario_GetAttributes_NeverRegistered_ReturnsEmpty;
end;

procedure TAttributesTests.Register_SameInstanceTwice_IsDeduplicated;
begin
  Scenario_Register_SameInstanceTwice_IsDeduplicated;
end;

procedure TAttributesTests.Register_TwoInstances_BothAppear;
begin
  Scenario_Register_TwoInstances_BothAppear;
end;

procedure TAttributesTests.NativePlusRegister_IsIdentical;
begin
  Scenario_NativePlusRegister_IsIdentical;
end;

{$IFDEF NO_NATIVE_ATTRS}
procedure TAttributesTests.TestFPC_NativeAlone_NoRegister_ReturnsEmpty;
var
  LResult: TArray<TObject>;
begin
  // Afirma a fronteira portavel: no FPC nao ha `[MyAttr]` nativo. Sem
  // Register previo, GetAttributes devolve array vazio.
  LResult := ModernAttributes.GetAttributes(TAlvoFpcNativeAlone);
  if Length(LResult) <> 0 then
    raise ETestScenarioFailed.CreateFmt(
      'expected empty (no native attrs on FPC), got %d', [Length(LResult)]);
end;
{$ENDIF}

initialization
  RegisterTest(TAttributesTests);

end.
