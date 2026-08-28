(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  PTestRTTI (FPC) — runner console FPCUnit para Pilar 1 ModernRTTI (issue #8).
  Padrao herdado do commit 7114cdc da issue #7. Modo OBJFPC no arquivo do
  programa e aceitavel (o programa nao contem records com strict private);
  as units compiladas usam modo Delphi via -Mdelphi na CLI e via
  <SyntaxMode Value="Delphi"/> em ambos os build modes do .lpi.
  ------------------------------------------------------------------------------
*)

program PTestRTTI;

{$MODE OBJFPC}{$H+}

uses
  Classes,
  consoletestrunner,
  UScenarios.RTTI,
  UTestMS.RTTI,
  ModernSyntax.RTTI;

type
  TMyTestRunner = class(TTestRunner)
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'ModernRTTI Pilar 1 - PTestRTTI (FPCUnit)';
  Application.Run;
  Application.Free;
end.
