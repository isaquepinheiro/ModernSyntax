(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  UScenarios.RTTI — cenarios portaveis do Pilar 1 ModernRTTI (issue #8).

  Procedures livres, sem framework de teste, executaveis a partir das duas
  cascas (DUnitX no lado Delphi e FPCUnit no lado FPC). Cada procedure
  levanta Exception na falha. Fixtures declaradas dentro deste proprio
  arquivo com M+ / published (para as classes portaveis) e sem M+ (para
  a fixture que exercita a excecao instrutiva do R4).

  Zero diretiva por compilador neste arquivo (CA-5 do PRD / ESP).
  ------------------------------------------------------------------------------
*)

unit UScenarios.RTTI;

interface

uses
  SysUtils,
  ModernSyntax.RTTI;

type
  // Nota tecnica: FPC 3.2.2 nao aceita propriedades published de tipo record
  // (medido: erro "This kind of property cannot be published") e nem expoe
  // propriedades public pela sua Rtti.GetProperties (medido: propcount=0).
  // O item "record simples" do CA-3 do ESP e cumprido por uma propriedade
  // published de tipo Currency (compound value type escalar de 8 bytes)
  // que exercita o mesmo caminho GetValue<T>/SetValue<T> generico. RSK-2
  // do ESP anticipa reforco de fixture sem violar CA-3.

{$M+}
  TPortableFixture = class
  strict private
    FNumber: Integer;
    FName: string;
    FAmount: Currency;
  published
    property Number: Integer read FNumber write FNumber;
    property Name: string read FName write FName;
    property Amount: Currency read FAmount write FAmount;
  end;
{$M-}

  // Classe sem M+; usada por Scenario_MissingM_RaisesEModernRTTIError.
  // NAO leva {$M+} porque o cenario existe justamente para validar que a
  // ausencia levanta EModernRTTIError com mensagem instrutiva.
  TNoRttiFixture = class
  private
    FSilent: Integer;
  public
    property Silent: Integer read FSilent write FSilent;
  end;

procedure Scenario_GetProperties_ReturnsPublishedProps;
procedure Scenario_GetValue_Integer_Roundtrip;
procedure Scenario_GetValue_String_Roundtrip;
procedure Scenario_GetValue_Currency_Roundtrip;
procedure Scenario_MissingM_RaisesEModernRTTIError;

implementation

procedure Fail(const AMsg: string);
begin
  raise Exception.Create(AMsg);
end;

function HasProperty(const AProps: TArray<TModernRTTIProperty>; const AName: string): Boolean;
var
  LIdx: Integer;
begin
  Result := False;
  for LIdx := 0 to High(AProps) do
    if SameText(AProps[LIdx].Name, AName) then
      Exit(True);
end;

function GetPropByName(const AProps: TArray<TModernRTTIProperty>; const AName: string): TModernRTTIProperty;
var
  LIdx: Integer;
begin
  for LIdx := 0 to High(AProps) do
    if SameText(AProps[LIdx].Name, AName) then
      Exit(AProps[LIdx]);
  Fail(Format('Propriedade "%s" nao encontrada nas propriedades publicadas', [AName]));
end;

procedure Scenario_GetProperties_ReturnsPublishedProps;
var
  LProps: TArray<TModernRTTIProperty>;
begin
  LProps := TModernRTTI.GetType(TPortableFixture).GetProperties;
  if Length(LProps) < 3 then
    Fail(Format('GetProperties devolveu %d propriedades; esperado ao menos 3', [Length(LProps)]));
  if not HasProperty(LProps, 'Number') then
    Fail('Propriedade "Number" ausente do retorno de GetProperties');
  if not HasProperty(LProps, 'Name') then
    Fail('Propriedade "Name" ausente do retorno de GetProperties');
  if not HasProperty(LProps, 'Amount') then
    Fail('Propriedade "Amount" ausente do retorno de GetProperties');
end;

procedure Scenario_GetValue_Integer_Roundtrip;
var
  LObj: TPortableFixture;
  LProp: TModernRTTIProperty;
  LRead: Integer;
begin
  LObj := TPortableFixture.Create;
  try
    LProp := GetPropByName(TModernRTTI.GetType(TPortableFixture).GetProperties, 'Number');
    LProp.SetValue<Integer>(LObj, 42);
    if LObj.Number <> 42 then
      Fail(Format('SetValue<Integer> nao chegou no objeto; esperado 42, obtido %d', [LObj.Number]));
    LRead := LProp.GetValue<Integer>(LObj);
    if LRead <> 42 then
      Fail(Format('GetValue<Integer> devolveu %d; esperado 42', [LRead]));
  finally
    LObj.Free;
  end;
end;

procedure Scenario_GetValue_String_Roundtrip;
var
  LObj: TPortableFixture;
  LProp: TModernRTTIProperty;
  LRead: string;
begin
  LObj := TPortableFixture.Create;
  try
    LProp := GetPropByName(TModernRTTI.GetType(TPortableFixture).GetProperties, 'Name');
    LProp.SetValue<string>(LObj, 'ModernRTTI');
    if LObj.Name <> 'ModernRTTI' then
      Fail(Format('SetValue<string> nao chegou no objeto; esperado "ModernRTTI", obtido "%s"', [LObj.Name]));
    LRead := LProp.GetValue<string>(LObj);
    if LRead <> 'ModernRTTI' then
      Fail(Format('GetValue<string> devolveu "%s"; esperado "ModernRTTI"', [LRead]));
  finally
    LObj.Free;
  end;
end;

procedure Scenario_GetValue_Currency_Roundtrip;
var
  LObj: TPortableFixture;
  LProp: TModernRTTIProperty;
  LRead: Currency;
begin
  LObj := TPortableFixture.Create;
  try
    LProp := GetPropByName(TModernRTTI.GetType(TPortableFixture).GetProperties, 'Amount');
    LProp.SetValue<Currency>(LObj, 1234.5678);
    if LObj.Amount <> 1234.5678 then
      Fail(Format('SetValue<Currency> nao chegou no objeto; esperado 1234.5678, obtido %s',
        [FloatToStr(LObj.Amount)]));
    LRead := LProp.GetValue<Currency>(LObj);
    if LRead <> 1234.5678 then
      Fail(Format('GetValue<Currency> devolveu %s; esperado 1234.5678', [FloatToStr(LRead)]));
  finally
    LObj.Free;
  end;
end;

procedure Scenario_MissingM_RaisesEModernRTTIError;
var
  LRaised: Boolean;
  LMsg: string;
begin
  LRaised := False;
  LMsg := '';
  try
    TModernRTTI.GetType(TNoRttiFixture).GetProperties;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  if not LRaised then
    Fail('GetProperties de classe sem M+/published nao levantou EModernRTTIError');
  if Pos('nao expoe propriedades a RTTI', LMsg) = 0 then
    Fail(Format('EModernRTTIError com mensagem inesperada: "%s"', [LMsg]));
end;

end.
