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
  @abstract(ModernRTTI - Pillar 1: unified RTTI reading for Delphi and FPC.)
  @created(28 Aug 2026)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)

  This unit deliberately does NOT include ModernSyntax.inc: the shared
  include ships a typo (the Lazarus block at ModernSyntax.inc:256 uses
  the wrong symbol name) which would silently disable the Lazarus
  branch. Branching here is written with {$IFDEF FPC} directly, so
  this unit is immune to that bug (ADR D-A2).
}

unit ModernSyntax.RTTI;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$H+}
{$ENDIF}

interface

uses
  Rtti,
  TypInfo,
  SysUtils;

type
  /// <summary>
  ///   Exception raised for every ModernRTTI error surface, including
  ///   the detection of a class without published RTTI on FPC (missing
  ///   {$M+} / 'published' section). Never returns an empty list
  ///   silently for that case (PRD R4).
  /// </summary>
  EModernRTTIError = class(Exception);

  /// <summary>
  ///   Compiler-agnostic wrapper around System.Rtti.TRttiProperty.
  ///   Consumers never touch the raw TRttiProperty; this preserves the
  ///   'same API on Delphi and FPC' contract (PRD D2, ADR RN-5).
  /// </summary>
  TModernRTTIProperty = record
  private
    // 'private' (not 'strict private') so unit-local factory functions
    // in the implementation section can seat the wrapped handle without
    // publishing a raw TRttiProperty on the interface surface (RN-5).
    FProp: TRttiProperty;
  public
    function IsValid: Boolean;
    function Name: string;
    /// <summary>Returns the property's runtime type info (from TypInfo).
    /// Wrap with ModernRTTI.GetType(...) for a TModernRTTIType.</summary>
    function PropertyType: PTypeInfo;
    function IsReadable: Boolean;
    function IsWritable: Boolean;
    function GetValue(const AInstance: TObject): TValue;
    procedure SetValue(const AInstance: TObject; const AValue: TValue);
  end;

  /// <summary>
  ///   Compiler-agnostic wrapper around System.Rtti.TRttiField.
  /// </summary>
  TModernRTTIField = record
  private
    FField: TRttiField;
  public
    function IsValid: Boolean;
    function Name: string;
    /// <summary>Returns the field's runtime type info (from TypInfo).</summary>
    function FieldType: PTypeInfo;
    function GetValue(const AInstance: TObject): TValue;
    procedure SetValue(const AInstance: TObject; const AValue: TValue);
  end;

  /// <summary>
  ///   Compiler-agnostic wrapper around System.Rtti.TRttiType. On FPC,
  ///   GetProperties/GetProperty on a class type walk the ancestor
  ///   chain for any published RTTI and raise EModernRTTIError with an
  ///   actionable message when nothing is found (never a silent []).
  /// </summary>
  TModernRTTIType = record
  private
    FType: TRttiType;
    procedure _RaiseNoPublishedRTTI;
  public
    function IsValid: Boolean;
    function Name: string;
    function IsClass: Boolean;
    function GetProperties: TArray<TModernRTTIProperty>;
    function GetProperty(const AName: string): TModernRTTIProperty;
    function GetFields: TArray<TModernRTTIField>;
    function GetField(const AName: string): TModernRTTIField;
  end;

  /// <summary>
  ///   Entry point for ModernRTTI. Static-only record following the
  ///   naming chosen by the PRD/issue (ModernRTTI.GetType(T)).
  /// </summary>
  ModernRTTI = record
  public
    class function GetType<T>: TModernRTTIType; overload; static;
    class function GetType(const AClass: TClass): TModernRTTIType; overload; static;
    class function GetType(const ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;

implementation

var
  _Context: TRttiContext;

{ Unit-local factories — NEVER exposed on the interface (RN-5) }

function _WrapProperty(const AProp: TRttiProperty): TModernRTTIProperty;
begin
  Result.FProp := AProp;
end;

function _WrapField(const AField: TRttiField): TModernRTTIField;
begin
  Result.FField := AField;
end;

function _WrapType(const AType: TRttiType): TModernRTTIType;
begin
  Result.FType := AType;
end;

{ Helpers }

{$IFDEF FPC}
// Walks the class ancestry looking for any published RTTI. On FPC, a
// class declared without {$M+} publishes no property metadata; the
// classic TRttiContext call then returns zero properties, but so does
// a class WITH {$M+} that has an empty 'published' section. Both cases
// are treated as 'no readable metadata' — the exception message names
// both fixes (see ADR D-A5).
function _AncestryHasPublishedRTTI(ATypeInfo: PTypeInfo): Boolean;
var
  LTypeData: PTypeData;
  LPropList: PPropList;
  LCount: Integer;
begin
  Result := False;
  while (ATypeInfo <> nil) and (ATypeInfo^.Kind = tkClass) do
  begin
    LPropList := nil;
    LCount := GetPropList(ATypeInfo, LPropList);
    if LPropList <> nil then
      FreeMem(LPropList);
    if LCount > 0 then
      Exit(True);
    LTypeData := GetTypeData(ATypeInfo);
    if (LTypeData <> nil) and (LTypeData^.ParentInfo <> nil) then
      ATypeInfo := LTypeData^.ParentInfo^
    else
      ATypeInfo := nil;
  end;
end;
{$ENDIF}

{ TModernRTTIProperty }

function TModernRTTIProperty.IsValid: Boolean;
begin
  Result := FProp <> nil;
end;

function TModernRTTIProperty.Name: string;
begin
  if FProp = nil then
    Exit('');
  Result := FProp.Name;
end;

function TModernRTTIProperty.PropertyType: PTypeInfo;
begin
  if (FProp = nil) or (FProp.PropertyType = nil) then
    Exit(nil);
  Result := FProp.PropertyType.Handle;
end;

function TModernRTTIProperty.IsReadable: Boolean;
begin
  Result := (FProp <> nil) and FProp.IsReadable;
end;

function TModernRTTIProperty.IsWritable: Boolean;
begin
  Result := (FProp <> nil) and FProp.IsWritable;
end;

function TModernRTTIProperty.GetValue(const AInstance: TObject): TValue;
begin
  if FProp = nil then
    raise EModernRTTIError.Create(
      'TModernRTTIProperty.GetValue: property handle is not bound.');
  Result := FProp.GetValue(Pointer(AInstance));
end;

procedure TModernRTTIProperty.SetValue(const AInstance: TObject;
  const AValue: TValue);
begin
  if FProp = nil then
    raise EModernRTTIError.Create(
      'TModernRTTIProperty.SetValue: property handle is not bound.');
  FProp.SetValue(Pointer(AInstance), AValue);
end;

{ TModernRTTIField }

function TModernRTTIField.IsValid: Boolean;
begin
  Result := FField <> nil;
end;

function TModernRTTIField.Name: string;
begin
  if FField = nil then
    Exit('');
  Result := FField.Name;
end;

function TModernRTTIField.FieldType: PTypeInfo;
begin
  if (FField = nil) or (FField.FieldType = nil) then
    Exit(nil);
  Result := FField.FieldType.Handle;
end;

function TModernRTTIField.GetValue(const AInstance: TObject): TValue;
begin
  if FField = nil then
    raise EModernRTTIError.Create(
      'TModernRTTIField.GetValue: field handle is not bound.');
  Result := FField.GetValue(Pointer(AInstance));
end;

procedure TModernRTTIField.SetValue(const AInstance: TObject;
  const AValue: TValue);
begin
  if FField = nil then
    raise EModernRTTIError.Create(
      'TModernRTTIField.SetValue: field handle is not bound.');
  FField.SetValue(Pointer(AInstance), AValue);
end;

{ TModernRTTIType }

function TModernRTTIType.IsValid: Boolean;
begin
  Result := FType <> nil;
end;

function TModernRTTIType.Name: string;
begin
  if FType = nil then
    Exit('');
  Result := FType.Name;
end;

function TModernRTTIType.IsClass: Boolean;
begin
  Result := (FType <> nil) and FType.IsInstance;
end;

procedure TModernRTTIType._RaiseNoPublishedRTTI;
var
  LClassName: string;
begin
  if (FType <> nil) then
    LClassName := FType.Name
  else
    LClassName := '<unknown>';
  raise EModernRTTIError.CreateFmt(
    'Class %s has no published RTTI. On FPC, add {$M+} and mark ' +
    'properties as ''published'' (see ModernRTTI docs).',
    [LClassName]);
end;

function TModernRTTIType.GetProperties: TArray<TModernRTTIProperty>;
var
  LProps: TArray<TRttiProperty>;
  LIdx: Integer;
begin
  if FType = nil then
    raise EModernRTTIError.Create(
      'ModernRTTI.GetProperties: type handle is nil (unknown type).');
  LProps := FType.GetProperties;
{$IFDEF FPC}
  if (Length(LProps) = 0) and FType.IsInstance then
    if not _AncestryHasPublishedRTTI(FType.Handle) then
      _RaiseNoPublishedRTTI;
{$ENDIF}
  SetLength(Result, Length(LProps));
  for LIdx := 0 to High(LProps) do
    Result[LIdx] := _WrapProperty(LProps[LIdx]);
end;

function TModernRTTIType.GetProperty(const AName: string): TModernRTTIProperty;
var
  LProp: TRttiProperty;
begin
  if FType = nil then
    raise EModernRTTIError.Create(
      'ModernRTTI.GetProperty: type handle is nil (unknown type).');
  LProp := FType.GetProperty(AName);
{$IFDEF FPC}
  if (LProp = nil) and FType.IsInstance then
    if not _AncestryHasPublishedRTTI(FType.Handle) then
      _RaiseNoPublishedRTTI;
{$ENDIF}
  Result := _WrapProperty(LProp);
end;

function TModernRTTIType.GetFields: TArray<TModernRTTIField>;
var
  LFields: TArray<TRttiField>;
  LIdx: Integer;
begin
  if FType = nil then
    raise EModernRTTIError.Create(
      'ModernRTTI.GetFields: type handle is nil (unknown type).');
  LFields := FType.GetFields;
  SetLength(Result, Length(LFields));
  for LIdx := 0 to High(LFields) do
    Result[LIdx] := _WrapField(LFields[LIdx]);
end;

function TModernRTTIType.GetField(const AName: string): TModernRTTIField;
begin
  if FType = nil then
    raise EModernRTTIError.Create(
      'ModernRTTI.GetField: type handle is nil (unknown type).');
  Result := _WrapField(FType.GetField(AName));
end;

{ ModernRTTI }

class function ModernRTTI.GetType<T>: TModernRTTIType;
begin
  Result := _WrapType(_Context.GetType(TypeInfo(T)));
end;

class function ModernRTTI.GetType(const AClass: TClass): TModernRTTIType;
begin
  if AClass = nil then
    raise EModernRTTIError.Create('ModernRTTI.GetType: AClass is nil.');
  Result := _WrapType(_Context.GetType(AClass.ClassInfo));
end;

class function ModernRTTI.GetType(
  const ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  if ATypeInfo = nil then
    raise EModernRTTIError.Create('ModernRTTI.GetType: ATypeInfo is nil.');
  Result := _WrapType(_Context.GetType(ATypeInfo));
end;

initialization
  _Context := TRttiContext.Create;

finalization
  _Context.Free;

end.
