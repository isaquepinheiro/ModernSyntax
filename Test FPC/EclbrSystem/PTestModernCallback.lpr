{
  ------------------------------------------------------------------------------
  ModernSyntax — FPCUnit console runner for ModernSyntax.Callback tests.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

program PTestModernCallback;

{$MODE DELPHI}
{$H+}

uses
  consoletestrunner,
  ModernSyntax.Callback,
  UTestMS.Callback.Scenarios,
  UTestMS.Callback;

type
  TCallbackTestRunner = class(TTestRunner)
  end;

var
  Application: TCallbackTestRunner;

begin
  Application := TCallbackTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'ModernSyntax.Callback tests';
    Application.Run;
  finally
    Application.Free;
  end;
end.
