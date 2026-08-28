program PTestAttributes;

{$MODE OBJFPC}{$H+}

uses
  consoletestrunner,
  UTestMS.Attributes,
  UTestMS.Attributes.Scenarios,
  ModernSyntax.Attributes;

type
  TAppRunner = class(TTestRunner);

var
  App: TAppRunner;
begin
  App := TAppRunner.Create(nil);
  App.Title := 'PTestAttributes';
  App.Run;
  App.Free;
end.
