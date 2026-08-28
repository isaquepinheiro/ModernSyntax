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

unit ModernSyntax.RTTI;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Rtti,
  TypInfo,
  SysUtils;

type
  /// <summary>
  ///   Exception raised by the ModernSyntax.RTTI unit when a RTTI operation
  ///   cannot be completed portably. The primary trigger is the absence of
  ///   <c>{$M+}</c> ahead of a class declaration on FPC 3.2.2 (see the
  ///   message text raised by <see cref="TModernRTTIType.GetProperties"/>).
  /// </summary>
  EModernRTTIError = class(Exception);

  /// <summary>
  ///   Lightweight handle around a <see cref="TRttiField"/> owned by the
  ///   unit-level <see cref="TModernRTTI.FContext"/>.
  /// </summary>
  /// <remarks>
  ///   Ownership: this record is a handle. Do not free the underlying
  ///   <see cref="TRttiField"/>. The referenced data lives as long as
  ///   <see cref="TModernRTTI"/> is loaded. Retaining a value after the
  ///   binary has shut down is undefined.
  /// </remarks>
  TModernRTTIField = record
  strict private
    FField: TRttiField;
  public
    /// <summary>Wraps a raw <see cref="TRttiField"/> — used internally by
    /// <see cref="TModernRTTIType.GetFields"/>.</summary>
    class function Wrap(AField: TRttiField): TModernRTTIField; static;
    /// <summary>Returns the field name.</summary>
    function Name: string;
    /// <summary>Reads the field value from <paramref name="AInstance"/>
    /// and casts it to <typeparamref name="T"/>.</summary>
    function GetValue<T>(const AInstance: TObject): T; overload;
    /// <summary>Writes <paramref name="AValue"/> of type <typeparamref name="T"/>
    /// into the field of <paramref name="AInstance"/>.</summary>
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <summary>Reads the field value as a raw <see cref="TValue"/>.</summary>
    /// <remarks>
    ///   Escape hatch: forces the caller to <c>uses Rtti</c>, a unit marked
    ///   <c>experimental</c> on FPC 3.2.2. Prefer the generic overload.
    /// </remarks>
    function GetValue(const AInstance: TObject): TValue; overload;
    /// <summary>Writes a raw <see cref="TValue"/> to the field.</summary>
    /// <remarks>
    ///   Escape hatch: forces the caller to <c>uses Rtti</c>, a unit marked
    ///   <c>experimental</c> on FPC 3.2.2. Prefer the generic overload.
    /// </remarks>
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
  end;

  /// <summary>
  ///   Lightweight handle around a <see cref="TRttiProperty"/> owned by the
  ///   unit-level <see cref="TModernRTTI.FContext"/>.
  /// </summary>
  /// <remarks>
  ///   Ownership: this record is a handle. Do not free the underlying
  ///   <see cref="TRttiProperty"/>. The referenced data lives as long as
  ///   <see cref="TModernRTTI"/> is loaded. Retaining a value after the
  ///   binary has shut down is undefined.
  /// </remarks>
  TModernRTTIProperty = record
  strict private
    FProp: TRttiProperty;
  public
    /// <summary>Wraps a raw <see cref="TRttiProperty"/> — used internally
    /// by <see cref="TModernRTTIType.GetProperties"/>.</summary>
    class function Wrap(AProp: TRttiProperty): TModernRTTIProperty; static;
    /// <summary>Returns the property name.</summary>
    function Name: string;
    /// <summary>Returns True when the property has a readable getter.</summary>
    function IsReadable: Boolean;
    /// <summary>Returns True when the property has a writable setter.</summary>
    function IsWritable: Boolean;
    /// <summary>Reads the property value from <paramref name="AInstance"/>
    /// and casts it to <typeparamref name="T"/>.</summary>
    function GetValue<T>(const AInstance: TObject): T; overload;
    /// <summary>Writes <paramref name="AValue"/> of type <typeparamref name="T"/>
    /// into the property of <paramref name="AInstance"/>.</summary>
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <summary>Reads the property value as a raw <see cref="TValue"/>.</summary>
    /// <remarks>
    ///   Escape hatch: forces the caller to <c>uses Rtti</c>, a unit marked
    ///   <c>experimental</c> on FPC 3.2.2. Prefer the generic overload.
    /// </remarks>
    function GetValue(const AInstance: TObject): TValue; overload;
    /// <summary>Writes a raw <see cref="TValue"/> to the property.</summary>
    /// <remarks>
    ///   Escape hatch: forces the caller to <c>uses Rtti</c>, a unit marked
    ///   <c>experimental</c> on FPC 3.2.2. Prefer the generic overload.
    /// </remarks>
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
  end;

  /// <summary>
  ///   Lightweight handle around a <see cref="TRttiType"/> owned by the
  ///   unit-level <see cref="TModernRTTI.FContext"/>. Entry point for
  ///   iterating properties and fields with the same call on Delphi and
  ///   FPC 3.2.2.
  /// </summary>
  /// <remarks>
  ///   Ownership: this record is a handle. Do not free the underlying
  ///   <see cref="TRttiType"/>. The array returned by
  ///   <see cref="GetProperties"/> and <see cref="GetFields"/> is safe to
  ///   iterate and store during the lifetime of the process.
  /// </remarks>
  TModernRTTIType = record
  strict private
    FType: TRttiType;
  public
    /// <summary>Wraps a raw <see cref="TRttiType"/> — used internally by
    /// <see cref="TModernRTTI.GetType"/>.</summary>
    class function Wrap(AType: TRttiType): TModernRTTIType; static;
    /// <summary>Returns the type name.</summary>
    function Name: string;
    /// <summary>Returns all properties visible to RTTI for this type.</summary>
    /// <remarks>
    ///   On FPC, if the class was declared without a preceding <c>{$M+}</c>
    ///   directive the RTTI table has zero properties. This method raises
    ///   <see cref="EModernRTTIError"/> in that case with an instructive
    ///   message — never returns a silent empty list. On Delphi, an empty
    ///   list means the class genuinely has no <c>public</c>/<c>published</c>
    ///   properties and the same exception is raised for consistency.
    ///   Ownership: the returned array holds handles; do not free them.
    /// </remarks>
    function GetProperties: TArray<TModernRTTIProperty>;
    /// <summary>Returns all fields visible to RTTI for this type.</summary>
    /// <remarks>
    ///   Ownership: the returned array holds handles; do not free them.
    /// </remarks>
    function GetFields: TArray<TModernRTTIField>;
  end;

  /// <summary>
  ///   Entry point of the ModernSyntax RTTI reader (Pillar 1 of ModernRTTI).
  ///   Owns a process-wide <see cref="TRttiContext"/> created at
  ///   <c>initialization</c> and released at <c>finalization</c>.
  /// </summary>
  TModernRTTI = record
  strict private
    class var FContext: TRttiContext;
  public
    /// <summary>Returns a <see cref="TModernRTTIType"/> for
    /// <paramref name="AClass"/>.</summary>
    /// <remarks>
    ///   Ownership: the returned handle points into
    ///   <see cref="FContext"/>. Do not free anything.
    /// </remarks>
    class function GetType(AClass: TClass): TModernRTTIType; overload; static;
    /// <summary>Returns a <see cref="TModernRTTIType"/> for
    /// <paramref name="ATypeInfo"/>.</summary>
    /// <remarks>
    ///   Ownership: the returned handle points into
    ///   <see cref="FContext"/>. Do not free anything.
    /// </remarks>
    class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;

