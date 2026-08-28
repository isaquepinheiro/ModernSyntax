(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  UTestMS.RTTI (Delphi) — casca fina DUnitX para Pilar 1 ModernRTTI (issue #8).

  Cada [Test] chama exatamente uma linha util. TestGetFields e Delphi-only:
  TModernRTTIField e TModernRTTIType.GetFields nao existem no FPC 3.2.2
  (D12 do ADR); nao ha cenario compartilhado para recurso Delphi-only, por
  isso este [Test] invoca GetFields diretamente e verifica com asserts.
  Zero diretiva por compilador neste arquivo (CA-5 do PRD / ESP).
  ------------------------------------------------------------------------------
*)

unit UTestMS.RTTI;

interface

uses
  DUnitX.TestFramework,
  UScenarios.RTTI,
  ModernSyntax.RTTI;

type
  TFieldFixture = class
  public
    Number: Integer;
    Name: string;
  end;

  [TestFixture]
  TTestModernRTTI = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGetProperties_ReturnsPublishedProps;
    [Test]
    procedure TestGetValue_Integer_Roundtrip;
    [Test]
    procedure TestGetValue_String_Roundtrip;
    [Test]
    procedure TestGetValue_Currency_Roundtrip;
    [Test]
    procedure TestMissingM_RaisesEModernRTTIError;

    /// <summary>
    ///   Cenario Delphi-only: TModernRTTIField e GetFields nao existem
    ///   no FPC 3.2.2 (D12 do ADR). Nao ha versao compartilhada.
    /// </summary>
    [Test]
    procedure TestGetFields_ReturnsFields;
  end;

implementation

uses
  SysUtils;

procedure TTestModernRTTI.Setup;
begin
end;

procedure TTestModernRTTI.TearDown;
begin
end;

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

procedure TTestModernRTTI.TestGetFields_ReturnsFields;
var
  LFields: TArray<TModernRTTIField>;
begin
  LFields := TModernRTTI.GetType(TFieldFixture).GetFields;
  Assert.IsTrue(Length(LFields) >= 2,
    Format('GetFields devolveu %d campos; esperado ao menos 2', [Length(LFields)]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestModernRTTI);

end.
