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
function MethodVisibility(AOwner: TClass; AToken: Pointer): TModernVisibility;
function MethodReturnType(AOwner: TClass; AToken: Pointer): TModernRTTIType;
function MethodGetParameters(AOwner: TClass; AToken: Pointer):
  TArray<TModernRTTIParameter>;

// --- Parameters --------------------------------------------------------------

function ParameterName(AOwner: TClass; const AName: string;
  ATypeToken: Pointer): string;
function ParameterParamType(AOwner: TClass; ATypeToken: Pointer):
  TModernRTTIType;

// --- Properties (issue #42) --------------------------------------------------

function PropertyVisibility(AToken: Pointer): TModernVisibility;

// --- Enumeration (issue #43) -------------------------------------------------

function EnumName(P: PTypeInfo): string;
function EnumMinValue(P: PTypeInfo): Integer;
function EnumMaxValue(P: PTypeInfo): Integer;
function EnumGetName(P: PTypeInfo; AOrdinal: Integer): string;
function EnumGetValue(P: PTypeInfo; const AName: string): Integer;
function EnumGetNames(P: PTypeInfo): TArray<string>;

// --- Pointer (issue #44) -----------------------------------------------------

function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;

// --- Record (issue #45) ------------------------------------------------------

function RecordTypeName(P: PTypeInfo): string;
function RecordTypeSize(P: PTypeInfo): Integer;

// --- Array & Set (issue #46) -------------------------------------------------

function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
function ArrayTypeSize(P: PTypeInfo): Integer;
function ArrayTypeLength(P: PTypeInfo): Integer;
function SetTypeElementType(P: PTypeInfo): PTypeInfo;

// --- Context (issue #28) -----------------------------------------------------

function ContextCreate: IModernRTTIContextToken;
function ContextGetType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
function ContextRegisterType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
function ContextGetTypes(AToken: IModernRTTIContextToken): TArray<TModernRTTIType>;
function ContextFindType(AToken: IModernRTTIContextToken; const AQualifiedName: string): TModernRTTIType;

implementation

resourcestring
  // Issue #43 — D-43.5/D-43.6 do ADR. Cada backend tem seu proprio bloco
  // `resourcestring` (padrao vigente do repo). Texto DUPLICADO com o do
  // backend FPC para paridade de mensagem — o contrato de erros e identico
  // por construcao nos dois compiladores (D-2/D-43.6).
  SEnumWrongKind =
    'TModernRTTIEnumerationType: PTypeInfo "%s" tem Kind %d; esperado tkEnumeration.';
  SEnumOrdinalOutOfRange =
    'TModernRTTIEnumerationType(%s).GetName(%d): ordinal fora de [MinValue..MaxValue].';
  SEnumNameUnknown =
    'TModernRTTIEnumerationType(%s).GetValue(''%s''): nome desconhecido.';
  // Issue #44 — D-44.2 do ADR. resourcestring local no backend (padrao
  // vigente do repo, D-1). Mesmo texto do backend FPC — o contrato de
  // erros e identico por construcao (D-2/D-44.4).
  SPointerWrongKind =
    'TModernRTTIPointerType: TypeInfo does not describe a pointer type (Kind <> tkPointer).';
  // Issue #45 — D-45.5/D-45.7 do ADR. resourcestring local no backend
  // (padrao vigente do repo, D-1). Texto DUPLICADO com o do backend FPC
  // por paridade de mensagem (D-2/D-43.6).
  SRecordWrongKind =
    'TModernRTTIRecordType: TypeInfo does not describe a record type (Kind <> tkRecord).';
  // Issue #46 — D-46.3/D-46.4/D-46.5 do ADR. resourcestring locais no
  // backend (D-1). Texto DUPLICADO com o do backend FPC por paridade de
  // mensagem (D-2/D-43.6). SArrayDynamicLength CURTO (Q4/D-46.3).
  SArrayWrongKind =
    'TModernRTTIArrayType: TypeInfo does not describe an array type (Kind not in [tkArray, tkDynArray]).';
  SArrayDynamicLength =
    'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.';
  SSetWrongKind =
    'TModernRTTISetType: TypeInfo does not describe a set type (Kind <> tkSet).';
  // Issue #51 — D-51.3 do ADR. resourcestring PRIVADA na implementation
  // (padrao vigente do repo: SFPCNoVisibility / SFPCNoReturnType / SEnum*).
  // NAO promover para a interface: o ramo `else raise` que a consome e
  // inalcancavel por dado real com o RTL atual (`TMemberVisibility` do
  // Delphi tem 4 valores em System.TypInfo.pas:232) e nenhum teste externo
  // referencia esta mensagem. Contraste com PR #58 (SModernRTTINilHandle
  // foi promovida porque um cenario em outra unit compara por igualdade).
  SDelphiUnknownVisibility =
    'TMemberVisibility desconhecido (Ord=%d) em %s — ' +
    'TModernVisibility precisa de novo ramo (issue #51).';

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

