{
  ------------------------------------------------------------------------------
  ModernSyntax — FPCUnit shell for the RTTI scenarios (Pilar 1, issue #8).

  NOTE (2026-08-28): Issue #7 (FPC test infrastructure — .lpi, Test FPC/ and
  Test Shared/ directories, FPCUnit vendoring pattern) has not merged yet.
  This file is committed as a SKELETON per the "Dependência declarada"
  clause in .project/pipeline/task-input.md. No .lpi is invented on this
  side (lesson from rejected commit 06fccea of cycle-002): the runner
  will be added to the .lpi of #7 once that ticket merges.

  Each method below delegates to a scenario in Test Shared/EclbrSystem/
  UScenarios.RTTI.pas. A failing scenario raises ETestScenarioFailed or
  EModernRTTIError; FPCUnit surfaces the message as the test failure.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro
  ------------------------------------------------------------------------------
}

unit UTestMS.RTTI;

{$mode objfpc}{$H+}

interface

uses
  fpcunit,
  testregistry,
  UScenarios.RTTI;

type
  TRTTITests = class(TTestCase)
  published
    procedure GetProperties_ReturnsPublishedProps;
    procedure GetFields_ReturnsFields;
    procedure MissingM_RaisesEModernRTTIError;
    procedure GetValue_RoundTripsGenericT;
    procedure GetType_ByTypeInfo_YieldsSameName;
  end;

implementation

procedure TRTTITests.GetProperties_ReturnsPublishedProps;
begin
  UScenarios.RTTI.Scenario_GetProperties_ReturnsPublishedProps;
end;

procedure TRTTITests.GetFields_ReturnsFields;
begin
  UScenarios.RTTI.Scenario_GetFields_ReturnsFields;
end;

procedure TRTTITests.MissingM_RaisesEModernRTTIError;
begin
  UScenarios.RTTI.Scenario_MissingM_RaisesEModernRTTIError;
end;

procedure TRTTITests.GetValue_RoundTripsGenericT;
begin
  UScenarios.RTTI.Scenario_GetValue_RoundTripsGenericT;
end;

procedure TRTTITests.GetType_ByTypeInfo_YieldsSameName;
begin
  UScenarios.RTTI.Scenario_GetType_ByTypeInfo_YieldsSameName;
end;

initialization
  RegisterTest(TRTTITests);

end.
