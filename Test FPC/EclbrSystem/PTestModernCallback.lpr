(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
  PTestModernCallback (FPC / FPCUnit console runner)

  Programa de teste que roda os casos registrados pela unit
  UTestMS.Callback via TTestRunner do pacote consoletestrunner (nativo
  do FPC 3.2.2).

  Rodar (na maquina do autor):
    lazbuild --build-mode=Debug-x86_64 PTestModernCallback.lpi
    ./PTestModernCallback --all -a --format=plain
  ------------------------------------------------------------------------------
*)

program PTestModernCallback;

{$MODE OBJFPC}{$H+}

uses
  Classes, consoletestrunner,
  UTestMS.Callback.Scenarios,
  UTestMS.Callback,
  ModernSyntax.Callback;

type
  TMyTestRunner = class(TTestRunner)
  protected
    // override the protected methods of TTestRunner if desired
  end;

var
  Application: TMyTestRunner;
begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'PTestModernCallback';
  Application.Run;
  Application.Free;
end.
