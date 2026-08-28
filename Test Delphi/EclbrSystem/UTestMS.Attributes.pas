(*
  ------------------------------------------------------------------------------
  ModernSyntax — DUnitX shell for ModernSyntax.Attributes tests (Delphi).

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Casca fina. Cada [Test] delega ao cenario compartilhado em uma linha.
  Testes Delphi-only (dependentes de `[MyAttr]` nativo) ficam atras de
  {$IFDEF HAS_NATIVE_ATTRS} — simbolo de *capacidade*, definido no
  UTestMS.Attributes.Symbols.inc.
  ------------------------------------------------------------------------------
*)

unit UTestMS.Attributes;

interface

{$I UTestMS.Attributes.Symbols.inc}
{$IF NOT DEFINED(HAS_NATIVE_ATTRS) AND NOT DEFINED(NO_NATIVE_ATTRS)}
  {$MESSAGE FATAL 'UTestMS.Attributes.Symbols.inc nao foi incluido'}
{$IFEND}

uses
  DUnitX.TestFramework,
  UTestMS.Attributes.Scenarios,
  ModernSyntax.Attributes;

type
  {$IFDEF HAS_NATIVE_ATTRS}
  // Classe local usada apenas nos testes Delphi-only. A anotacao nativa
  // [TMyAttr('nat')] fica aqui — nao pode viver na shared (ver esp CA-4).
  [TMyAttr('nat')]
  TClasseNativa = class(TObject);
  {$ENDIF}

  [TestFixture]
  TAttributesTests = class
  public
    [Test] procedure Register_ThenGetAttributes_ReturnsRegistered;
    [Test] procedure GetAttributes_NeverRegistered_ReturnsEmpty;
    [Test] procedure Register_SameInstanceTwice_IsDeduplicated;
    [Test] procedure Register_TwoInstances_BothAppear;
    [Test] procedure NativePlusRegister_IsIdentical;
    {$IFDEF HAS_NATIVE_ATTRS}
    [Test] procedure TestDelphi_NativeAlone_NoRegister_ReturnsNonEmpty;
    [Test] procedure TestDelphi_NativeSuppressedByRegistered_ReturnsRegisteredOnly;
    {$ENDIF}
  end;

implementation

uses
  SysUtils;

{ TAttributesTests }

procedure TAttributesTests.Register_ThenGetAttributes_ReturnsRegistered;
begin
  Scenario_Register_ThenGetAttributes_ReturnsRegistered;
end;

procedure TAttributesTests.GetAttributes_NeverRegistered_ReturnsEmpty;
begin
  Scenario_GetAttributes_NeverRegistered_ReturnsEmpty;
end;

procedure TAttributesTests.Register_SameInstanceTwice_IsDeduplicated;
begin
  Scenario_Register_SameInstanceTwice_IsDeduplicated;
end;

procedure TAttributesTests.Register_TwoInstances_BothAppear;
begin
  Scenario_Register_TwoInstances_BothAppear;
end;

procedure TAttributesTests.NativePlusRegister_IsIdentical;
begin
  Scenario_NativePlusRegister_IsIdentical;
end;

{$IFDEF HAS_NATIVE_ATTRS}
procedure TAttributesTests.TestDelphi_NativeAlone_NoRegister_ReturnsNonEmpty;
var
  LResult: TArray<TObject>;
begin
  // TClasseNativa esta anotada com [TMyAttr('nat')]; sem Register previo,
  // GetAttributes deve devolver a instancia nativa vinda do TRttiContext
  // interno.
  LResult := ModernAttributes.GetAttributes(TClasseNativa);
  if Length(LResult) < 1 then
    raise ETestScenarioFailed.Create('native attribute not surfaced');
end;

procedure TAttributesTests.TestDelphi_NativeSuppressedByRegistered_ReturnsRegisteredOnly;
var
  LResult: TArray<TObject>;
begin
  // Regra 2 do ADENDO: com Register de TMyAttr, a nativa (mesma classe)
  // e descartada. Resultado: 1 entrada, Tag = 'reg'.
  ModernAttributes.Register(TClasseNativa, [TMyAttr.Create('reg')]);
  LResult := ModernAttributes.GetAttributes(TClasseNativa);
  if Length(LResult) <> 1 then
    raise ETestScenarioFailed.CreateFmt(
      'expected 1 entry (registered wins), got %d', [Length(LResult)]);
  if not (LResult[0] is TMyAttr) then
    raise ETestScenarioFailed.Create('entry is not TMyAttr');
  if TMyAttr(LResult[0]).Tag <> 'reg' then
    raise ETestScenarioFailed.CreateFmt(
      'expected tag "reg", got "%s"', [TMyAttr(LResult[0]).Tag]);
end;
{$ENDIF}

initialization
  TDUnitX.RegisterTestFixture(TAttributesTests);

end.
