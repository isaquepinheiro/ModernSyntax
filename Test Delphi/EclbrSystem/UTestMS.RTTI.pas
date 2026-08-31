(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  UTestMS.RTTI (Delphi) — casca fina DUnitX para Pilar 1/4 ModernRTTI
  (issues #8 e #25).

  Cada [Test] chama exatamente uma linha util. TestGetFields e Delphi-only:
  o backend FPC de TModernRTTIField levanta EModernRTTIError (D-25.4 do ADR)
  porque vFieldTable no FPC 3.2.2 nao e populada para classes gerais; a
  superficie publica existe nos dois compiladores, mas so o Delphi devolve
  dado real. Nao ha cenario compartilhado para esse caso, por isso este
  [Test] invoca GetFields diretamente e verifica com asserts.
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
    ///   Cenario Delphi-only: TModernRTTIField expoe superficie unificada
    ///   nos dois compiladores (D-25.1), mas o backend FPC 3.2.2 levanta
    ///   EModernRTTIError porque vFieldTable nao e populada para classes
    ///   gerais (D-25.4). Nao ha versao compartilhada.
    /// </summary>
    [Test]
    procedure TestGetFields_ReturnsFields;

    // issue #25 — TModernRTTIMethod (uma linha util cada)
    [Test]
    procedure TestGetMethods_CountsPublishedInherited_Exact;
    [Test]
    procedure TestGetMethod_ByName_FindsInherited;
    [Test]
    procedure TestMethod_Invoke_NoArgs;
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

procedure TTestModernRTTI.TestGetMethods_CountsPublishedInherited_Exact;
begin
  Scenario_GetMethods_CountsPublishedInherited_Exact;
end;

procedure TTestModernRTTI.TestGetMethod_ByName_FindsInherited;
begin
  Scenario_GetMethod_ByName_FindsInherited;
end;

procedure TTestModernRTTI.TestMethod_Invoke_NoArgs;
begin
  Scenario_Method_Invoke_NoArgs;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestModernRTTI);

end.