implementation

resourcestring
  SNoPublishedRTTI =
    'Class %s does not expose properties to RTTI. On Delphi this means the ' +
    'class has no public/published properties. On FPC it also requires a ' +
    '{$M+} directive before the class declaration and a published section ' +
    'listing the desired properties. Add both and recompile.';

{ Internal helpers }

/// <summary>
///   Heuristic used to detect whether a class was declared without
///   <c>{$M+}</c> — the case where FPC returns zero properties even when
///   the class actually defines some. Applied uniformly to both compilers:
///   on Delphi the same heuristic simply reports a class with no
///   <c>public</c>/<c>published</c> properties.
/// </summary>
function MissingPublishedRTTI(AType: TRttiType): Boolean;
var
  LTypeInfo: PTypeInfo;
  LTypeData: PTypeData;
begin
  Result := False;
  if not (AType is TRttiInstanceType) then
    Exit;
  LTypeInfo := AType.Handle;
  if LTypeInfo = nil then
    Exit;
  // TObject itself has no published properties, but that is not a defect.
  if TRttiInstanceType(AType).MetaclassType = TObject then
    Exit;
  LTypeData := GetTypeData(LTypeInfo);
  if LTypeData = nil then
    Exit;
  Result := LTypeData^.PropCount = 0;
end;

