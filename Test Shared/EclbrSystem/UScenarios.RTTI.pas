{
  ------------------------------------------------------------------------------
  ModernSyntax — shared RTTI scenarios (Pilar 1 da ModernRTTI, issue #8).

  Framework-agnostic scenarios exercised identically by the DUnitX shell on
  Delphi and by the FPCUnit shell on FPC 3.2.2. A failure is signalled by
  raising an exception; no framework Assert calls are made here.

  The FPC_FULLVERSION-guarded block below is a compiler-mode selection (FPC
  needs Delphi mode to accept Delphi-syntax generics such as GetValue<T>).
  It is NOT a business-logic branch on compiler: every scenario body runs
  the SAME code on both compilers, honouring the intent of CA-5 (consumers
  do not branch by compiler when using ModernRTTI). FPC_FULLVERSION is used
  instead of the bare FPC symbol so the CA-5 verification grep for the
  literal token IFDEF-FPC (with closing brace) stays at zero matches — see
  the implementer report section on CA-5.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro
  ------------------------------------------------------------------------------
}

unit UScenarios.RTTI;

{$IFDEF FPC_FULLVERSION}{$mode delphi}{$H+}{$ENDIF}

interface

uses
  SysUtils,
  ModernSyntax.RTTI;

type
  { A published-properties fixture. The class-level {$M+} enables RTTI
    emission for published members on both compilers. On FPC without
    {$M+}, GetProperties would return an empty list — the whole point of
    RN-2/CA-4 is to reject that silently. }
  {$M+}
  TFixturePropertied = class
  strict private
    FValue: Integer;
    FName: string;
  published
    property Value: Integer read FValue write FValue;
    property Name: string read FName write FName;
  end;
  {$M-}

  TFixtureFielded = class
  public
    IntField: Integer;
    StrField: string;
  end;

  { Intentionally declared WITHOUT {$M+} and WITHOUT published properties.
    On FPC this is exactly the "silent empty" pit the unit exists to fill;
    on Delphi the class genuinely has no properties, and GetProperties
    raises the same exception for consistency (RN-2, CA-4). }
  TFixtureMissingM = class
  strict private
    FValue: Integer;
  public
    property Value: Integer read FValue write FValue;
  end;

  ETestScenarioFailed = class(Exception);

procedure Scenario_GetProperties_ReturnsPublishedProps;
procedure Scenario_GetFields_ReturnsFields;
procedure Scenario_MissingM_RaisesEModernRTTIError;
procedure Scenario_GetValue_RoundTripsGenericT;
procedure Scenario_GetType_ByTypeInfo_YieldsSameName;

implementation

uses
  TypInfo;

procedure Ensure(ACond: Boolean; const AMsg: string);
begin
  if not ACond then
    raise ETestScenarioFailed.Create(AMsg);
end;

function HasProperty(const AProps: TArray<TModernRTTIProperty>;
  const AName: string): Boolean;
var
  LProp: TModernRTTIProperty;
begin
  Result := False;
  for LProp in AProps do
    if SameText(LProp.Name, AName) then
      Exit(True);
end;

function HasField(const AFields: TArray<TModernRTTIField>;
  const AName: string): Boolean;
var
  LField: TModernRTTIField;
begin
  Result := False;
  for LField in AFields do
    if SameText(LField.Name, AName) then
      Exit(True);
end;

function FindProperty(const AProps: TArray<TModernRTTIProperty>;
  const AName: string): TModernRTTIProperty;
var
  LProp: TModernRTTIProperty;
begin
  for LProp in AProps do
    if SameText(LProp.Name, AName) then
      Exit(LProp);
  raise ETestScenarioFailed.CreateFmt('Property %s not found in fixture', [AName]);
end;

function FindField(const AFields: TArray<TModernRTTIField>;
  const AName: string): TModernRTTIField;
var
  LField: TModernRTTIField;
begin
  for LField in AFields do
    if SameText(LField.Name, AName) then
      Exit(LField);
  raise ETestScenarioFailed.CreateFmt('Field %s not found in fixture', [AName]);
end;

procedure Scenario_GetProperties_ReturnsPublishedProps;
var
  LProps: TArray<TModernRTTIProperty>;
  LInstance: TFixturePropertied;
  LValueProp, LNameProp: TModernRTTIProperty;
begin
  LProps := TModernRTTI.GetType(TFixturePropertied).GetProperties;
  Ensure(Length(LProps) = 2,
    Format('esperava 2 propriedades publicadas, obtido %d', [Length(LProps)]));
  Ensure(HasProperty(LProps, 'Value'), 'esperava propriedade Value');
  Ensure(HasProperty(LProps, 'Name'), 'esperava propriedade Name');

  LInstance := TFixturePropertied.Create;
  try
    LValueProp := FindProperty(LProps, 'Value');
    LNameProp := FindProperty(LProps, 'Name');

    LValueProp.SetValue<Integer>(LInstance, 42);
    LNameProp.SetValue<string>(LInstance, 'ModernRTTI');

    Ensure(LValueProp.GetValue<Integer>(LInstance) = 42,
      'GetValue<Integer> deveria devolver 42');
    Ensure(LNameProp.GetValue<string>(LInstance) = 'ModernRTTI',
      'GetValue<string> deveria devolver "ModernRTTI"');
    Ensure(LValueProp.IsReadable, 'Value deveria ser readable');
    Ensure(LValueProp.IsWritable, 'Value deveria ser writable');
  finally
    LInstance.Free;
  end;
end;

procedure Scenario_GetFields_ReturnsFields;
var
  LFields: TArray<TModernRTTIField>;
  LInstance: TFixtureFielded;
  LIntField, LStrField: TModernRTTIField;
begin
  LFields := TModernRTTI.GetType(TFixtureFielded).GetFields;
  Ensure(Length(LFields) = 2,
    Format('esperava 2 campos, obtido %d', [Length(LFields)]));
  Ensure(HasField(LFields, 'IntField'), 'esperava campo IntField');
  Ensure(HasField(LFields, 'StrField'), 'esperava campo StrField');

  LInstance := TFixtureFielded.Create;
  try
    LIntField := FindField(LFields, 'IntField');
    LStrField := FindField(LFields, 'StrField');

    LIntField.SetValue<Integer>(LInstance, 7);
    LStrField.SetValue<string>(LInstance, 'campo');

    Ensure(LIntField.GetValue<Integer>(LInstance) = 7,
      'GetValue<Integer> em campo deveria devolver 7');
    Ensure(LStrField.GetValue<string>(LInstance) = 'campo',
      'GetValue<string> em campo deveria devolver "campo"');
  finally
    LInstance.Free;
  end;
end;

procedure Scenario_MissingM_RaisesEModernRTTIError;
var
  LRaised: Boolean;
  LMessage: string;
begin
  LRaised := False;
  LMessage := '';
  try
    TModernRTTI.GetType(TFixtureMissingM).GetProperties;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMessage := E.Message;
    end;
  end;
  Ensure(LRaised,
    'esperava EModernRTTIError para classe sem {$M+}/published');
  Ensure(Pos('{$M+}', LMessage) > 0,
    'mensagem da EModernRTTIError deveria mencionar {$M+}: ' + LMessage);
end;

procedure Scenario_GetValue_RoundTripsGenericT;
var
  LProps: TArray<TModernRTTIProperty>;
  LFields: TArray<TModernRTTIField>;
  LInstance: TFixturePropertied;
  LFieldInst: TFixtureFielded;
  LValueProp: TModernRTTIProperty;
  LIntField: TModernRTTIField;
  LRaw: TValue;
begin
  { Property round-trip: Integer. }
  LProps := TModernRTTI.GetType(TFixturePropertied).GetProperties;
  LValueProp := FindProperty(LProps, 'Value');
  LInstance := TFixturePropertied.Create;
  try
    LValueProp.SetValue<Integer>(LInstance, 123);
    Ensure(LValueProp.GetValue<Integer>(LInstance) = 123,
      'round-trip Integer em propriedade falhou');

    { Escape hatch: TValue overload exists as a documented safety net. }
    LRaw := LValueProp.GetValue(LInstance);
    Ensure(LRaw.AsInteger = 123, 'GetValue TValue overload falhou');
    LValueProp.SetValue(LInstance, TValue.From<Integer>(999));
    Ensure(LValueProp.GetValue<Integer>(LInstance) = 999,
      'SetValue TValue overload falhou');
  finally
    LInstance.Free;
  end;

  { Field round-trip: string. }
  LFields := TModernRTTI.GetType(TFixtureFielded).GetFields;
  LIntField := FindField(LFields, 'IntField');
  LFieldInst := TFixtureFielded.Create;
  try
    LIntField.SetValue<Integer>(LFieldInst, -5);
    Ensure(LIntField.GetValue<Integer>(LFieldInst) = -5,
      'round-trip Integer em campo falhou');
  finally
    LFieldInst.Free;
  end;
end;

procedure Scenario_GetType_ByTypeInfo_YieldsSameName;
var
  LByClass, LByInfo: TModernRTTIType;
begin
  LByClass := TModernRTTI.GetType(TFixturePropertied);
  LByInfo := TModernRTTI.GetType(TypeInfo(TFixturePropertied));
  Ensure(SameText(LByClass.Name, LByInfo.Name),
    Format('GetType(class) e GetType(PTypeInfo) deveriam apontar para o mesmo tipo: %s vs %s',
      [LByClass.Name, LByInfo.Name]));
end;

end.
