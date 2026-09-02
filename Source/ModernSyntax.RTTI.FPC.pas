(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI.FPC — backend FPC do Pilar 4 do ModernRTTI (issue #25).

  Papel arquitetural (D-25.1): esta unit expoe a mesma superficie de funcoes
  livres que ModernSyntax.RTTI.Delphi. A casca publica ModernSyntax.RTTI
  seleciona uma das duas via unico {$IFDEF} da uses da implementation. Aqui
  nao ha ramificacao por compilador — este arquivo so entra na compilacao
  quando FPC = True.

  Mecanismos:
    - Enumeracao de metodos: itera pela vmtMethodTable, subindo por
      ClassParent (D-25.2 + D-25.3). Iteracao pela property indexada
      LTab^.Entry[i] — nunca aritmetica literal (SizeOf(TVmtMethodEntry)
      difere entre x86_64 e i386, ver ADR issue #25).
    - Enumeracao de campos: mesma tecnica da vmtFieldTable (ciclo 008).
    - Lookup por nome: MethodAddress (D-25.3), que sobe a cadeia sozinho.
    - Invocacao: nao acontece aqui — a casca publica chama TModernInvoker
      diretamente com FOwner+FName (D-25.9).
    - Membros sem fonte no FPC (IsConstructor, IsClassMethod, IsStatic,
      Visibility, ReturnType, GetParameters, ParameterName, ParameterType):
      raise EModernRTTIError com mensagem instrutiva (D-25.4). Precedente:
      TModernRTTIType.GetProperties para classes sem {$M+} (ciclo 002).
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.RTTI.FPC;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses
  SysUtils,
  TypInfo,
  Rtti,
  ModernSyntax.RTTI;

type
  /// <summary>
  ///   Backend-local operations record — D-2 do ADR issue #26. Homonimo com
  ///   ModernSyntax.RTTI.Delphi.TValueOps por construcao: a exclusividade e
  ///   garantida pelo unico {$IFDEF FPC} da uses de ModernSyntax.RTTI. Nao
  ///   introduzir uma terceira unit que faca uses das duas (D-10).
  /// </summary>
  TValueOps = record
    /// <summary>
    ///   Interno — nao faz parte da API publica de ModernSyntax.RTTI. Sobe
    ///   ao interface para desarmar o defeito medido do FPC 3.2.2
    ///   "Global Generic template references static symtable": uma funcao
    ///   generica declarada em record no interface nao pode referenciar
    ///   simbolos que morem no static symtable da implementation (SKILL.md
    ///   trap #2). Como a assinatura desta procedure vive no interface, a
    ///   funcao generica pode chama-la sem violar a regra, e o corpo (na
    ///   implementation) resolve resourcestring/EModernRTTIError livremente.
    /// </summary>
    class procedure RaiseIncompatible(AOrigin, ADestination: PTypeInfo); static;
    /// <summary>
    ///   FPC: exige tipo EXATO. Verifica via V.IsType(TypeInfo(T)) (D-4 do
    ///   ADR — a forma generica IsType&lt;T&gt; nao compila dentro de funcao
    ///   generica no FPC 3.2.2) e extrai por ExtractRawData; conversao entre
    ///   tipos diferentes levanta EModernRTTIError nomeando origem e destino.
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

uses
  Classes;

resourcestring
  SFPCNoConstructor =
    'IsConstructor: nao disponivel no FPC. vmtMethodTable (typinfo.pp:388-396) ' +
    'carrega apenas Name e CodeAddress; a distincao entre construtor, ' +
    'metodo de classe e metodo de instancia mora em TIntfMethodEntry ' +
    '(uso interfaces) e nao existe para RTTI de classe.';
  SFPCNoClassMethod =
    'IsClassMethod: nao disponivel no FPC. vmtMethodTable (typinfo.pp:388-396) ' +
    'carrega apenas Name e CodeAddress; distincao class/instance mora em ' +
    'TIntfMethodEntry, nao aqui.';
  SFPCNoStatic =
    'IsStatic: nao disponivel no FPC. vmtMethodTable (typinfo.pp:388-396) ' +
    'nao registra o modificador static — o dado nao existe.';
  // D-42.5 do ADR issue #42: reescrita para expor a RAIZ verdadeira. O
  // texto anterior ("visibilidade fina nao e enumeravel pela RTTI de
  // classe") era falso — `TRttiMember.Visibility` existe em
  // `rtti.pp:317` do FPC 3.2.2. O que nao a expoe e o CAMINHO
  // escolhido: esta camada enumera metodos por `vmtMethodTable`
  // (decisao da issue #25) e `TVmtMethodEntry` so carrega `Name` e
  // `CodeAddress`. Trocar para `TRttiMethod` reintroduziria
  // dependencia de `TRttiContext.GetType` e perderia a enumeracao por
  // heranca que a #25 provou.
  SFPCNoVisibility =
    'Visibility: nao disponivel para metodos no FPC. TRttiMember.Visibility ' +
    'existe em rtti.pp:317 do FPC 3.2.2, mas esta camada enumera metodos por ' +
    'vmtMethodTable (decisao da issue #25) e TVmtMethodEntry so carrega Name ' +
    'e CodeAddress. TRttiMethod fica fora do caminho escolhido — trocar para ' +
    'ele reintroduziria dependencia de TRttiContext.GetType e perderia a ' +
    'enumeracao por heranca. Para visibilidade de PROPRIEDADES use ' +
    'TModernRTTIProperty.Visibility, que le TRttiProperty.Visibility direto.';
  SFPCNoReturnType =
    'ReturnType: nao disponivel no FPC. vmtMethodTable (typinfo.pp:388-396) ' +
    'carrega apenas Name e CodeAddress; tipo de retorno mora em ' +
    'TIntfMethodEntry (interfaces), nao aqui.';
  SFPCNoParameters =
    'GetParameters: nao disponivel no FPC. vmtMethodTable (typinfo.pp:388-396) ' +
    'nao lista parametros — o dado esta em TIntfMethodEntry (interfaces), ' +
    'nao no RTTI de metodo de classe.';
  SFPCNoParamName =
    'TModernRTTIParameter.Name: nao disponivel no FPC. Sem TIntfMethodEntry ' +
    'nao ha lista de parametros, e sem lista de parametros nenhum ' +
    'TModernRTTIParameter e construido no FPC.';
  SFPCNoParamType =
    'TModernRTTIParameter.ParamType: nao disponivel no FPC pelo mesmo ' +
    'motivo de Name — a lista de parametros vive em TIntfMethodEntry, ' +
    'que nao alimenta metodos de classe.';
  // Issue #26 — D-4 do ADR. UMA unica resourcestring nomeando origem e
  // destino. Origem sai de V.TypeInfo^.Name; destino sai de
  // PTypeInfo(TypeInfo(T))^.Name. Sem alargamento (D-5): tipos diferentes
  // levantam com esta mensagem.
  SModernValueIncompatibleType =
    'incompativel: origem=%s destino=%s';
  // Issue #28 — D-28.4. `GetTypes` sobre registry vazio LEVANTA em vez de
  // devolver array vazio. Mensagem instrutiva: diz o que fazer.
  SModernRTTIError_EmptyRegistry =
    'o FPC 3.2.2 nao enumera tipos; registre com TModernRTTIContext.RegisterType ' +
    'os tipos que importam antes de chamar GetTypes.';
  // Issue #43 — D-43.3/D-43.4/D-43.5 do ADR. As tres resourcestring vivem no
  // backend (nao na unit publica RTTI.pas) para preservar D-1: a fabrica
  // FromTypeInfo NAO valida Kind exatamente para nao obrigar resourcestring
  // na casca. Cada guarda por metodo (D-4) usa uma destas.
  SEnumWrongKind =
    'TModernRTTIEnumerationType: PTypeInfo "%s" tem Kind %d; esperado tkEnumeration.';
  SEnumOrdinalOutOfRange =
    'TModernRTTIEnumerationType(%s).GetName(%d): ordinal fora de [MinValue..MaxValue].';
  SEnumNameUnknown =
    'TModernRTTIEnumerationType(%s).GetValue(''%s''): nome desconhecido.';
  // Issue #44 — D-44.2/D-44.3 do ADR. resourcestring vive no backend
  // (D-1) para nao vazar para a unit publica. Guarda em
  // PointerTypeReferredType (D-4). Mesma mensagem no backend Delphi.
  SPointerWrongKind =
    'TModernRTTIPointerType: TypeInfo does not describe a pointer type (Kind <> tkPointer).';
  // Issue #45 — D-45.5/D-45.7 do ADR. resourcestring UNICO no backend
  // (D-1) para nao vazar para a unit publica. Texto IDENTICO ao do
  // backend Delphi (D-2/D-43.6). Guarda em RecordRaiseWrongKind.
  SRecordWrongKind =
    'TModernRTTIRecordType: TypeInfo does not describe a record type (Kind <> tkRecord).';
  // Issue #46 — D-46.3/D-46.4/D-46.5 do ADR. Tres resourcestrings no backend
  // (D-1) com texto IDENTICO ao backend Delphi (D-2/D-43.6). SArrayWrongKind
  // cobre a guarda combinada [tkArray, tkDynArray] (D-46.4); SSetWrongKind
  // cobre a guarda por tkSet. SArrayDynamicLength e texto CURTO (Q4/D-46.3)
  // — RTTI reporta o que sabe do tipo, nao ensina API de instancia.
  SArrayWrongKind =
    'TModernRTTIArrayType: TypeInfo does not describe an array type (Kind not in [tkArray, tkDynArray]).';
  SArrayDynamicLength =
    'TModernRTTIArrayType.Length: nao suportado para arrays dinamicos.';
  SSetWrongKind =
    'TModernRTTISetType: TypeInfo does not describe a set type (Kind <> tkSet).';

// --- TValueOps ---------------------------------------------------------------

class procedure TValueOps.RaiseIncompatible(AOrigin, ADestination: PTypeInfo);
begin
  // Metodo NAO-generico do proprio record, declarado no interface (ver
  // XMLDoc). Corpo pode tocar resourcestring/EModernRTTIError da
  // implementation livremente — o defeito "Global Generic template
  // references static symtable" so atinge codigo generico.
  raise EModernRTTIError.CreateFmt(SModernValueIncompatibleType,
    [string(AOrigin^.Name), string(ADestination^.Name)]);
end;

class function TValueOps.AsType<T>(const AValue: TValue): T;
begin
  // D-4 do ADR issue #26. IsType(TypeInfo(T)) — nao IsType<T> — pela nota
  // do proprio ADR: a forma generica nao compila dentro de funcao generica
  // no FPC 3.2.2 e depende do {$ifndef NoGenericMethods} da RTL. A forma
  // nao-generica e imune aos dois problemas.
  // ExtractRawData cobre 10/10 dos casos exatos (medido nos dois bitness,
  // record e enum inclusos) — dispensa dispatch por Kind.
  if not AValue.IsType(TypeInfo(T)) then
    TValueOps.RaiseIncompatible(AValue.TypeInfo, TypeInfo(T));
  AValue.ExtractRawData(@Result);
end;

// --- Fields ------------------------------------------------------------------

function FieldEnumerate(AClass: TClass): TArray<TModernRTTIField>;
var
  LCur: TClass;
  LTab: PVmtFieldTable;
  LEntry: PVmtFieldEntry;
  LCount, LIdx, LI: Integer;
begin
  // Enumeracao portavel no FPC via vmtFieldTable tipada (D4 do ADR issue #21).
  // vmtFieldTable NAO e recursiva (jitclass.pas:1187-1188); subimos a
  // cadeia por ClassParent.
  Result := nil;
  if AClass = nil then
    Exit;

  LCount := 0;
  LCur := AClass;
  while LCur <> nil do
  begin
    LTab := PVmtFieldTable(PVmt(Pointer(LCur))^.vFieldTable);
    if LTab <> nil then
      Inc(LCount, LTab^.Count);
    LCur := LCur.ClassParent;
  end;

  SetLength(Result, LCount);
  LIdx := 0;
  LCur := AClass;
  while LCur <> nil do
  begin
    LTab := PVmtFieldTable(PVmt(Pointer(LCur))^.vFieldTable);
    if LTab <> nil then
      for LI := 0 to LTab^.Count - 1 do
      begin
        // property Field[i] (D5 do ADR issue #21): TVmtFieldEntry tem
        // tamanho variavel (Name: ShortString) — indexar como array le lixo.
        LEntry := LTab^.Field[LI];
        // Token: guardamos o offset absoluto empacotado como Pointer.
        // Casts PtrUInt<->Pointer sao legais na RTL (ambos word-sized).
        Result[LIdx] := TModernRTTIField.FromToken(
          LCur, string(LEntry^.Name), Pointer(PtrUInt(LEntry^.FieldOffset)));
        Inc(LIdx);
      end;
    LCur := LCur.ClassParent;
  end;
end;

function FieldReadValue(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject): TValue;
begin
  // Overload TValue no FPC — limite published e tipo classe (D9 do ADR
  // issue #21). Envolve o ponteiro lido em TValue.From<TObject>.
  Result := TValue.From<TObject>(
    PPointer(PByte(AInstance) + PtrUInt(AToken))^);
end;

procedure FieldWriteValue(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; const AValue: TValue);
begin
  PPointer(PByte(AInstance) + PtrUInt(AToken))^ := Pointer(AValue.AsObject);
end;

function FieldReadRaw(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; ADest: Pointer; ASize: NativeInt): Boolean;
begin
  // Leitura crua por offset absoluto — cabe em ASize bytes (delega a
  // decisao de compatibilidade ao chamador que ja passou SizeOf(T)).
  Move((PByte(AInstance) + PtrUInt(AToken))^, ADest^, ASize);
  Result := True;
end;

procedure FieldWriteRaw(AOwner: TClass; AToken: Pointer;
  const AInstance: TObject; ASrc: Pointer; ASize: NativeInt);
begin
  Move(ASrc^, (PByte(AInstance) + PtrUInt(AToken))^, ASize);
end;

// --- Methods -----------------------------------------------------------------

function MethodEnumerate(AClass: TClass): TArray<TModernRTTIMethod>;
var
  LCur: TClass;
  LTab: PVmtMethodTable;
  LEntry: PVmtMethodEntry;
  LCount, LIdx, LI: Integer;
begin
  // D-25.2 do ADR issue #25: itera pela property indexada LTab^.Entry[i],
  // que resolve offset+padding por arquitetura (SizeOf(TVmtMethodEntry) e
  // 16 em x86_64 e 8 em i386 — aritmetica literal quebra i386).
  // D-25.3: subida por ClassParent aqui na enumeracao (necessaria); o
  // lookup por nome usa MethodAddress e nao replica este laco.
  Result := nil;
  if AClass = nil then
    Exit;

  LCount := 0;
  LCur := AClass;
  while LCur <> nil do
  begin
    LTab := PVmtMethodTable(PVmt(Pointer(LCur))^.vMethodTable);
    if LTab <> nil then
      Inc(LCount, LTab^.Count);
    LCur := LCur.ClassParent;
  end;

  SetLength(Result, LCount);
  LIdx := 0;
  LCur := AClass;
  while LCur <> nil do
  begin
    LTab := PVmtMethodTable(PVmt(Pointer(LCur))^.vMethodTable);
    if LTab <> nil then
      for LI := 0 to LTab^.Count - 1 do
      begin
        LEntry := LTab^.Entry[LI];
        // F-3 do STUDY: TVmtMethodEntry.Name e PShortString — deref
        // explicito antes do cast string(...).
        Result[LIdx] := TModernRTTIMethod.FromToken(
          LCur, string(LEntry^.Name^), Pointer(LEntry));
        Inc(LIdx);
      end;
    LCur := LCur.ClassParent;
  end;
end;

function MethodLookup(AClass: TClass; const AName: string;
  out AEntry: TModernRTTIMethod): Boolean;
var
  LAddr: Pointer;
begin
  // D-25.3: TObject.MethodAddress sobe a cadeia por conta propria (medido:
  // TDerived.MethodAddress('Alpha') acha metodo herdado). Nao replicamos
  // o laco por ClassParent aqui.
  Result := False;
  if AClass = nil then
    Exit;
  LAddr := AClass.MethodAddress(AName);
  if LAddr = nil then
    Exit;
  // Token pode ser nil no caminho de lookup — TModernRTTIMethod.Invoke
  // delega a TModernInvoker (que usa MethodAddress internamente pelo
  // FName), portanto nao depende do token.
  AEntry := TModernRTTIMethod.FromToken(AClass, AName, nil);
  Result := True;
end;

function MethodIsConstructor(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := False;
  raise EModernRTTIError.Create(SFPCNoConstructor);
end;

function MethodIsClassMethod(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := False;
  raise EModernRTTIError.Create(SFPCNoClassMethod);
end;

function MethodIsStatic(AOwner: TClass; AToken: Pointer): Boolean;
begin
  Result := False;
  raise EModernRTTIError.Create(SFPCNoStatic);
end;

function MethodVisibility(AOwner: TClass; AToken: Pointer): TModernVisibility;
begin
  // D-42.5 do ADR issue #42: continua levantando, mas a resourcestring
  // reescrita expoe a raiz (vmtMethodTable + D-25) em vez de mentir
  // "nao enumeravel pela RTTI". O `Result` default e apenas para
  // silenciar o compilador sobre "parametro de saida nao inicializado"
  // — o raise ocorre em seguida.
  Result := TModernVisibility.mvPublic;
  raise EModernRTTIError.Create(SFPCNoVisibility);
end;

function MethodReturnType(AOwner: TClass; AToken: Pointer): TModernRTTIType;
begin
  Result := Default(TModernRTTIType);
  raise EModernRTTIError.Create(SFPCNoReturnType);
end;

function MethodGetParameters(AOwner: TClass; AToken: Pointer):
  TArray<TModernRTTIParameter>;
begin
  Result := nil;
  raise EModernRTTIError.Create(SFPCNoParameters);
end;

// --- Parameters --------------------------------------------------------------

function ParameterName(AOwner: TClass; const AName: string;
  ATypeToken: Pointer): string;
begin
  Result := '';
  raise EModernRTTIError.Create(SFPCNoParamName);
end;

function ParameterParamType(AOwner: TClass; ATypeToken: Pointer):
  TModernRTTIType;
begin
  Result := Default(TModernRTTIType);
  raise EModernRTTIError.Create(SFPCNoParamType);
end;

// --- Properties (issue #42) --------------------------------------------------

function PropertyVisibility(AToken: Pointer): TModernVisibility;
begin
  // D-42.2 + D-42.4 do ADR issue #42: `case` explicito de EXATAMENTE 4
  // ramos sobre `TRttiProperty(AToken).Visibility`. Dado real — NAO
  // levanta. `TRttiProperty.Visibility` existe no FPC 3.2.2
  // (`rtti.pp:340,3776`) e devolve `mvPublished` para propriedades
  // declaradas em secao `published` de classe `{$M+}`.
  //
  // SEM ramo `mvAutomated` — esse identificador NAO existe em
  // `TMemberVisibility` do FPC 3.2.2 (`rtti.pp:308`); inclui-lo nao
  // compila. Os quatro ramos esgotam o enum; `else` levantando seria
  // codigo morto.
  //
  // Case labels QUALIFICADOS com `TMemberVisibility.` (do Rtti/TypInfo),
  // Result com `TModernVisibility.` (da casca), porque os dois enums
  // declaram constantes homonimas — a mesma disciplina do backend Delphi.
  case TRttiProperty(AToken).Visibility of
    TMemberVisibility.mvPrivate:   Result := TModernVisibility.mvPrivate;
    TMemberVisibility.mvProtected: Result := TModernVisibility.mvProtected;
    TMemberVisibility.mvPublic:    Result := TModernVisibility.mvPublic;
    TMemberVisibility.mvPublished: Result := TModernVisibility.mvPublished;
  end;
end;

// --- Enumeration (issue #43) -------------------------------------------------

// Helper NAO-generico compartilhado pelas seis funcoes livres. Nao muda o
// contrato "cada funcao abre com guarda por Kind" (D-4/D-43.2) — apenas
// centraliza a construcao da mensagem, que precisa distinguir P = nil (nome
// "<nil>", Kind 0) de P nao-nil mas com Kind errado (nome e Kind reais).
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
  // D-4/D-43.2: guarda por Kind aberta em cada funcao.
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  Result := string(P^.Name);
end;

function EnumMinValue(P: PTypeInfo): Integer;
begin
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  Result := GetTypeData(P)^.MinValue;
end;

function EnumMaxValue(P: PTypeInfo): Integer;
begin
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  Result := GetTypeData(P)^.MaxValue;
end;

function EnumGetName(P: PTypeInfo; AOrdinal: Integer): string;
var
  LTD: PTypeData;
begin
  // D-4/D-43.2 + D-43.3 (M-1): guarda por Kind, depois guarda por faixa
  // ANTES de delegar a TypInfo.GetEnumName — no FPC 3.2.2, GetEnumName(P, -1)
  // devolve o primeiro nome silenciosamente (indistinguivel de resposta
  // legitima). Este raise torna a garantia local (D-26).
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  LTD := GetTypeData(P);
  if (AOrdinal < LTD^.MinValue) or (AOrdinal > LTD^.MaxValue) then
    raise EModernRTTIError.CreateFmt(SEnumOrdinalOutOfRange,
      [string(P^.Name), AOrdinal]);
  Result := TypInfo.GetEnumName(P, AOrdinal);
end;

function EnumGetValue(P: PTypeInfo; const AName: string): Integer;
begin
  // D-4/D-43.2 + D-43.4 (M-2): captura o retorno de TypInfo.GetEnumValue e
  // levanta em -1. O sentinela colide com "enum poderia ter ordinal
  // negativo"; o raise torna a garantia local, nao dependente de outra
  // propriedade do FPC (D-26).
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  Result := TypInfo.GetEnumValue(P, AName);
  if Result = -1 then
    raise EModernRTTIError.CreateFmt(SEnumNameUnknown,
      [string(P^.Name), AName]);
end;

function EnumGetNames(P: PTypeInfo): TArray<string>;
var
  LTD: PTypeData;
  LMin, LMax, LI: Integer;
begin
  // D-4/D-43.2: guarda por Kind. O laco MinValue..MaxValue e seguro no FPC
  // 3.2.2 apenas porque enums com valores explicitos (M-3) nao emitem RTTI
  // (`TypeInfo(TCod = (kX=5))` nao compila). Se um dia esse comportamento
  // mudar, o laco reintroduz risco de indices fantasma — este comentario e
  // o alarme (D-43.7 do ADR).
  //
  // MUTACAO OBRIGATORIA (D-43.8 / CA-12): trocar LMax por LMax - 1 aqui
  // deve deixar Scenario_EnumerationType_GetNames_LengthAndPresence
  // vermelho no runner FPC.
  if (P = nil) or (P^.Kind <> tkEnumeration) then
    EnumRaiseWrongKind(P);
  LTD := GetTypeData(P);
  LMin := LTD^.MinValue;
  LMax := LTD^.MaxValue;
  SetLength(Result, LMax - LMin + 1);
  for LI := LMin to LMax do
    Result[LI - LMin] := TypInfo.GetEnumName(P, LI);
end;

// --- Pointer (issue #44) -----------------------------------------------------

function PointerTypeReferredType(P: PTypeInfo): TModernRTTIType;
var
  LCtx: TRttiContext;
begin
  // D-4/D-44.2: guarda por Kind aberta em cada funcao. Mensagem
  // consistente com o backend Delphi (D-44.2/D-2).
  if (P = nil) or (P^.Kind <> tkPointer) then
    raise EModernRTTIError.Create(SPointerWrongKind);
  LCtx := TRttiContext.Create;
  // MUTACAO OBRIGATORIA (issue #44 / D-44.3): trocar `RefType` por
  //   PTypeInfo(GetTypeData(P)^.RefTypeRef)
  // deixa Scenario_PointerType_ReferredType_Matches vermelho por
  // semantica. A property `RefType` (typinfo.pp:563) faz
  // `DerefTypeInfoPtr(RefTypeRef)` (typinfo.pp:3306). Usar
  // `RefTypeRef` (que e PPTypeInfo) com cast para PTypeInfo le a
  // regiao errada — delta 24 bytes em x86_64 medido no relatorio.
  // A forma literal SEM cast nao compila; o cast e obrigatorio para
  // que a mutacao seja "vermelho por semantica" e nao "erro de
  // compile" (regra de teste "cenario vermelho, nao erro de compile").
  //
  // Sem try/finally .Free — no FPC 3.2.2, TRttiContext e record por
  // valor (D-44.5 / R-5). Sem try/except — para PTypeInfo(Pointer) puro,
  // GetTypeData(P)^.RefType e nil e LCtx.GetType(nil) retorna nil,
  // caindo em TModernRTTIType.IsNil = True sem levantar.
  Result := TModernRTTIType.FromRtti(LCtx.GetType(GetTypeData(P)^.RefType));
end;

// --- Record (issue #45) ------------------------------------------------------

// Helper unificado (D-45.5) — padrao consagrado do modulo (EnumRaiseWrongKind
// :473 / issue #43). Guarda EXCLUSIVAMENTE por nil ou Kind — SEM condicao
// sobre Size (D-45.8): `record end` (Size = 0) e valido nos seis alvos e
// nao pode ser rejeitado. Cada funcao publica chama o helper como primeira
// instrucao. Preparado para receber `GetFields` da issue-filha sem duplicar
// guarda inline.
procedure RecordRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or (P^.Kind <> tkRecord) then
    raise EModernRTTIError.Create(SRecordWrongKind);
end;

function RecordTypeName(P: PTypeInfo): string;
begin
  // D-4/D-45.3: guarda por Kind aberta em cada funcao (via helper).
  RecordRaiseWrongKind(P);
  Result := string(P^.Name);
end;

function RecordTypeSize(P: PTypeInfo): Integer;
begin
  // D-4/D-45.3: guarda por Kind aberta em cada funcao (via helper).
  // RecSize e o campo canonico do TTypeData para records. NAO usar
  // ManagedFldCount para derivar nada (D-45.7): medicao mostra que o
  // campo mente para tkRecord puro (TPlain com zero campos managed
  // retorna ManagedFldCount = 2 — leitura da uniao).
  RecordRaiseWrongKind(P);
  Result := GetTypeData(P)^.RecSize;
end;

// --- Array (issue #46) -------------------------------------------------------

// Helper unificado (D-46.4) — drift novo do #46: guarda COMBINADA [tkArray,
// tkDynArray] porque as quatro funcoes livres do array aceitam os dois
// sub-Kinds e ramificam internamente. Padrao adaptado de RecordRaiseWrongKind
// (:606 / issue #45). Preparado para receber `Bounds`/`Dims` de issue-filha
// sem duplicar guarda inline.
procedure ArrayRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or not (P^.Kind in [tkArray, tkDynArray]) then
    raise EModernRTTIError.Create(SArrayWrongKind);
end;

function ArrayTypeIsDynamic(P: PTypeInfo): Boolean;
begin
  // D-4/D-46.4: guarda combinada. B-46.1: True SSE Kind = tkDynArray.
  ArrayRaiseWrongKind(P);
  Result := P^.Kind = tkDynArray;
end;

function ArrayTypeElementType(P: PTypeInfo): PTypeInfo;
begin
  // D-46.5: SEMPRE via property `elType2` (dinamico) / `ArrayData.ElType`
  // (estatico). Os campos crus correspondentes (as referencias
  // intermediarias) NAO sao usados — layout pode divergir do PTypeInfo
  // esperado, mesmo defeito das issues #29 e #44. Aceitacao: o grep de
  // refs crus na unit inteira devolve 0 (D-46.11).
  //
  // MUTACAO OBRIGATORIA 1 (D-46.9 / issue #46 / cenario 8): trocar
  // `GetTypeData(P)^.elType2` por `GetTypeData(P)^.elType` no ramo dinamico
  // deixa Scenario_ArrayType_Dynamic_LengthRaises vermelho/AV — `array of
  // Byte` (unmanaged) tem `elType = nil`, e o acesso posterior a `.Name`
  // sobre nil AVs. O log do cenario 8 vai ao PR.
  ArrayRaiseWrongKind(P);
  if P^.Kind = tkDynArray then
    Result := GetTypeData(P)^.elType2
  else
    Result := GetTypeData(P)^.ArrayData.ElType;
end;

function ArrayTypeSize(P: PTypeInfo): Integer;
begin
  // D-46.6: dinamico -> elSize (tamanho do elemento); estatico ->
  // ArrayData.Size (paridade objetiva com Delphi, medido no relatorio).
  ArrayRaiseWrongKind(P);
  if P^.Kind = tkDynArray then
    Result := GetTypeData(P)^.elSize
  else
    Result := GetTypeData(P)^.ArrayData.Size;
end;

function ArrayTypeLength(P: PTypeInfo): Integer;
begin
  // B-46.2 / D-46.2: paridade semantica com o backend Delphi — Length em
  // dinamico LEVANTA nos DOIS compiladores; RTTI de tipo nao carrega
  // contagem de instancia. Consumidor cross-compiler tem comportamento
  // identico. Em estatico devolve `ArrayData.ElCount` (produto de todos os
  // graus para multidimensional — medido; NAO `TotalElementCount`).
  ArrayRaiseWrongKind(P);
  if P^.Kind = tkDynArray then
    raise EModernRTTIError.Create(SArrayDynamicLength);
  Result := GetTypeData(P)^.ArrayData.ElCount;
end;

// --- Set (issue #46) ---------------------------------------------------------

// Helper CLASSICO — guarda por unico Kind (tkSet), padrao de
// EnumRaiseWrongKind (:483) / PointerTypeReferredType (:577) /
// RecordRaiseWrongKind (:606).
procedure SetRaiseWrongKind(P: PTypeInfo);
begin
  if (P = nil) or (P^.Kind <> tkSet) then
    raise EModernRTTIError.Create(SSetWrongKind);
end;

function SetTypeElementType(P: PTypeInfo): PTypeInfo;
begin
  // D-46.5: SEMPRE via property `CompType` — o campo cru correspondente
  // le regiao errada da uniao. Aceitacao: o grep de refs crus na unit
  // inteira devolve 0 (D-46.11).
  //
  // MUTACAO OBRIGATORIA 2 (D-46.9 / issue #46 / cenario 10): trocar
  // `GetTypeData(P)^.CompType` pelo cast do campo cru correspondente
  // (PTypeInfo(GetTypeData(P)^.<compref>)) deixa Scenario_SetType_ElementType
  // vermelho (AV ou nome lixo). O log do cenario 10 vai ao PR.
  SetRaiseWrongKind(P);
  Result := GetTypeData(P)^.CompType;
end;

// --- Context (issue #28) -----------------------------------------------------

type
  /// <summary>
  ///   Estado interno do `TModernRTTIContext` no FPC: um `TRttiContext`
  ///   nativo per-instancia e um `FRegistry: TList` (de `PTypeInfo`)
  ///   alimentado por `GetType`/`RegisterType`. O ciclo de vida e o do
  ///   refcount da `IInterface` — o ultimo record que segurar o token
  ///   dispara `Destroy` e libera o registry.
  /// </summary>
  TFPCContextToken = class(TInterfacedObject, IModernRTTIContextToken)
  private
    FContext: TRttiContext;
    FRegistry: TList;
  public
    constructor Create;
    destructor Destroy; override;
  end;

constructor TFPCContextToken.Create;
begin
  inherited Create;
  FContext := TRttiContext.Create;
  FRegistry := TList.Create;
end;

destructor TFPCContextToken.Destroy;
begin
  FRegistry.Free;
  // FContext e um record valor — nao ha Free a chamar aqui (o TRttiContext
  // do FPC libera automaticamente ao sair de escopo do objeto).
  inherited Destroy;
end;

function ContextCreate: IModernRTTIContextToken;
begin
  Result := TFPCContextToken.Create;
end;

function RegistryEnsure(AToken: TFPCContextToken; ATypeInfo: PTypeInfo): Boolean;
var
  LIdx: Integer;
begin
  // Evita duplicar: registro por identidade de PTypeInfo. TList.IndexOf
  // ja compara por Pointer — nao precisamos escrever laco a mao.
  Result := False;
  if ATypeInfo = nil then
    Exit;
  LIdx := AToken.FRegistry.IndexOf(ATypeInfo);
  if LIdx < 0 then
  begin
    AToken.FRegistry.Add(ATypeInfo);
    Result := True;
  end;
end;

function ContextGetType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
var
  LTok: TFPCContextToken;
begin
  LTok := AToken as TFPCContextToken;
  RegistryEnsure(LTok, ATypeInfo);
  Result := TModernRTTIType.FromRtti(LTok.FContext.GetType(ATypeInfo));
end;

function ContextRegisterType(AToken: IModernRTTIContextToken; ATypeInfo: PTypeInfo): TModernRTTIType;
var
  LTok: TFPCContextToken;
begin
  LTok := AToken as TFPCContextToken;
  RegistryEnsure(LTok, ATypeInfo);
  Result := TModernRTTIType.FromRtti(LTok.FContext.GetType(ATypeInfo));
end;

function ContextGetTypes(AToken: IModernRTTIContextToken): TArray<TModernRTTIType>;
var
  LTok: TFPCContextToken;
  LIdx: Integer;
  LInfo: PTypeInfo;
begin
  LTok := AToken as TFPCContextToken;
  // D-28.4: registry vazio LEVANTA em vez de devolver array vazio silencioso.
  // A mensagem instrutiva diz exatamente o que fazer (SKILL.md — nao silenciar
  // divergencia).
  //
  // MUTACAO OBRIGATORIA: remover este raise deve deixar o cenario
  // Scenario_Context_GetTypes_EmptyRegistry_Raises vermelho no runner FPC
  // (D-28.10 do ADR issue #28).
  if LTok.FRegistry.Count = 0 then
    raise EModernRTTIError.Create(SModernRTTIError_EmptyRegistry);

  SetLength(Result, LTok.FRegistry.Count);
  for LIdx := 0 to LTok.FRegistry.Count - 1 do
  begin
    LInfo := PTypeInfo(LTok.FRegistry[LIdx]);
    Result[LIdx] := TModernRTTIType.FromRtti(LTok.FContext.GetType(LInfo));
  end;
end;

function ContextFindType(AToken: IModernRTTIContextToken; const AQualifiedName: string): TModernRTTIType;
var
  LTok: TFPCContextToken;
  LIdx: Integer;
  LInfo: PTypeInfo;
  LQualified: string;
begin
  LTok := AToken as TFPCContextToken;
  Result := TModernRTTIType.FromRtti(nil);
  for LIdx := 0 to LTok.FRegistry.Count - 1 do
  begin
    LInfo := PTypeInfo(LTok.FRegistry[LIdx]);
    if LInfo = nil then
      Continue;
    // D-28.5: SO resolve tkClass. Fora de tkClass, o campo UnitName nao
    // existe no layout de TTypeData (medido kind a kind nos dois bitness
    // — le lixo ou AV silencioso). Outros kinds sao PULADOS, nao levantam.
    if LInfo^.Kind <> tkClass then
      Continue;
    LQualified := GetTypeData(LInfo)^.UnitName + '.' + string(LInfo^.Name);
    if LQualified = AQualifiedName then
    begin
      Result := TModernRTTIType.FromRtti(LTok.FContext.GetType(LInfo));
      Exit;
    end;
  end;
end;

end.