function MethodVisibility(AOwner: TClass; AToken: Pointer): TModernVisibility;
begin
  // D-51.1 do ADR issue #51: `case` explicito de 4 ramos (`mvPrivate`,
  // `mvProtected`, `mvPublic`, `mvPublished`) + `else raise
  // EModernRTTIError`. Substitui parcialmente D-42.2 do ADR issue #42:
  // intencao fail-loud preservada; mecanismo trocado.
  //
  // Medido nos 4 alvos (Delphi 23.0/37.0 x Win32/Win64, run
  // 2e4913d83ea2e1f06b3d8e8589bcbc4f): Delphi NAO faz analise de
  // exaustividade em `case` sobre enum. `case` sem `else` emite W1035 e,
  // em runtime, devolve lixo indeterminado no `Result` (ordinal 204/16/
  // 252/16 por bitness — 3 valores distintos em 4 alvos). W1035 morre
  // igualmente com `else` que faz cast e com `else` que levanta — o
  // criterio de desempate NAO e o warning, e sim fail-loud vs.
  // errado-em-silencio:
  //   - `else TModernVisibility(Ord(...))` — ordinal 4 deterministico, MUDO.
  //   - `else raise EModernRTTIError`      — mensagem nomeando ordinal +
  //     funcao, ALTA. Unica opcao que entrega a intencao de D-42.2.
  //
  // O ramo `else` e inalcancavel por dado real hoje (`TMemberVisibility`
  // do Delphi tem 4 valores em `System.TypInfo.pas:232`); por isso D-51.7
  // dispensa cenario novo de teste. `Ord(...)` recebe
  // `TRttiMethod(AToken).Visibility` — o `TMemberVisibility` do RTL, nao
  // o `TModernVisibility` da casca — para reportar o ordinal REAL que o
  // RTL passou.
  //
  // Case labels QUALIFICADOS com `TMemberVisibility.` (do RTL), Result
  // com `TModernVisibility.` (da casca), porque os dois enums declaram
  // constantes homonimas — depender de shadowing por ordem de `uses`
  // seria fragil.
  case TRttiMethod(AToken).Visibility of
    TMemberVisibility.mvPrivate:   Result := TModernVisibility.mvPrivate;
    TMemberVisibility.mvProtected: Result := TModernVisibility.mvProtected;
    TMemberVisibility.mvPublic:    Result := TModernVisibility.mvPublic;
    TMemberVisibility.mvPublished: Result := TModernVisibility.mvPublished;
  else
    raise EModernRTTIError.CreateFmt(
      SDelphiUnknownVisibility,
      [Ord(TRttiMethod(AToken).Visibility), 'MethodVisibility']);
  end;
end;

