(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  UTestMS.RTTI (Delphi) — casca fina DUnitX para Pilar 1 + Pilar 4 do
  ModernRTTI (issues #8, #21, #25).

  Cada [Test] chama exatamente uma linha util. TestGetFields_ReturnsFields
  usa fixture Delphi-only com campos `public` (nao `published`) — este
  caminho a vmtFieldTable do FPC nao ve por design (§2 do ESP issue #21),
  portanto nao existe cenario compartilhado equivalente e este [Test]
  verifica GetFields diretamente. Zero diretiva por compilador neste
  arquivo (CA-5 do PRD / ESP).
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
    ///   Delphi-only: fixture usa campos `public` (nao published), que a
    ///   vmtFieldTable do FPC nao enumera por design. TModernRTTIField
    ///   e TModernRTTIType.GetFields sao portaveis desde a issue #21;
    ///   este [Test] cobre o caminho especifico de campos non-published
    ///   que so o Delphi ve. Nao ha cenario compartilhado equivalente.
    /// </summary>
    [Test]
    procedure TestGetFields_ReturnsFields;

    // issue #25 — TModernRTTIMethod pela vmtMethodTable.
    [Test]
    procedure TestGetMethods_CountsPublishedInherited_Exact;
    [Test]
    procedure TestGetMethod_ByName_FindsInherited;
    [Test]
    procedure TestMethod_Invoke_NoArgs;

    // issue #26 — TModernValue.AsType<T>. Sete cenarios compartilhados, um
    // por tipo (5 do CA + record + enum). NAO ha equivalente ao teste FPC
    // TestModernValue_AsType_DifferentType_...: no Delphi, tipo diferente
    // pode passar por alargamento nativo do TValue, e testar
    // "levanta OU converte" nao vale nada (D-9 do ADR).
    [Test]
    procedure TestModernValue_AsType_String;
    [Test]
    procedure TestModernValue_AsType_Integer;
    [Test]
    procedure TestModernValue_AsType_Boolean;
    [Test]
    procedure TestModernValue_AsType_Double;
    [Test]
    procedure TestModernValue_AsType_Object;
    [Test]
    procedure TestModernValue_AsType_Record;
    [Test]
    procedure TestModernValue_AsType_Enum;

    // issue #27 — for..in sobre as coleções (cinco comuns + Parameters
    // itera parametros reais no Delphi). O irmao que espera exceção nao e
    // publicado aqui (padrao "dois cenarios distintos + duas cascas" da #25).
    [Test]
    procedure TestFields_ForIn_IteratesFields;
    [Test]
    procedure TestProperties_ForIn_IteratesProperties;
    [Test]
    procedure TestMethods_ForIn_IteratesMethods;
    [Test]
    procedure TestAttributes_ForIn_IteratesAttributes;
    [Test]
    procedure TestEmptyCollection_ForIn_DoesNotLoop;
    [Test]
    procedure TestParameters_ForIn_IteratesRealParameters;

    // issue #28 — TModernRTTIContext. Quatro cenarios (todos exceto
    // EmptyRegistry_Raises — FPC-only na casca, D-28.10 do ADR).
    [Test]
    procedure TestContext_GetTypes_AfterTwoRegisterType_ContainsBoth;
    [Test]
    procedure TestContext_FindType_Class_Found;
    [Test]
    procedure TestContext_FindType_NotFound_ReturnsNil;
    [Test]
    procedure TestContext_CopyByValue_SharesState_NoUseAfterFree;

    // issue #42 — TModernVisibility. Method_Visibility_Delphi_Returns_
    // mvPublished e o par Delphi-only (D-42.2). O irmao FPC-only
    // (Method_Visibility_FPC_Raises) NAO e publicado aqui.
    // Property_Visibility_Returns_mvPublished e cross-compiler (D-42.7).
    [Test]
    procedure TestMethod_Visibility_Delphi_Returns_mvPublished;
    [Test]
    procedure TestProperty_Visibility_Returns_mvPublished;

    // issue #43 — TModernRTTIEnumerationType. Quatro cenarios compartilhados
    // (paridade estrita com o FPC — mesmos nomes, mesmo Fail em quebra).
    [Test]
    procedure TestEnumerationType_NameAndBounds;
    [Test]
    procedure TestEnumerationType_GetNameGetValue;
    [Test]
    procedure TestEnumerationType_GetNames_LengthAndPresence;
    [Test]
    procedure TestEnumerationType_OutOfRangeAndUnknownRaises;

    // issue #44 — TModernRTTIPointerType. Duas cascas [Test] delegando
    // ao cenario compartilhado (padrao "um cenario, duas cascas").
    [Test]
    procedure TestPointerType_ReferredType_Matches;
    [Test]
    procedure TestPointerType_ReferredType_Nil_ForBarePointer;

    // issue #45 — TModernRTTIRecordType. UMA unica [Test] (D-7 "um cenario,
    // duas cascas") delegando ao cenario compartilhado; quatro assercões
    // internas (Name+Size por fixture).
    [Test]
    procedure TestRecordType_NameAndSize;

    // issue #46 — TModernRTTIArrayType + TModernRTTISetType. QUATRO [Test]
    // delegando aos cenarios compartilhados (padrao "um cenario, duas
    // cascas"). Contagem passa de 35 -> 39 [Test].
    [Test]
    procedure TestArrayType_Static_LengthAndSize;
    [Test]
    procedure TestArrayType_Dynamic_LengthRaises;
    [Test]
    procedure TestArrayType_Dynamic_Managed_ElementType;
    [Test]
    procedure TestSetType_ElementType;

    // issue #49 — contrato de nil-handle em TModernRTTIType. UMA [Test]
    // (D-7 "um cenario, duas cascas") delegando ao cenario compartilhado;
    // internamente afirma EModernRTTIError nos cinco membros afetados.
    [Test]
    procedure TestNilHandle_AllMembers_Raises;
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

procedure TTestModernRTTI.TestParameters_ForIn_IteratesRealParameters;
begin
  Scenario_Parameters_ForIn_IteratesRealParameters;
end;

// --- Issue #28 ---------------------------------------------------------------

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

procedure TTestModernRTTI.TestMethod_Visibility_Delphi_Returns_mvPublished;
begin
  Scenario_Method_Visibility_Delphi_Returns_mvPublished;
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

// --- Issue #45 ---------------------------------------------------------------

procedure TTestModernRTTI.TestRecordType_NameAndSize;
begin
  Scenario_RecordType_NameAndSize;
end;

// --- Issue #46 ---------------------------------------------------------------

procedure TTestModernRTTI.TestArrayType_Static_LengthAndSize;
begin
  Scenario_ArrayType_Static_LengthAndSize;
end;

procedure TTestModernRTTI.TestArrayType_Dynamic_LengthRaises;
begin
  Scenario_ArrayType_Dynamic_LengthRaises;
end;

procedure TTestModernRTTI.TestArrayType_Dynamic_Managed_ElementType;
begin
  Scenario_ArrayType_Dynamic_Managed_ElementType;
end;

procedure TTestModernRTTI.TestSetType_ElementType;
begin
  Scenario_SetType_ElementType;
end;

// --- Issue #49 ---------------------------------------------------------------

procedure TTestModernRTTI.TestNilHandle_AllMembers_Raises;
begin
  Scenario_NilHandle_AllMembers_Raises;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestModernRTTI);

end.
