{
  ------------------------------------------------------------------------------
  ModernSyntax — DUnitX thin shell over the shared callback scenarios.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{
  UTestMS.Callback (DUnitX side) — each method delegates to the identically
  named scenario procedure in UTestMS.Callback.Scenarios (shared unit under
  Test Shared/EclbrSystem/). No assertion logic lives here; any exception
  raised by the scenario becomes a DUnitX Fail.
}

unit UTestMS.Callback;

interface

uses
  DUnitX.TestFramework,
  UTestMS.Callback.Scenarios;

type
  [TestFixture]
  TCallbackTests = class
  public
    [Test]
    procedure CallbackOf_MethodOfObject_Func_Returns;
    [Test]
    procedure CallbackOf_MethodOfObject_Proc_Executes;
    [Test]
    procedure CallbackOf_MethodOfObject_Predicate_ReturnsBoolean;
    [Test]
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
  TDUnitX.RegisterTestFixture(TCallbackTests);

end.
