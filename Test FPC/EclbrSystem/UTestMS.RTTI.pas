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
    procedure TestGetFields_EnumeratesInheritedPublishedClassFields;
    // issue #25 — TModernRTTIMethod pela vmtMethodTable.
    procedure TestGetMethods_CountsPublishedInherited_Exact;
    procedure TestGetMethod_ByName_FindsInherited;
    procedure TestMethod_Invoke_NoArgs;
    // issue #26 — TModernValue.AsType<T> (5 tipos do CA + record + enum,
    // via cenarios compartilhados) + assercao LOCAL do backend FPC para
    // conversao entre tipos diferentes (D-9 do ADR: valido ate a issue de
    // alargamento ser resolvida — no Delphi nao existe equivalente porque
    // o TValue nativo pode passar por alargamento e "levanta OU converte"
    // nao vale nada como teste).
    procedure TestModernValue_AsType_String;
    procedure TestModernValue_AsType_Integer;
    procedure TestModernValue_AsType_Boolean;
    procedure TestModernValue_AsType_Double;
    procedure TestModernValue_AsType_Object;
    procedure TestModernValue_AsType_Record;
    procedure TestModernValue_AsType_Enum;
    procedure TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination;
    // issue #27 — for..in sobre as coleções (cinco comuns + Parameters
    // raises no FPC). O irmao que itera parametros reais nao e publicado
    // aqui (padrao "dois cenarios distintos + duas cascas" da #25).
    procedure TestFields_ForIn_IteratesFields;
    procedure TestProperties_ForIn_IteratesProperties;
    procedure TestMethods_ForIn_IteratesMethods;
    procedure TestAttributes_ForIn_IteratesAttributes;
    procedure TestEmptyCollection_ForIn_DoesNotLoop;
    procedure TestParameters_ForIn_RaisesOnFPC;
    // issue #28 — TModernRTTIContext. Cinco cenarios; um deles (EmptyRegistry
    // _Raises) e FPC-only na casca porque o pool nativo do Delphi torna
    // registry-vazio impossivel de simular. Padrao "dois cenarios distintos"
    // da #25.
    procedure TestContext_GetTypes_EmptyRegistry_Raises;
    procedure TestContext_GetTypes_AfterTwoRegisterType_ContainsBoth;
    procedure TestContext_FindType_Class_Found;
    procedure TestContext_FindType_NotFound_ReturnsNil;
    procedure TestContext_CopyByValue_SharesState_NoUseAfterFree;
    // issue #42 — TModernVisibility. Method_Visibility_FPC_Raises e o par
    // FPC-only (D-42.5); o irmao Method_Visibility_Delphi_Returns_mvPublished
    // NAO e publicado aqui — casca Delphi so. Property_Visibility_Returns_
    // mvPublished e cross-compiler (D-42.7).
    procedure TestMethod_Visibility_FPC_Raises;
    procedure TestProperty_Visibility_Returns_mvPublished;
    // issue #43 — TModernRTTIEnumerationType. Quatro cenarios compartilhados
    // (tres positivos + um negativo com tres afirmacoes independentes).
    procedure TestEnumerationType_NameAndBounds;
    procedure TestEnumerationType_GetNameGetValue;
    procedure TestEnumerationType_GetNames_LengthAndPresence;
    procedure TestEnumerationType_OutOfRangeAndUnknownRaises;
    // issue #44 — TModernRTTIPointerType. Duas cascas por cenario
    // compartilhado (padrao "um cenario, duas cascas").
    procedure TestPointerType_ReferredType_Matches;
    procedure TestPointerType_ReferredType_Nil_ForBarePointer;
  end;

implementation

uses
  SysUtils,
  ModernSyntax.RTTI;

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

procedure TTestModernRTTI.TestGetFields_EnumeratesInheritedPublishedClassFields;
begin
  Scenario_GetFields_EnumeratesInheritedPublishedClassFields;
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

// --- Issue #26 ---------------------------------------------------------------

procedure TTestModernRTTI.TestModernValue_AsType_String;
begin
  Scenario_ModernValue_AsType_String;
end;

procedure TTestModernRTTI.TestModernValue_AsType_Integer;
begin
  Scenario_ModernValue_AsType_Integer;
end;

procedure TTestModernRTTI.TestModernValue_AsType_Boolean;
begin
  Scenario_ModernValue_AsType_Boolean;
end;

procedure TTestModernRTTI.TestModernValue_AsType_Double;
begin
  Scenario_ModernValue_AsType_Double;
end;

procedure TTestModernRTTI.TestModernValue_AsType_Object;
begin
  Scenario_ModernValue_AsType_Object;
end;

procedure TTestModernRTTI.TestModernValue_AsType_Record;
begin
  Scenario_ModernValue_AsType_Record;
end;

procedure TTestModernRTTI.TestModernValue_AsType_Enum;
begin
  Scenario_ModernValue_AsType_Enum;
end;

