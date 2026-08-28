program PTestInvoker;

{$mode objfpc}{$H+}

uses
  consoletestrunner,
  UTestMS.Invoker,
  UTestMS.Invoker.Cases,
  ModernSyntax.Invoker;

type
  TAppRunner = class(TTestRunner);

var
  App: TAppRunner;
begin
  App := TAppRunner.Create(nil);
  App.Title := 'PTestInvoker';
  App.Run;
  App.Free;
end.
