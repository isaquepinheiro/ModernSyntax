program PTestModernRTTI;

{$MODE DELPHI}{$H+}

// Minimal FPC runner for the ModernRTTI Pillar 1 test suite.
// Uses DUnitX (VSoftTechnologies/DUnitX has FPC support in Delphi mode);
// the LPI must add the DUnitX source path to its 'Unit Files' (OtherUnitFiles).
// If issue #7 has already provided a shared Test Lazarus/.lpi, this project
// should be merged with it rather than kept as a separate runner.

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  UTestMS.RTTI,
  ModernSyntax.RTTI;

var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
begin
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.FailsOnNoAsserts := False;
    LLogger := TDUnitXConsoleLogger.Create(False);
    LRunner.AddLogger(LLogger);
    LResults := LRunner.Execute;
    if not LResults.AllPassed then
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
end.