function PropertyVisibility(AToken: Pointer): TModernVisibility;
begin
  // D-51.1 do ADR issue #51: mesmo `case` de 4 ramos sobre
  // `TRttiProperty.Visibility` + `else raise EModernRTTIError` (mesmo
  // framing do sitio `MethodVisibility`: W1035 morre igualmente com
  // cast e com raise; o criterio de desempate e fail-loud vs.
  // errado-em-silencio — lixo 204/16/252/16 medido nos 4 alvos, run
  // 2e4913d83ea2e1f06b3d8e8589bcbc4f). Substitui parcialmente D-42.2 +
  // D-42.4 do ADR issue #42: intencao fail-loud preservada; mecanismo
  // trocado.
  //
  // `TRttiProperty` e auto-contido — parametro unico (AToken); simetria
  // formal com `MethodVisibility(AOwner, AToken)` seria ruido (AOwner
  // ficaria morto). D-51.5 do ADR (preserva D-42.6). Por isso a mensagem
  // usa `%s` com o nome da funcao — nao com o owner.
  //
  // `Ord(...)` recebe `TRttiProperty(AToken).Visibility` (o
  // `TMemberVisibility` do RTL), para reportar o ordinal REAL que o RTL
  // passou. Ramo `else` inalcancavel por dado real com o RTL atual
  // (D-51.7).
  case TRttiProperty(AToken).Visibility of
    TMemberVisibility.mvPrivate:   Result := TModernVisibility.mvPrivate;
    TMemberVisibility.mvProtected: Result := TModernVisibility.mvProtected;
    TMemberVisibility.mvPublic:    Result := TModernVisibility.mvPublic;
    TMemberVisibility.mvPublished: Result := TModernVisibility.mvPublished;
  else
    raise EModernRTTIError.CreateFmt(
      SDelphiUnknownVisibility,
      [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility']);
  end;
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

// --- Enumeration (issue #43) -------------------------------------------------

// Helper NAO-generico compartilhado. Constroi a mensagem com o nome real
// e o Kind real do PTypeInfo, distinguindo P = nil.
procedure EnumRaiseWrongKind(P: PTypeInfo);
begin
  if P = nil then
    raise EModernRTTIError.CreateFmt(SEnumWrongKind, ['<nil>', 0])
  else
    raise EModernRTTIError.CreateFmt(SEnumWrongKind,
      [string(P^.Name), Ord(P^.Kind)]);
end;

function EnumName(P: PTypeInfo): string;
begin
  // D-2/D-43.6: paridade estrita com FPC. Guarda por Kind aberta em cada
  // funcao antes de qualquer delegacao.
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  Result := string(P^.Name);
end;

function EnumMinValue(P: PTypeInfo): Integer;
var
  LCtx: TRttiContext;
  LType: TRttiEnumerationType;
begin
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    LType := TRttiEnumerationType(LCtx.GetType(P));
    Result := LType.MinValue;
  finally
    LCtx.Free;
  end;
end;

function EnumMaxValue(P: PTypeInfo): Integer;
var
  LCtx: TRttiContext;
  LType: TRttiEnumerationType;
begin
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    LType := TRttiEnumerationType(LCtx.GetType(P));
    Result := LType.MaxValue;
  finally
    LCtx.Free;
  end;
end;

function EnumGetName(P: PTypeInfo; AOrdinal: Integer): string;
var
  LCtx: TRttiContext;
  LType: TRttiEnumerationType;
begin
  // D-43.6: espelha o guard de M-1 do FPC antes de delegar. Sem esse guard,
  // se TRttiEnumerationType.GetNames/GetName do Delphi tratar -1 de forma
  // diferente do FPC, o contrato de erros seria assimetrico. Espelhar aqui
  // paga a mutacao `MaxValue-1` do lado Delphi tambem.
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    LType := TRttiEnumerationType(LCtx.GetType(P));
    if (AOrdinal < LType.MinValue) or (AOrdinal > LType.MaxValue) then
      raise EModernRTTIError.CreateFmt(SEnumOrdinalOutOfRange,
        [string(P^.Name), AOrdinal]);
    Result := TypInfo.GetEnumName(P, AOrdinal);
  finally
    LCtx.Free;
  end;
end;

function EnumGetValue(P: PTypeInfo; const AName: string): Integer;
begin
  // D-43.6: espelha o guard de M-2 do FPC. Captura o retorno de
  // TypInfo.GetEnumValue (mesmo no Delphi) e levanta em -1. Paridade por
  // construcao.
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  Result := TypInfo.GetEnumValue(P, AName);
  if Result = -1 then
    raise EModernRTTIError.CreateFmt(SEnumNameUnknown,
      [string(P^.Name), AName]);
end;

function EnumGetNames(P: PTypeInfo): TArray<string>;
var
  LCtx: TRttiContext;
  LType: TRttiEnumerationType;
  LMin, LMax, LI: Integer;
begin
  // D-43.7: laco MinValue..MaxValue espelhado do FPC. A mutacao obrigatoria
  // (D-43.8 / CA-12) — trocar LMax por LMax - 1 aqui — deve deixar
  // Scenario_EnumerationType_GetNames_LengthAndPresence vermelho tambem no
  // runner Delphi. Paridade por construcao.
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    LType := TRttiEnumerationType(LCtx.GetType(P));
    LMin := LType.MinValue;
    LMax := LType.MaxValue;
    SetLength(Result, LMax - LMin + 1);
    for LI := LMin to LMax do
      Result[LI - LMin] := TypInfo.GetEnumName(P, LI);
  finally
    LCtx.Free;
  end;
end;

// --- Pointer (issue #44) -----------------------------------------------------

function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;
var
  LCtx: TRttiContext;
begin
  // D-4/D-44.4: paridade estrita com FPC. Guarda por Kind aberta antes
  // de qualquer delegacao. SEM `is TRttiPointerType` (medicao nos 4
  // alvos: LCtx.GetType(TypeInfo(Pointer)) sempre devolve
  // TRttiPointerType, nunca nil, nunca levanta). SEM try/except extra:
  // TRttiPointerType(...).ReferredType para `Pointer` puro retorna nil
  // sem AV, caindo em IsNil = True (B-44.1).
  if (P = nil) or (P^.Kind <> tkPointer) then
    raise EModernRTTIError.Create(SPointerWrongKind);
  LCtx := TRttiContext.Create;
  try
    // MUTACAO OBRIGATORIA (issue #44 / D-44.3): a mutacao real vive no
    // backend FPC (property `RefType` vs raw `RefTypeRef` com cast).
    // Comentario aqui documenta simetria — nao ha equivalente Delphi
    // porque TRttiPointerType.ReferredType e API tipada, sem
    // "campo bruto" analogo.
    Result := TModernRTTIType.FromRtti(TRttiPointerType(LCtx.GetType(P)).ReferredType);
  finally
    LCtx.Free;
  end;
end;

// --- Record (issue #45) ------------------------------------------------------

// Helper unificado (D-45.5) — paridade estrita com o backend FPC. Guarda
// EXCLUSIVAMENTE por nil ou Kind — SEM condicao sobre Size (D-45.8):
// `record end` (Size = 0) e valido nos quatro alvos Delphi e nao pode ser
// rejeitado. Mesma mensagem do backend FPC (D-2/D-43.6).
procedure RecordRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or (P^.Kind <> tkRecord) then
    raise EModernRTTIError.Create(SRecordWrongKind);
end;

function RecordTypeName(P: PTypeInfo): string;
var
  LCtx: TRttiContext;
begin
  // D-4/D-45.6: paridade estrita com FPC. Guarda por Kind aberta antes
  // de qualquer delegacao. LCtx LOCAL com try/finally (padrao EnumMinValue
  // :364-377) — nao FContext global (acopla initialization order).
  // Delegacao a TRttiRecordType.Name mantida como seguranca para o caso
  // generico/aninhado; a medicao do Diretor cobriu records simples nos 4
  // alvos Delphi e a delegacao vira a rede para o que nao foi medido.
  RecordRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    Result := TRttiRecordType(LCtx.GetType(P)).Name;
  finally
    LCtx.Free;
  end;
end;

function RecordTypeSize(P: PTypeInfo): Integer;
begin
  // D-4/D-45.6: guarda por Kind aberta em cada funcao. NAO cria contexto:
  // GetTypeData(P)^.RecSize direto (paridade objetiva com o FPC; mais
  // barato que TRttiType.TypeSize, permitido pela issue como equivalente).
  RecordRaiseWrongKind(P);
  Result := GetTypeData(P)^.RecSize;
end;

// --- Array (issue #46) -------------------------------------------------------

// Helper unificado (D-46.4) — paridade estrita com o backend FPC. Guarda
// COMBINADA [tkArray, tkDynArray] porque as quatro funcoes livres do array
// aceitam os dois sub-Kinds e ramificam internamente por Kind (D-46.10).
procedure ArrayRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or not (P^.Kind in [tkArray, tkDynArray]) then
    raise EModernRTTIError.Create(SArrayWrongKind);
end;

function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
begin
  // D-4/D-46.4: guarda combinada. B-46.1: True SSE Kind = tkDynArray.
  // Identico ao backend FPC — `Kind` e objeto de linguagem, nao de RTL.
  ArrayRaiseWrongKind(P);
  Result := P^.Kind = tkDynArray;
end;

function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
var
  LCtx: TRttiContext;
begin
  // D-46.10 do ADR: TRttiDynamicArrayType e TRttiArrayType sao IRMAS em
  // System.Rtti (nao existe cast comum). Ramifica por Kind explicitamente.
  // LCtx local com try/finally (padrao RecordTypeName :505-522 / D-44.5).
  ArrayRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    if P^.Kind = tkDynArray then
      Result := TRttiDynamicArrayType(LCtx.GetType(P)).ElementType.Handle
    else
      Result := TRttiArrayType(LCtx.GetType(P)).ElementType.Handle;
  finally
    LCtx.Free;
  end;
end;

function ArrayTypeSize(P: PTypeInfo): Integer;
begin
  // D-46.6: paridade objetiva com o FPC — dinamico usa elSize, estatico usa
  // ArrayData.Size. Leitura direta via GetTypeData(P)^, sem contexto.
  ArrayRaiseWrongKind(P);
  if P^.Kind = tkDynArray then
    Result := GetTypeData(P)^.elSize
  else
    Result := GetTypeData(P)^.ArrayData.Size;
end;

function ArrayTypeLength(P: PTypeInfo): Integer;
begin
  // B-46.2 / D-46.2: paridade semantica com o backend FPC — Length em
  // dinamico LEVANTA nos DOIS compiladores. Em estatico devolve
  // ArrayData.ElCount (produto de todos os graus para multidimensional;
  // Q2 volta 1 provou que ElCount = TotalElementCount — NAO usar
  // TotalElementCount).
  ArrayRaiseWrongKind(P);
  if P^.Kind = tkDynArray then
    raise EModernRTTIError.Create(SArrayDynamicLength);
  Result := GetTypeData(P)^.ArrayData.ElCount;
end;

// --- Set (issue #46) ---------------------------------------------------------

// Helper CLASSICO — guarda por unico Kind (tkSet), paridade estrita com o
// backend FPC.
procedure SetRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or (P^.Kind <> tkSet) then
    raise EModernRTTIError.Create(SSetWrongKind);
end;

function SetTypeElementType(P: PTypeInfo): PTypeInfo;
var
  LCtx: TRttiContext;
begin
  // D-46.10: delega a TRttiSetType via LCtx local com try/finally (padrao
  // RecordTypeName). A mutacao obrigatoria 2 vive no lado FPC (property
  // CompType vs raw CompTypeRef) — a API tipada do Delphi nao expoe
  // equivalente cru.
  SetRaiseWrongKind(P);
  LCtx := TRttiContext.Create;
  try
    Result := TRttiSetType(LCtx.GetType(P)).ElementType.Handle;
  finally
    LCtx.Free;
  end;
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
