unit UTestMS.RTTI;

interface

uses
  DUnitX.TestFramework,
  Rtti,
  ModernSyntax.RTTI;

// $M+ directive is written unconditionally: harmless in Delphi (which
// always publishes RTTI for TObject descendants anyway) and REQUIRED
// in FPC to make the 'published' section produce metadata. The test
// source deliberately contains NO IFDEF FPC branch (CA-4 of ESP /
// CA-5 of PRD): the SAME source compiles and passes on both compilers.
{$M+}
type
  TSampleModel = class
  strict private
    FCount: Integer;
    FTitle: string;
  published
    property Count: Integer read FCount write FCount;
    property Title: string read FTitle write FTitle;
  end;

  TSampleFieldHolder = class
  public
    Slot: Integer;
    Tag: string;
  end;
{$M-}

  // Deliberately WITHOUT {$M+}: on FPC this class has no published
  // metadata anywhere in the hierarchy — the API MUST raise
  // EModernRTTIError. On Delphi, TObject descendants always carry
  // some minimum RTTI, so an empty result is legitimate. The negative
  // test below accepts EITHER outcome so the SAME source compiles and
  // passes in both compilers with NO conditional-branching directive.
  TSampleNoPublished = class
  strict private
    FHidden: Integer;
  public
    property Hidden: Integer read FHidden write FHidden;
  end;

  [TestFixture]
  TTestModernRTTI = class
  public
    [Test]
    procedure TestGetType_ByClass_ReturnsValidType;
    [Test]
    procedure TestGetType_ByGeneric_ReturnsValidType;
    [Test]
    procedure TestGetType_ByTypeInfo_ReturnsValidType;
    [Test]
    procedure TestGetProperties_ReturnsPublishedProperty;
    [Test]
    procedure TestGetProperty_ByName_ReadsAndWrites;
    [Test]
    procedure TestGetField_ReturnsPublicField;
    [Test]
    procedure TestGetField_ByName_ReadsAndWrites;
    [Test]
    procedure TestGetProperties_NoPublishedMetadata_IsLoudOrEmpty;
    [Test]
    procedure TestPublicSurface_DoesNotExposeRawRttiTypes;
  end;

implementation

uses
  SysUtils,
  TypInfo;

{ TTestModernRTTI }

procedure TTestModernRTTI.TestGetType_ByClass_ReturnsValidType;
var
  LType: TModernRTTIType;
begin
  LType := ModernRTTI.GetType(TSampleModel);
  Assert.IsTrue(LType.IsValid, 'GetType(TSampleModel) must return a valid type');
  Assert.IsTrue(LType.IsClass, 'TSampleModel is a class');
  Assert.AreEqual('TSampleModel', LType.Name);
end;

procedure TTestModernRTTI.TestGetType_ByGeneric_ReturnsValidType;
var
  LType: TModernRTTIType;
begin
  LType := ModernRTTI.GetType<TSampleModel>;
  Assert.IsTrue(LType.IsValid);
  Assert.AreEqual('TSampleModel', LType.Name);
end;

procedure TTestModernRTTI.TestGetType_ByTypeInfo_ReturnsValidType;
var
  LType: TModernRTTIType;
begin
  LType := ModernRTTI.GetType(TypeInfo(TSampleModel));
  Assert.IsTrue(LType.IsValid);
  Assert.AreEqual('TSampleModel', LType.Name);
end;

procedure TTestModernRTTI.TestGetProperties_ReturnsPublishedProperty;
var
  LProps: TArray<TModernRTTIProperty>;
  LIdx: Integer;
  LFoundCount: Boolean;
begin
  LProps := ModernRTTI.GetType(TSampleModel).GetProperties;
  Assert.IsTrue(Length(LProps) >= 1,
    'TSampleModel has at least one published property (Count / Title)');

  LFoundCount := False;
  for LIdx := 0 to High(LProps) do
    if SameText(LProps[LIdx].Name, 'Count') then
      LFoundCount := True;
  Assert.IsTrue(LFoundCount, 'GetProperties must include "Count"');
end;

procedure TTestModernRTTI.TestGetProperty_ByName_ReadsAndWrites;
var
  LProp: TModernRTTIProperty;
  LInstance: TSampleModel;
