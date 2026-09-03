(*
  ------------------------------------------------------------------------------
  UTestMS.Invoker — casca fina FPCUnit do TModernInvoker (issues #10 + #13)

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Cada metodo published tem uma linha util: delega no Case_... da unit
  compartilhada UTestMS.Invoker.Cases.pas. A logica dos cenarios NAO mora
  aqui.

  Assimetria D-13.3: esta casca registra
  InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC (o FPC nao acha o metodo
  sem {$M+}); NAO registra _OKOnDelphi (esse cabe a casca DUnitX).
  ------------------------------------------------------------------------------
*)

unit UTestMS.Invoker;

{$mode delphi}{$H+}

interface

uses
  fpcunit,
  testregistry,
  UTestMS.Invoker.Cases,
  ModernSyntax.Invoker;

type
  TInvokerTests = class(TTestCase)
  published
    procedure Invoke_InstanceMethod_ReturnsValue;
    procedure TypedMethod_CalledWithArgs_ReturnsExpected;
    procedure Invoke_ClassMethod_Works;
    procedure Invoke_MethodNotFound_RaisesWithActionableMessage;
    procedure Invoke_NilInstance_Raises;
    procedure Invoke_PublicMethodWithoutMPlus_RaisesNotFound;
    procedure Invoke_NonMethodSignature_Raises;
    procedure InvokeDynamic_ReturnsRecordIntegerAndString;
    procedure InvokeDynamic_ReturnsDouble;
    procedure InvokeDynamic_ReturnsManagedString;
    procedure InvokeDynamic_ProcedureVoid_SideEffect;
    procedure InvokeDynamic_NilInstance_Raises;
    procedure InvokeDynamic_MethodNotFound_RaisesInstructive;
    procedure InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
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

procedure TInvokerTests.InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
begin
  Case_InvokeDynamic_PublicWithoutMPlus_RaisesOnFPC;
end;

initialization
  RegisterTest(TInvokerTests);

end.
