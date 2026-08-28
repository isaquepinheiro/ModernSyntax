(*
  ------------------------------------------------------------------------------
  UTestMS.Invoker — casca fina DUnitX do TModernInvoker (issue #10)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Cada [Test] tem uma linha util: delega no Case_... da unit compartilhada
  UTestMS.Invoker.Cases.pas. A logica dos cenarios NAO mora aqui.
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

initialization
  TDUnitX.RegisterTestFixture(TInvokerTests);

end.