procedure TTestModernRTTI.TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination;
var
  LRec: TPonto;
  LValue: TModernValue;
  LRaised: Boolean;
  LMsg: string;
begin
  // D-4 do ADR issue #26: FPC exige tipo exato. Este teste vive AQUI (nao
  // em UScenarios.RTTI.pas — CA-5) porque no Delphi o TValue nativo pode
  // passar por alargamento e "levanta OU converte" nao vale nada.
  // Prova de mutacao (D-4 + SKILL.md:92-97): trocar `if not
  // AValue.IsType(TypeInfo(T))` por `if False` no backend FPC faz este
  // teste falhar. Executar antes de fechar o PR.
  LRec.X := 1;
  LRec.Y := 2;
  LValue := TModernValue.From<TPonto>(LRec);
  LRaised := False;
  LMsg := '';
  try
    LValue.AsType<string>;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  AssertTrue('AsType<string> sobre TValue tipado como TPonto nao levantou EModernRTTIError', LRaised);
  AssertTrue(
    Format('EModernRTTIError sem nome de origem "TPonto" em: "%s"', [LMsg]),
    Pos('TPonto', LMsg) > 0);
  AssertTrue(
    Format('EModernRTTIError sem nome de destino "AnsiString" em: "%s"', [LMsg]),
    Pos('AnsiString', LMsg) > 0);
end;

// --- Issue #27 ---------------------------------------------------------------

procedure TTestModernRTTI.TestFields_ForIn_IteratesFields;
begin
  Scenario_Fields_ForIn_IteratesFields;
end;

procedure TTestModernRTTI.TestProperties_ForIn_IteratesProperties;
begin
  Scenario_Properties_ForIn_IteratesProperties;
end;

procedure TTestModernRTTI.TestMethods_ForIn_IteratesMethods;
begin
  Scenario_Methods_ForIn_IteratesMethods;
end;

procedure TTestModernRTTI.TestAttributes_ForIn_IteratesAttributes;
begin
  Scenario_Attributes_ForIn_IteratesAttributes;
end;

procedure TTestModernRTTI.TestEmptyCollection_ForIn_DoesNotLoop;
begin
  Scenario_EmptyCollection_ForIn_DoesNotLoop;
end;

procedure TTestModernRTTI.TestParameters_ForIn_RaisesOnFPC;
begin
  Scenario_Parameters_ForIn_RaisesOnFPC;
end;

// --- Issue #28 ---------------------------------------------------------------

procedure TTestModernRTTI.TestContext_GetTypes_EmptyRegistry_Raises;
begin
  Scenario_Context_GetTypes_EmptyRegistry_Raises;
end;

procedure TTestModernRTTI.TestContext_GetTypes_AfterTwoRegisterType_ContainsBoth;
begin
  Scenario_Context_GetTypes_AfterTwoRegisterType_ContainsBoth;
end;

procedure TTestModernRTTI.TestContext_FindType_Class_Found;
begin
  Scenario_Context_FindType_Class_Found;
end;

procedure TTestModernRTTI.TestContext_FindType_NotFound_ReturnsNil;
begin
  Scenario_Context_FindType_NotFound_ReturnsNil;
end;

procedure TTestModernRTTI.TestContext_CopyByValue_SharesState_NoUseAfterFree;
begin
  Scenario_Context_CopyByValue_SharesState_NoUseAfterFree;
end;

// --- Issue #42 ---------------------------------------------------------------

procedure TTestModernRTTI.TestMethod_Visibility_FPC_Raises;
begin
  Scenario_Method_Visibility_FPC_Raises;
end;

procedure TTestModernRTTI.TestProperty_Visibility_Returns_mvPublished;
begin
  Scenario_Property_Visibility_Returns_mvPublished;
end;

// --- Issue #43 ---------------------------------------------------------------

procedure TTestModernRTTI.TestEnumerationType_NameAndBounds;
begin
  Scenario_EnumerationType_NameAndBounds;
end;

procedure TTestModernRTTI.TestEnumerationType_GetNameGetValue;
begin
  Scenario_EnumerationType_GetNameGetValue;
end;

procedure TTestModernRTTI.TestEnumerationType_GetNames_LengthAndPresence;
begin
  Scenario_EnumerationType_GetNames_LengthAndPresence;
end;

procedure TTestModernRTTI.TestEnumerationType_OutOfRangeAndUnknownRaises;
begin
  Scenario_EnumerationType_OutOfRangeAndUnknownRaises;
end;

// --- Issue #44 ---------------------------------------------------------------

procedure TTestModernRTTI.TestPointerType_ReferredType_Matches;
begin
  Scenario_PointerType_ReferredType_Matches;
end;

procedure TTestModernRTTI.TestPointerType_ReferredType_Nil_ForBarePointer;
begin
  Scenario_PointerType_ReferredType_Nil_ForBarePointer;
end;

initialization
  RegisterTest(TTestModernRTTI);

end.
