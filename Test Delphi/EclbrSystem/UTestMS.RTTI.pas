unit UTestMS.RTTI;

interface

uses
  DUnitX.TestFramework,
  UScenarios.RTTI;

type
  [TestFixture]
  TRTTITests = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure GetProperties_ReturnsPublishedProps;
    [Test]
    procedure GetFields_ReturnsFields;
    [Test]
    procedure MissingM_RaisesEModernRTTIError;
    [Test]
    procedure GetValue_RoundTripsGenericT;
    [Test]
    procedure GetType_ByTypeInfo_YieldsSameName;
  end;

implementation

procedure TRTTITests.Setup;
begin
end;

procedure TRTTITests.TearDown;
begin
end;

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
  TDUnitX.RegisterTestFixture(TRTTITests);

end.
