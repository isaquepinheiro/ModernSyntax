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
  SFPCNoVisibility =
    'Visibility: nao disponivel no FPC. vmtMethodTable (typinfo.pp:388-396) ' +
    'so registra membros published; visibilidade fina (private/protected/' +
    'public) nao e enumeravel pela RTTI de classe.';
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

function MethodVisibility(AOwner: TClass; AToken: Pointer): TMemberVisibility;
begin
  Result := mvPublic;
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
