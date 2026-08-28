{
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{
  ModernSyntax.Callback — portable callback foundation for ModernRTTI.

  Provides three GUID-less generic interfaces (IModernFunc<T,R>, IModernProc<T>,
  IModernPredicate<T>) plus the Callback factory record with three overloads of
  &Of accepting method-of-object references. Compiles identically on Delphi XE+
  and FPC 3.2.2 without requiring the consumer to write any {$IFDEF FPC}.

  Design notes:
    * This unit intentionally does NOT include ModernSyntax.inc (see ADR D-A5,
      D-A11 of cycle-003). The include file has a latent typo (the letters of
      the FPC symbol transposed) on line 256; contouring it here keeps this
      foundation independent of that unrelated fix.
    * The interface section uses ONLY SysUtils. Any other unit of the library
      transitively re-introduces `reference to` or the .inc.
    * The method-pointer identifier `&Of` is escaped with the ampersand prefix
      because `of` is a reserved word in Object Pascal. Consumers call it as
      `Callback.&Of(Self.MyMethod)`.
}

unit ModernSyntax.Callback;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  { Contract for a function callback: takes a value of T, returns R. }
  IModernFunc<T, R> = interface
    function Invoke(const AValue: T): R;
  end;

  { Contract for a procedure callback: takes a value of T, returns nothing. }
  IModernProc<T> = interface
    procedure Invoke(const AValue: T);
  end;

  { Contract for a predicate callback: takes a value of T, returns Boolean. }
  IModernPredicate<T> = interface
    function Invoke(const AValue: T): Boolean;
  end;

  { Named method-pointer aliases. Declared in interface so they are visible
    where the Callback record method signatures are declared. Consumers do
    not need to reference these names — Delphi/FPC infer the method pointer
    from the passed expression. }
  TModernFuncMethod<T, R> = function(const AValue: T): R of object;
  TModernProcMethod<T> = procedure(const AValue: T) of object;
  TModernPredicateMethod<T> = function(const AValue: T): Boolean of object;

  { Callback — factory record. Three overloads of &Of, one per contract.
    All three accept a method-of-object reference and return the matching
    interface. Only the interface is exposed; the wrapper class is a
    private implementation detail. }
  Callback = record
  public
    class function &Of<T, R>(const AMethod: TModernFuncMethod<T, R>): IModernFunc<T, R>; overload; static;
    class function &Of<T>(const AMethod: TModernProcMethod<T>): IModernProc<T>; overload; static;
    class function &Of<T>(const AMethod: TModernPredicateMethod<T>): IModernPredicate<T>; overload; static;
  end;

implementation

type
  { Wrapper adapting a `function(const T): R of object` to IModernFunc<T,R>. }
  TFuncOfObjectWrapper<T, R> = class(TInterfacedObject, IModernFunc<T, R>)
  private
    FMethod: TModernFuncMethod<T, R>;
  public
    constructor Create(const AMethod: TModernFuncMethod<T, R>);
    function Invoke(const AValue: T): R;
  end;

  { Wrapper adapting a `procedure(const T) of object` to IModernProc<T>. }
  TProcOfObjectWrapper<T> = class(TInterfacedObject, IModernProc<T>)
  private
    FMethod: TModernProcMethod<T>;
  public
    constructor Create(const AMethod: TModernProcMethod<T>);
    procedure Invoke(const AValue: T);
  end;

  { Wrapper adapting a `function(const T): Boolean of object` to
    IModernPredicate<T>. }
  TPredicateOfObjectWrapper<T> = class(TInterfacedObject, IModernPredicate<T>)
  private
    FMethod: TModernPredicateMethod<T>;
  public
    constructor Create(const AMethod: TModernPredicateMethod<T>);
    function Invoke(const AValue: T): Boolean;
  end;

{ TFuncOfObjectWrapper<T, R> }

constructor TFuncOfObjectWrapper<T, R>.Create(const AMethod: TModernFuncMethod<T, R>);
begin
  inherited Create;
  FMethod := AMethod;
end;

function TFuncOfObjectWrapper<T, R>.Invoke(const AValue: T): R;
begin
  Result := FMethod(AValue);
end;

{ TProcOfObjectWrapper<T> }

constructor TProcOfObjectWrapper<T>.Create(const AMethod: TModernProcMethod<T>);
begin
  inherited Create;
  FMethod := AMethod;
end;

procedure TProcOfObjectWrapper<T>.Invoke(const AValue: T);
begin
  FMethod(AValue);
end;

{ TPredicateOfObjectWrapper<T> }

constructor TPredicateOfObjectWrapper<T>.Create(const AMethod: TModernPredicateMethod<T>);
begin
  inherited Create;
  FMethod := AMethod;
end;

function TPredicateOfObjectWrapper<T>.Invoke(const AValue: T): Boolean;
begin
  Result := FMethod(AValue);
end;

{ Callback }

class function Callback.&Of<T, R>(const AMethod: TModernFuncMethod<T, R>): IModernFunc<T, R>;
begin
  Result := TFuncOfObjectWrapper<T, R>.Create(AMethod);
end;

class function Callback.&Of<T>(const AMethod: TModernProcMethod<T>): IModernProc<T>;
begin
  Result := TProcOfObjectWrapper<T>.Create(AMethod);
end;

class function Callback.&Of<T>(const AMethod: TModernPredicateMethod<T>): IModernPredicate<T>;
begin
  Result := TPredicateOfObjectWrapper<T>.Create(AMethod);
end;

end.