{ TModernRTTIField }

class function TModernRTTIField.Wrap(AField: TRttiField): TModernRTTIField;
begin
  Result.FField := AField;
end;

function TModernRTTIField.Name: string;
begin
  Result := FField.Name;
end;

function TModernRTTIField.GetValue<T>(const AInstance: TObject): T;
begin
  Result := FField.GetValue(AInstance).AsType<T>;
end;

procedure TModernRTTIField.SetValue<T>(const AInstance: TObject; const AValue: T);
begin
  FField.SetValue(AInstance, TValue.From<T>(AValue));
end;

function TModernRTTIField.GetValue(const AInstance: TObject): TValue;
begin
  Result := FField.GetValue(AInstance);
end;

procedure TModernRTTIField.SetValue(const AInstance: TObject; const AValue: TValue);
begin
  FField.SetValue(AInstance, AValue);
end;

{ TModernRTTIProperty }

class function TModernRTTIProperty.Wrap(AProp: TRttiProperty): TModernRTTIProperty;
begin
  Result.FProp := AProp;
end;

function TModernRTTIProperty.Name: string;
begin
  Result := FProp.Name;
end;

function TModernRTTIProperty.IsReadable: Boolean;
begin
  Result := FProp.IsReadable;
end;

function TModernRTTIProperty.IsWritable: Boolean;
begin
  Result := FProp.IsWritable;
end;

function TModernRTTIProperty.GetValue<T>(const AInstance: TObject): T;
begin
  Result := FProp.GetValue(AInstance).AsType<T>;
end;

procedure TModernRTTIProperty.SetValue<T>(const AInstance: TObject; const AValue: T);
begin
  FProp.SetValue(AInstance, TValue.From<T>(AValue));
end;

function TModernRTTIProperty.GetValue(const AInstance: TObject): TValue;
begin
  Result := FProp.GetValue(AInstance);
end;

procedure TModernRTTIProperty.SetValue(const AInstance: TObject; const AValue: TValue);
begin
  FProp.SetValue(AInstance, AValue);
end;

{ TModernRTTIType }

class function TModernRTTIType.Wrap(AType: TRttiType): TModernRTTIType;
begin
  Result.FType := AType;
end;

function TModernRTTIType.Name: string;
begin
  Result := FType.Name;
end;

function TModernRTTIType.GetProperties: TArray<TModernRTTIProperty>;
var
  LProps: TArray<TRttiProperty>;
  LIndex: Integer;
begin
  LProps := FType.GetProperties;
  if (Length(LProps) = 0) and MissingPublishedRTTI(FType) then
    raise EModernRTTIError.CreateFmt(SNoPublishedRTTI, [FType.Name]);
  SetLength(Result, Length(LProps));
  for LIndex := 0 to High(LProps) do
    Result[LIndex] := TModernRTTIProperty.Wrap(LProps[LIndex]);
end;

function TModernRTTIType.GetFields: TArray<TModernRTTIField>;
var
  LFields: TArray<TRttiField>;
  LIndex: Integer;
begin
  LFields := FType.GetFields;
  SetLength(Result, Length(LFields));
  for LIndex := 0 to High(LFields) do
    Result[LIndex] := TModernRTTIField.Wrap(LFields[LIndex]);
end;

{ TModernRTTI }

class function TModernRTTI.GetType(AClass: TClass): TModernRTTIType;
begin
  Result := TModernRTTIType.Wrap(FContext.GetType(AClass));
end;

class function TModernRTTI.GetType(ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  Result := TModernRTTIType.Wrap(FContext.GetType(ATypeInfo));
end;

initialization
  TModernRTTI.FContext := TRttiContext.Create;

finalization
  TModernRTTI.FContext.Free;

end.
