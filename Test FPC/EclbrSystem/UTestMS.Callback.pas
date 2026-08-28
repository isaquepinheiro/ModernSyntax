(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
  UTestMS.Callback (FPC / FPCUnit)

  Casca fina. Cada metodo tem UMA linha util, delegando ao cenario
  correspondente em UTestMS.Callback.Scenarios. Excecao levantada pelo
  cenario vira Fail do FPCUnit naturalmente (TTestCase captura no runner).

  NAO contem diretiva de compilacao condicional — CA-4 do ESP;
  verificavel por grep de IFDEF (sem chaves) sobre este arquivo.
  ------------------------------------------------------------------------------
*)

{$MODE DELPHI}

unit UTestMS.Callback;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
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
