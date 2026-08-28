{
  ------------------------------------------------------------------------------
  ModernSyntax — FPCUnit thin shell over the shared callback scenarios.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{
  UTestMS.Callback (FPCUnit side) — each method delegates to the identically
  named scenario procedure in UTestMS.Callback.Scenarios (shared unit under
  Test Shared/EclbrSystem/). No assertion logic lives here; any exception
  raised by the scenario becomes an FPCUnit failure.
}

unit UTestMS.Callback;

{$MODE DELPHI}
{$H+}

interface

uses
  fpcunit,
  testregistry,
  UTestMS.Callback.Scenarios;

type
  TCallbackTests = class(TTestCase)
  published
    procedure CallbackOf_MethodOfObject_Func_Returns;
    procedure CallbackOf_MethodOfObject_Proc_Executes;
    procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
    procedure Interface_CapturesState_ViaHelperClass;
  end;

implementation

procedure TCallbackTests.CallbackOf_MethodOfObject_Func_Returns;
begin
  UTestMS.Callback.Scenarios.CallbackOf_MethodOfObject_Func_Returns;
end;

procedure TCallbackTests.CallbackOf_MethodOfObject_Proc_Executes;
begin
  UTestMS.Callback.Scenarios.CallbackOf_MethodOfObject_Proc_Executes;
end;

procedure TCallbackTests.CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
begin
  UTestMS.Callback.Scenarios.CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
end;

procedure TCallbackTests.Interface_CapturesState_ViaHelperClass;
begin
  UTestMS.Callback.Scenarios.Interface_CapturesState_ViaHelperClass;
end;

initialization
  RegisterTest(TCallbackTests);

end.
