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

implementation

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

end.
