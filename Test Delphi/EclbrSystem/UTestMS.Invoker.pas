(*
  ------------------------------------------------------------------------------
  UTestMS.Invoker — casca fina DUnitX do TModernInvoker (issues #10 + #13)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Cada [Test] tem uma linha util: delega no Case_... da unit compartilhada
  UTestMS.Invoker.Cases.pas. A logica dos cenarios NAO mora aqui.

  Assimetria D-13.3: esta casca registra
  InvokeDynamic_PublicWithoutMPlus_OKOnDelphi (Delphi enxerga public via
  TRttiContext); NAO registra _RaisesOnFPC (esse cabe a casca FPCUnit).
  ------------------------------------------------------------------------------
*)

unit UTestMS.Invoker;

interface

uses
  DUnitX.TestFramework,
  UTestMS.Invoker.Cases,
  ModernSyntax.Invoker;

type
  [TestFixture]
  TInvokerTests = class
  public
    [Test]
    procedure Invoke_InstanceMethod_ReturnsValue;
    [Test]
    procedure TypedMethod_CalledWithArgs_ReturnsExpected;
    [Test]
    procedure Invoke_ClassMethod_Works;
    [Test]
    procedure Invoke_MethodNotFound_RaisesWithActionableMessage;
    [Test]
    procedure Invoke_NilInstance_Raises;
    [Test]
    procedure Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
    [Test]
    procedure Invoke_NonMethodSignature_Raises;
    [Test]
    procedure InvokeDynamic_ReturnsRecordIntegerAndString;
    [Test]
    procedure InvokeDynamic_ReturnsDouble;
    [Test]
    procedure InvokeDynamic_ReturnsManagedString;
    [Test]
    procedure InvokeDynamic_ProcedureVoid_SideEffect;
    [Test]
    procedure InvokeDynamic_NilInstance_Raises;
    [Test]
    procedure InvokeDynamic_MethodNotFound_RaisesInstructive;
    [Test]
    procedure InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
  end;

implementation

procedure TInvokerTests.Invoke_InstanceMethod_ReturnsValue;
begin
  Case_Invoke_InstanceMethod_ReturnsValue;
end;

procedure TInvokerTests.TypedMethod_CalledWithArgs_ReturnsExpected;
begin
  Case_TypedMethod_CalledWithArgs_ReturnsExpected;
end;

procedure TInvokerTests.Invoke_ClassMethod_Works;
begin
  Case_Invoke_ClassMethod_Works;
end;

procedure TInvokerTests.Invoke_MethodNotFound_RaisesWithActionableMessage;
begin
  Case_Invoke_MethodNotFound_RaisesWithActionableMessage;
end;

procedure TInvokerTests.Invoke_NilInstance_Raises;
begin
  Case_Invoke_NilInstance_Raises;
end;

procedure TInvokerTests.Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
begin
  Case_Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
end;

procedure TInvokerTests.Invoke_NonMethodSignature_Raises;
begin
  Case_Invoke_NonMethodSignature_Raises;
end;

procedure TInvokerTests.InvokeDynamic_ReturnsRecordIntegerAndString;
begin
  Case_InvokeDynamic_ReturnsRecordIntegerAndString;
end;

procedure TInvokerTests.InvokeDynamic_ReturnsDouble;
begin
  Case_InvokeDynamic_ReturnsDouble;
end;

procedure TInvokerTests.InvokeDynamic_ReturnsManagedString;
begin
  Case_InvokeDynamic_ReturnsManagedString;
end;

procedure TInvokerTests.InvokeDynamic_ProcedureVoid_SideEffect;
begin
  Case_InvokeDynamic_ProcedureVoid_SideEffect;
end;

procedure TInvokerTests.InvokeDynamic_NilInstance_Raises;
begin
  Case_InvokeDynamic_NilInstance_Raises;
end;

procedure TInvokerTests.InvokeDynamic_MethodNotFound_RaisesInstructive;
begin
  Case_InvokeDynamic_MethodNotFound_RaisesInstructive;
end;

procedure TInvokerTests.InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
begin
  Case_InvokeDynamic_PublicWithoutMPlus_OKOnDelphi;
end;

initialization
  TDUnitX.RegisterTestFixture(TInvokerTests);

end.
