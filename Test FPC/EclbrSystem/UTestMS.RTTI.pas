(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  UTestMS.RTTI (FPC) — casca fina FPCUnit para Pilar 1 ModernRTTI (issue #8).

  Cada procedure published chama exatamente uma linha util (o cenario
  compartilhado). Se aparecer if/then de asserção nesta casca, e vazamento.
  Sem TestGetFields aqui: TModernRTTIField e Delphi-only (D12 do ADR).
  Zero diretiva por compilador neste arquivo (CA-5 do PRD / ESP).
  ------------------------------------------------------------------------------
*)

unit UTestMS.RTTI;

interface

uses
  fpcunit,
  testregistry,
  UScenarios.RTTI;

type
  TTestModernRTTI = class(TTestCase)
  published
    procedure TestGetProperties_ReturnsPublishedProps;
    procedure TestGetValue_Integer_Roundtrip;
    procedure TestGetValue_String_Roundtrip;
    procedure TestGetValue_Currency_Roundtrip;
    procedure TestMissingM_RaisesEModernRTTIError;
  end;

implementation

procedure TTestModernRTTI.TestGetProperties_ReturnsPublishedProps;
begin
  Scenario_GetProperties_ReturnsPublishedProps;
end;

procedure TTestModernRTTI.TestGetValue_Integer_Roundtrip;
begin
  Scenario_GetValue_Integer_Roundtrip;
end;

procedure TTestModernRTTI.TestGetValue_String_Roundtrip;
begin
  Scenario_GetValue_String_Roundtrip;
end;

procedure TTestModernRTTI.TestGetValue_Currency_Roundtrip;
begin
  Scenario_GetValue_Currency_Roundtrip;
end;

procedure TTestModernRTTI.TestMissingM_RaisesEModernRTTIError;
begin
  Scenario_MissingM_RaisesEModernRTTIError;
end;

initialization
  RegisterTest(TTestModernRTTI);

end.