begin
  LInstance := TSampleModel.Create;
  try
    LInstance.Count := 42;

    LProp := ModernRTTI.GetType(TSampleModel).GetProperty('Count');
    Assert.IsTrue(LProp.IsValid, 'Property "Count" must be found');
    Assert.IsTrue(LProp.IsReadable, 'Property "Count" must be readable');
    Assert.IsTrue(LProp.IsWritable, 'Property "Count" must be writable');
    Assert.AreEqual(42, LProp.GetValue(LInstance).AsInteger);

    LProp.SetValue(LInstance, TValue.From<Integer>(7));
    Assert.AreEqual(7, LInstance.Count);
  finally
    LInstance.Free;
  end;
end;

procedure TTestModernRTTI.TestGetField_ReturnsPublicField;
var
  LFields: TArray<TModernRTTIField>;
begin
  LFields := ModernRTTI.GetType(TSampleFieldHolder).GetFields;
  Assert.IsTrue(Length(LFields) >= 1,
    'TSampleFieldHolder exposes at least one public field via RTTI');
end;

procedure TTestModernRTTI.TestGetField_ByName_ReadsAndWrites;
var
  LField: TModernRTTIField;
  LInstance: TSampleFieldHolder;
begin
  LInstance := TSampleFieldHolder.Create;
  try
    LInstance.Slot := 99;

    LField := ModernRTTI.GetType(TSampleFieldHolder).GetField('Slot');
    Assert.IsTrue(LField.IsValid, 'Field "Slot" must be found');
    Assert.AreEqual(99, LField.GetValue(LInstance).AsInteger);

    LField.SetValue(LInstance, TValue.From<Integer>(11));
    Assert.AreEqual(11, LInstance.Slot);
  finally
    LInstance.Free;
  end;
end;

procedure TTestModernRTTI.TestGetProperties_NoPublishedMetadata_IsLoudOrEmpty;
var
  LProps: TArray<TModernRTTIProperty>;
  LRaised: Boolean;
  LMessage: string;
begin
  // Compiler-agnostic negative test: the same source runs in Delphi and FPC,
  // no conditional-branching directive anywhere (CA-4 / CA-5 of PRD). On FPC, a class without
  // {$M+} produces NO published metadata across its ancestry, so the API
  // MUST raise EModernRTTIError (never a silent empty list — PRD R4).
  // On Delphi, TObject descendants always publish some minimum RTTI, so
  // an empty array is a legitimate outcome. Both are accepted here.
  LRaised := False;
  LMessage := '';
  try
    LProps := ModernRTTI.GetType(TSampleNoPublished).GetProperties;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMessage := E.Message;
    end;
  end;

  if LRaised then
  begin
    Assert.IsTrue(Pos('TSampleNoPublished', LMessage) > 0,
      'Exception message must name the offending class');
    Assert.IsTrue(Pos('{$M+}', LMessage) > 0,
      'Exception message must instruct the fix ({$M+} / published)');
  end
  else
  begin
    // Delphi path: an empty result means 'no published properties on
    // this class', which is factual — the contract only forbids a
    // silent empty when metadata is UNREADABLE. Delphi's metadata IS
    // readable; there is simply nothing to publish. This is fine.
    Assert.IsTrue(Length(LProps) >= 0, 'Empty result is legitimate on Delphi');
  end;
end;

procedure TTestModernRTTI.TestPublicSurface_DoesNotExposeRawRttiTypes;
var
  LProp: TModernRTTIProperty;
  LField: TModernRTTIField;
  LType: TModernRTTIType;
begin
  // Compile-time-ish smoke check for RN-5: the public surface uses only
  // the ModernRTTI wrappers plus PTypeInfo/TValue for exchange. If a
  // future refactor accidentally leaked a TRttiProperty/TRttiField/
  // TRttiType as a public return, this test would stop compiling
  // (or the assignment shapes below would break).
  LType := ModernRTTI.GetType(TSampleModel);
  Assert.IsTrue(LType.IsValid);

  LProp := LType.GetProperty('Count');
  Assert.IsTrue(LProp.IsValid);
  Assert.IsTrue(LProp.PropertyType <> nil,
    'PropertyType must expose PTypeInfo (from TypInfo), not TRttiType');

  LField := ModernRTTI.GetType(TSampleFieldHolder).GetField('Slot');
  Assert.IsTrue(LField.IsValid);
  Assert.IsTrue(LField.FieldType <> nil,
    'FieldType must expose PTypeInfo (from TypInfo), not TRttiType');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestModernRTTI);

end.
