(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI.Delphi — backend Delphi do Pilar 4 ModernRTTI (issue #25).

  Funcoes livres que a casca publica (ModernSyntax.RTTI.pas) chama via o unico
  {$IFDEF} da unit, na `uses` da implementation. Este backend envolve
  System.Rtti diretamente: os simbolos TRttiField, TRttiMethod, TRttiParameter,
  TRttiType e TValue ficam confinados a esta unit.

  Arquitetura §7 do API-MAP: mesma superficie de funcoes livres do backend
  gemeo (ModernSyntax.RTTI.FPC.pas). A compilacao e o portao que garante
  paridade de assinatura.
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.RTTI.Delphi;

interface

uses
  SysUtils,
  TypInfo,
  Rtti,
  ModernSyntax.RTTI;

// -- Field ---------------------------------------------------------------

function FieldTokens(AOwner: TClass): TArray<Pointer>;
function FieldTokenByName(AOwner: TClass; const AName: string): Pointer;
function FieldName(AOwner: TClass; AToken: Pointer): string;
function FieldRead(AInstance: TObject; AOwner: TClass; AToken: Pointer): TValue;
procedure FieldWrite(AInstance: TObject; AOwner: TClass; AToken: Pointer; const AValue: TValue);

// -- Method --------------------------------------------------------------

function MethodTokens(AOwner: TClass): TArray<Pointer>;
function MethodTokenByName(AOwner: TClass; const AName: string): Pointer;
function MethodName(AOwner: TClass; AToken: Pointer): string;
function MethodIsConstructor(AOwner: TClass; AToken: Pointer): Boolean;
function MethodIsClassMethod(AOwner: TClass; AToken: Pointer): Boolean;
function MethodIsStatic(AOwner: TClass; AToken: Pointer): Boolean;
function MethodVisibility(AOwner: TClass; AToken: Pointer): TModernRTTIVisibility;
function MethodReturnType(AOwner: TClass; AToken: Pointer): PTypeInfo;
function MethodGetParameters(AOwner: TClass; AToken: Pointer): TArray<TModernRTTIParameter>;

// -- Parameter -----------------------------------------------------------

function ParameterName(AOwner: TClass; AParamToken: Pointer): string;
function ParameterType(AOwner: TClass; AParamToken, ATypeToken: Pointer): PTypeInfo;

implementation

// -- Helpers -------------------------------------------------------------

function AsField(AToken: Pointer): TRttiField; inline;
begin
  Result := TRttiField(AToken);
end;

function AsMethod(AToken: Pointer): TRttiMethod; inline;
begin
  Result := TRttiMethod(AToken);
end;

function AsParameter(AToken: Pointer): TRttiParameter; inline;
begin
  Result := TRttiParameter(AToken);
end;

function GetRttiType(AClass: TClass): TRttiType;
begin
  Result := TModernRTTI.Context.GetType(AClass);
end;

// -- Field ---------------------------------------------------------------

function FieldTokens(AOwner: TClass): TArray<Pointer>;
var
  LFields: TArray<TRttiField>;
  LIdx: Integer;
begin
  LFields := GetRttiType(AOwner).GetFields;
  SetLength(Result, Length(LFields));
  for LIdx := 0 to High(LFields) do
    Result[LIdx] := Pointer(LFields[LIdx]);
end;

function FieldTokenByName(AOwner: TClass; const AName: string): Pointer;
var
  LField: TRttiField;
begin
  LField := GetRttiType(AOwner).GetField(AName);
  Result := Pointer(LField);
end;

function FieldName(AOwner: TClass; AToken: Pointer): string;
begin
  Result := AsField(AToken).Name;
end;

function FieldRead(AInstance: TObject; AOwner: TClass; AToken: Pointer): TValue;
begin
  Result := AsField(AToken).GetValue(AInstance);
end;

procedure FieldWrite(AInstance: TObject; AOwner: TClass; AToken: Pointer; const AValue: TValue);
begin
  AsField(AToken).SetValue(AInstance, AValue);
end;

// -- Method --------------------------------------------------------------

function MethodTokens(AOwner: TClass): TArray<Pointer>;
var
  LMethods: TArray<TRttiMethod>;
  LIdx: Integer;
begin
  LMethods := GetRttiType(AOwner).GetMethods;
  SetLength(Result, Length(LMethods));
  for LIdx := 0 to High(LMethods) do
    Result[LIdx] := Pointer(LMethods[LIdx]);
end;

function MethodTokenByName(AOwner: TClass; const AName: string): Pointer;
begin
  Result := Pointer(GetRttiType(AOwner).GetMethod(AName));
end;

function MethodName(AOwner: TClass; AToken: Pointer): string;
begin
  Result := AsMethod(AToken).Name;
end;

function MethodIsConstructor(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := AsMethod(AToken).IsConstructor;
end;

function MethodIsClassMethod(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := AsMethod(AToken).IsClassMethod;
end;

function MethodIsStatic(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := AsMethod(AToken).IsStatic;
end;

function MethodVisibility(AOwner: TClass; AToken: Pointer): TModernRTTIVisibility;
begin
  case AsMethod(AToken).Visibility of
    mvPrivate:   Result := TModernRTTIVisibility.mvPrivate;
    mvProtected: Result := TModernRTTIVisibility.mvProtected;
    mvPublic:    Result := TModernRTTIVisibility.mvPublic;
    mvPublished: Result := TModernRTTIVisibility.mvPublished;
  else
    Result := TModernRTTIVisibility.mvPublic;
  end;
end;

function MethodReturnType(AOwner: TClass; AToken: Pointer): PTypeInfo;
var
  LRet: TRttiType;
begin
  LRet := AsMethod(AToken).ReturnType;
  if LRet <> nil then
    Result := LRet.Handle
  else
    Result := nil;
end;

function MethodGetParameters(AOwner: TClass; AToken: Pointer): TArray<TModernRTTIParameter>;
var
  LParams: TArray<TRttiParameter>;
  LIdx: Integer;
begin
  LParams := AsMethod(AToken).GetParameters;
  SetLength(Result, Length(LParams));
  for LIdx := 0 to High(LParams) do
    Result[LIdx] := TModernRTTIParameter.FromToken(AOwner,
      LParams[LIdx].Name,
      Pointer(LParams[LIdx]),
      Pointer(LParams[LIdx].ParamType));
end;

// -- Parameter -----------------------------------------------------------

function ParameterName(AOwner: TClass; AParamToken: Pointer): string;
begin
  Result := AsParameter(AParamToken).Name;
end;

function ParameterType(AOwner: TClass; AParamToken, ATypeToken: Pointer): PTypeInfo;
var
  LType: TRttiType;
begin
  LType := TRttiType(ATypeToken);
  if LType <> nil then
    Result := LType.Handle
  else
    Result := nil;
end;

end.
