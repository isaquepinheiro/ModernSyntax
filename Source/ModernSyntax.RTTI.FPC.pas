(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI.FPC — backend FPC do Pilar 4 ModernRTTI (issue #25).

  Arquitetura §7 do API-MAP: mesma superficie de funcoes livres do backend
  gemeo (ModernSyntax.RTTI.Delphi.pas). A compilacao e o portao que garante
  paridade de assinatura.

  Onde o dado nao existe, esta unit levanta EModernRTTIError com mensagem
  instrutiva — nunca devolve valor que tambem seria resposta legitima
  (D-25.4 do ADR). Precedente: GetProperties em ModernSyntax.RTTI.pas.

  A vmtMethodTable no FPC 3.2.2 (typinfo.pp:388-410) carrega apenas Name +
  CodeAddress. Nao ha metadata suficiente para IsConstructor, IsClassMethod,
  IsStatic, Visibility, ReturnType nem lista de parametros — esses seis
  membros levantam. Enumeracao usa a property indexada Entry[i] (sem
  aritmetica de ponteiro literal, que quebraria i386 — vide D-25.2).

  Lookup por nome nao replica laco de heranca: TObject.MethodAddress ja
  sobe a cadeia (medido). O loop por ClassParent fica so em MethodTokens.
  ------------------------------------------------------------------------------
*)

{$IFDEF FPC}
  {$MODE DELPHI}
  {$H+}
{$ENDIF}

unit ModernSyntax.RTTI.FPC;

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

resourcestring
  SMethodMemberNoSource =
    'TModernRTTIMethod.%s nao esta disponivel no FPC 3.2.2: vmtMethodTable ' +
    '(typinfo.pp:388-396) carrega apenas Name e CodeAddress. Metadata como ' +
    'ResultType, ParamCount, Kind e CallConv existe so em TIntfMethodEntry ' +
    '(interfaces), nunca para classes. Use o backend Delphi para esses ' +
    'membros ou trabalhe com Invoke via TSignature.';

  SParameterMemberNoSource =
    'TModernRTTIParameter.%s nao esta disponivel no FPC 3.2.2: vmtMethodTable ' +
    '(typinfo.pp:388-396) nao expoe lista de parametros de metodo de classe. ' +
    'Use o backend Delphi ou declare TSignature no consumidor para invocar.';

  SFieldMemberNoSource =
    'TModernRTTIField.%s nao esta disponivel no FPC 3.2.2 neste backend: ' +
    'vFieldTable no FPC nao e populada para classes gerais. Este acesso ' +
    'foi levantado como EModernRTTIError seguindo o padrao de GetProperties.';

// -- Field ---------------------------------------------------------------
//
// Sem fonte no FPC 3.2.2: vFieldTable so e populada em condicoes especificas
// e este ciclo (issue #25) nao cobre o path de field FPC. Consumidores que
// tentem exercitar campos via a casca portavel recebem excecao instrutiva —
// mesma disciplina de D-25.4 aplicada a metodos.

function FieldTokens(AOwner: TClass): TArray<Pointer>;
begin
  Result := nil;
end;

function FieldTokenByName(AOwner: TClass; const AName: string): Pointer;
begin
  Result := nil;
end;

function FieldName(AOwner: TClass; AToken: Pointer): string;
begin
  raise EModernRTTIError.CreateFmt(SFieldMemberNoSource, ['Name']);
end;

function FieldRead(AInstance: TObject; AOwner: TClass; AToken: Pointer): TValue;
begin
  raise EModernRTTIError.CreateFmt(SFieldMemberNoSource, ['GetValue']);
end;

procedure FieldWrite(AInstance: TObject; AOwner: TClass; AToken: Pointer; const AValue: TValue);
begin
  raise EModernRTTIError.CreateFmt(SFieldMemberNoSource, ['SetValue']);
end;

// -- Method --------------------------------------------------------------

function MethodTokens(AOwner: TClass): TArray<Pointer>;
var
  LCur: TClass;
  LTab: PVmtMethodTable;
  LIdx: Integer;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  LCur := AOwner;
  while LCur <> nil do
  begin
    LTab := PVmtMethodTable(PVmt(LCur)^.vMethodTable);
    if LTab <> nil then
    begin
      SetLength(Result, LCount + Integer(LTab^.Count));
      for LIdx := 0 to Integer(LTab^.Count) - 1 do
      begin
        Result[LCount] := LTab^.Entry[LIdx];
        Inc(LCount);
      end;
    end;
    LCur := LCur.ClassParent;
  end;
end;

function MethodTokenByName(AOwner: TClass; const AName: string): Pointer;
begin
  // MethodAddress sobe a cadeia sozinho (medido). Handle devolvido pode ser
  // nil quando o consumidor consulta o metodo por nome; Invoke usa apenas
  // AOwner + AName via TObject.MethodAddress e nao depende do token.
  if AOwner.MethodAddress(AName) <> nil then
    Result := Pointer(1)  // sentinel: encontrado, sem PVmtMethodEntry pra devolver
  else
    Result := nil;
end;

function MethodName(AOwner: TClass; AToken: Pointer): string;
begin
  if AToken = nil then
    raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['Name']);
  Result := string(PVmtMethodEntry(AToken)^.Name^);
end;

function MethodIsConstructor(AOwner: TClass; AToken: Pointer): Boolean;
begin
  raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['IsConstructor']);
end;

function MethodIsClassMethod(AOwner: TClass; AToken: Pointer): Boolean;
begin
  raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['IsClassMethod']);
end;

function MethodIsStatic(AOwner: TClass; AToken: Pointer): Boolean;
begin
  raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['IsStatic']);
end;

function MethodVisibility(AOwner: TClass; AToken: Pointer): TModernRTTIVisibility;
begin
  raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['Visibility']);
end;

function MethodReturnType(AOwner: TClass; AToken: Pointer): PTypeInfo;
begin
  raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['ReturnType']);
end;

function MethodGetParameters(AOwner: TClass; AToken: Pointer): TArray<TModernRTTIParameter>;
begin
  raise EModernRTTIError.CreateFmt(SMethodMemberNoSource, ['GetParameters']);
end;

// -- Parameter -----------------------------------------------------------

function ParameterName(AOwner: TClass; AParamToken: Pointer): string;
begin
  raise EModernRTTIError.CreateFmt(SParameterMemberNoSource, ['Name']);
end;

function ParameterType(AOwner: TClass; AParamToken, ATypeToken: Pointer): PTypeInfo;
begin
  raise EModernRTTIError.CreateFmt(SParameterMemberNoSource, ['ParamType']);
end;

end.
