(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI.Delphi — backend Delphi do Pilar 4 do ModernRTTI (issue #25).

  Papel arquitetural (D-25.1): mesma superficie de ModernSyntax.RTTI.FPC.
  Aqui envolve TRttiField/TRttiMethod/TRttiParameter direto — os oito
  membros de TModernRTTIMethod tem dado real (o Delphi enumera public e
  published, enquanto o FPC so enumera published: D-25.5 do ADR).

  Nota de ownership do TRttiContext:
    O TRttiContext do Delphi mantem um pool global compartilhado. Enquanto
    houver PELO MENOS um contexto vivo (TModernRTTI.FContext, criado no
    initialization de ModernSyntax.RTTI), todos os TRtti*  permanecem
    validos. Este backend pode criar contextos locais e libera-los sem
    invalidar os handles retornados.
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.RTTI.Delphi;

interface

uses
  SysUtils,
  TypInfo,
  Rtti,
  ModernSyntax.RTTI;

type
  /// <summary>
  ///   Backend-local operations record — D-2 do ADR issue #26. Homonimo com
  ///   ModernSyntax.RTTI.FPC.TValueOps por construcao: as duas units nunca
  ///   entram na mesma compilacao (a unit publica ModernSyntax.RTTI faz uses
  ///   de exatamente uma delas via {$IFDEF FPC}). Nao introduzir uma
  ///   terceira unit que faca uses das duas (D-10 do ADR).
  /// </summary>
  TValueOps = record
    /// <summary>
    ///   Delphi: delegacao pura ao TValue.AsType&lt;T&gt; nativo — herda a
    ///   semantica de conversao (inclusive alargamento de ordinais).
    /// </summary>
    class function AsType<T>(const AValue: TValue): T; static;
  end;

// --- Fields ------------------------------------------------------------------

function FieldEnumerate(AClass: TClass): TArray<TModernRTTIField>;
function FieldReadValue(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject): TValue;
procedure FieldWriteValue(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; const AValue: TValue);
function FieldReadRaw(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; ADest: Pointer; ASize: NativeInt): Boolean;
procedure FieldWriteRaw(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; ASrc: Pointer; ASize: NativeInt);

// --- Methods -----------------------------------------------------------------

function MethodEnumerate(AClass: TClass): TArray<TModernRTTIMethod>;
function MethodLookup(AClass: TClass; const AName: string;
  out AEntry: TModernRTTIMethod): Boolean;
function MethodIsConstructor(AOwner: TClass; AToken: Pointer): Boolean;
function MethodIsClassMethod(AOwner: TClass; AToken: Pointer): Boolean;
function MethodIsStatic(AOwner: TClass; AToken: Pointer): Boolean;
function MethodVisibility(AOwner: TClass; AToken: Pointer): TMemberVisibility;
function MethodReturnType(AOwner: TClass; AToken: Pointer): TModernRTTIType;
function MethodGetParameters(AOwner: TClass; AToken: Pointer):
  TArray<TModernRTTIParameter>;

// --- Parameters --------------------------------------------------------------

function ParameterName(AOwner: TClass; const AName: string;
  ATypeToken: Pointer): string;
function ParameterParamType(AOwner: TClass; ATypeToken: Pointer):
  TModernRTTIType;

// --- Context (issue #28) -----------------------------------------------------

function ContextCreate: IModernRTTIContextToken;
function ContextGetType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
function ContextRegisterType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
function ContextGetTypes(AToken: IModernRTTIContextToken): TArray<TModernRTTIType>;
function ContextFindType(AToken: IModernRTTIContextToken; const AQualifiedName: string): TModernRTTIType;

implementation

// --- TValueOps ---------------------------------------------------------------

class function TValueOps.AsType<T>(const AValue: TValue): T;
begin
  // D-3 do ADR issue #26: delegacao pura. Consumidor Delphi de
  // LProp.GetValue<Int64> sobre propriedade Integer continua funcionando
  // como sempre — sem regressao possivel; a divergencia de alargamento com
  // o FPC esta declarada em voz alta no XMLDoc de TModernValue.AsType<T>.
  Result := AValue.AsType<T>;
end;

// --- Fields ------------------------------------------------------------------

function FieldEnumerate(AClass: TClass): TArray<TModernRTTIField>;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LFields: TArray<TRttiField>;
  LIdx: Integer;
begin
  Result := nil;
  if AClass = nil then
    Exit;
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(AClass);
    if LType = nil then
      Exit;
    LFields := LType.GetFields;
    SetLength(Result, Length(LFields));
    for LIdx := 0 to High(LFields) do
      Result[LIdx] := TModernRTTIField.FromToken(
        AClass, LFields[LIdx].Name, Pointer(LFields[LIdx]));
  finally
    LCtx.Free;
  end;
end;

function FieldReadValue(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject): TValue;
begin
  Result := TRttiField(AToken).GetValue(AInstance);
end;

procedure FieldWriteValue(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; const AValue: TValue);
begin
  TRttiField(AToken).SetValue(AInstance, AValue);
end;

function FieldReadRaw(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; ADest: Pointer; ASize: NativeInt): Boolean;
var
  LValue: TValue;
begin
  LValue := TRttiField(AToken).GetValue(AInstance);
  Result := LValue.DataSize = ASize;
  if Result then
    LValue.ExtractRawData(ADest);
end;

procedure FieldWriteRaw(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; ASrc: Pointer; ASize: NativeInt);
var
  LField: TRttiField;
  LValue: TValue;
begin
  LField := TRttiField(AToken);
  TValue.Make(ASrc, LField.FieldType.Handle, LValue);
  LField.SetValue(AInstance, LValue);
end;

// --- Methods -----------------------------------------------------------------

function MethodEnumerate(AClass: TClass): TArray<TModernRTTIMethod>;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethods: TArray<TRttiMethod>;
  LIdx: Integer;
begin
  Result := nil;
  if AClass = nil then
    Exit;
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(AClass);
    if LType = nil then
      Exit;
    LMethods := LType.GetMethods;
    SetLength(Result, Length(LMethods));
    for LIdx := 0 to High(LMethods) do
      Result[LIdx] := TModernRTTIMethod.FromToken(
        AClass, LMethods[LIdx].Name, Pointer(LMethods[LIdx]));
  finally
    LCtx.Free;
  end;
end;

function MethodLookup(AClass: TClass; const AName: string;
  out AEntry: TModernRTTIMethod): Boolean;
var
  LCtx: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  Result := False;
  if AClass = nil then
    Exit;
  LCtx := TRttiContext.Create;
  try
    LType := LCtx.GetType(AClass);
    if LType = nil then
      Exit;
    LMethod := LType.GetMethod(AName);
    if LMethod = nil then
      Exit;
    AEntry := TModernRTTIMethod.FromToken(
      AClass, LMethod.Name, Pointer(LMethod));
    Result := True;
  finally
    LCtx.Free;
  end;
end;

function MethodIsConstructor(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := TRttiMethod(AToken).IsConstructor;
end;

function MethodIsClassMethod(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := TRttiMethod(AToken).IsClassMethod;
end;

function MethodIsStatic(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := TRttiMethod(AToken).IsStatic;
end;

function MethodVisibility(AOwner: TClass; AToken: Pointer): TMemberVisibility;
begin
  Result := TRttiMethod(AToken).Visibility;
end;

function MethodReturnType(AOwner: TClass; AToken: Pointer): TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(TRttiMethod(AToken).ReturnType);
end;

function MethodGetParameters(AOwner: TClass; AToken: Pointer):
  TArray<TModernRTTIParameter>;
var
  LParams: TArray<TRttiParameter>;
  LIdx: Integer;
begin
  LParams := TRttiMethod(AToken).GetParameters;
  SetLength(Result, Length(LParams));
  for LIdx := 0 to High(LParams) do
    Result[LIdx] := TModernRTTIParameter.FromToken(
      AOwner, LParams[LIdx].Name, Pointer(LParams[LIdx].ParamType));
end;

// --- Parameters --------------------------------------------------------------

function ParameterName(AOwner: TClass; const AName: string;
  ATypeToken: Pointer): string;
begin
  // D-25.6: no Delphi, FromToken ja populou FName com dado real de
  // TRttiParameter.Name. Devolvemos o valor cru — evita reter TRttiParameter
  // como token e depender de tempo de vida do contexto local.
  Result := AName;
end;

function ParameterParamType(AOwner: TClass; ATypeToken: Pointer):
  TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(TRttiType(ATypeToken));
end;

// --- Context (issue #28) -----------------------------------------------------

type
  /// <summary>
  ///   Estado interno do `TModernRTTIContext` no Delphi: um `TRttiContext`
  ///   nativo per-instancia. Alocacao per-instancia (nao reusa o
  ///   `FContext` global de `TModernRTTI`) para simetria com o backend
  ///   FPC. O ciclo de vida e o do refcount da `IInterface`.
  /// </summary>
  TDelphiContextToken = class(TInterfacedObject, IModernRTTIContextToken)
  private
    FContext: TRttiContext;
  public
    constructor Create;
    destructor Destroy; override;
  end;

constructor TDelphiContextToken.Create;
begin
  inherited Create;
  FContext := TRttiContext.Create;
end;

destructor TDelphiContextToken.Destroy;
begin
  FContext.Free;
  inherited Destroy;
end;

function ContextCreate: IModernRTTIContextToken;
begin
  Result := TDelphiContextToken.Create;
end;

function ContextGetType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(
    (AToken as TDelphiContextToken).FContext.GetType(ATypeInfo));
end;

function ContextRegisterType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  // D-28.7: no Delphi RegisterType e no-op logico — o pool nativo do
  // TRttiContext ja carrega os tipos. Devolvemos o handle nativo por
  // consistencia com o FPC (que devolve o mesmo formato de retorno).
  Result := TModernRTTIType.FromRtti(
    (AToken as TDelphiContextToken).FContext.GetType(ATypeInfo));
end;

function ContextGetTypes(AToken: IModernRTTIContextToken): TArray<TModernRTTIType>;
var
  LTypes: TArray<TRttiType>;
  LIdx: Integer;
begin
  // Delega ao pool nativo — TRttiContext.GetTypes retorna todos os tipos
  // conhecidos pelo Delphi. Registry-vazio-levanta e comportamento
  // exclusivo do FPC (D-28.4) — no Delphi o pool nativo torna o cenario
  // "empty" impossivel de simular (padrao "dois cenarios distintos"
  // da #25 — o cenario Scenario_Context_GetTypes_EmptyRegistry_Raises
  // e publicado APENAS na casca FPC).
  LTypes := (AToken as TDelphiContextToken).FContext.GetTypes;
  SetLength(Result, Length(LTypes));
  for LIdx := 0 to High(LTypes) do
    Result[LIdx] := TModernRTTIType.FromRtti(LTypes[LIdx]);
end;

function ContextFindType(AToken: IModernRTTIContextToken; const AQualifiedName: string): TModernRTTIType;
begin
  // Delega ao FindType nativo — o Delphi cobre todos os kinds pelo
  // qualified name. Divergencia com FPC (que so resolve tkClass) esta
  // declarada em XMLDoc de TModernRTTIContext.FindType (D-28.5).
  Result := TModernRTTIType.FromRtti(
    (AToken as TDelphiContextToken).FContext.FindType(AQualifiedName));
end;

end.
