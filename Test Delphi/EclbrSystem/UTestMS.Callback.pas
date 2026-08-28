(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
  UTestMS.Callback (Delphi / DUnitX)

  Casca fina. Cada metodo tem UMA linha util, delegando ao cenario
  correspondente em UTestMS.Callback.Scenarios. Excecao levantada pelo
  cenario vira Fail do DUnitX naturalmente.

  NAO contem diretiva de compilacao condicional — CA-4 do ESP;
  verificavel por grep de IFDEF (sem chaves) sobre este arquivo.
  ------------------------------------------------------------------------------
*)

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
