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
  /// <summary>
  ///   Excecao usada por Fail(...) neste arquivo (Slice 3 / D-25.7 do ADR
  ///   issue #25 — fecha ModernSyntax #35). Padrao herdado de
  ///   UTestMS.Attributes.Scenarios.pas:31 e
  ///   UTestMS.Callback.Scenarios.pas:42. Antes, Fail levantava Exception
  ///   generica — PTestRTTI devolvia exit 0 sobre vermelho (matriz medida
  ///   no relatorio da issue #25), e a prova de mutacao nao valia nada em
  ///   CI. Com uma excecao propria, FPCUnit e DUnitX classificam a falha
  ///   como "failed" (nao "error"), e o exit code do runner reflete o
  ///   vermelho.
  /// </summary>
  ETestScenarioFailed = class(Exception);

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

  // Fixture com heranca para Scenario_GetFields_EnumeratesInheritedPublishedClassFields
  // (issue #21). Duas razoes de forma (D12 do ADR issue #21):
  //   1. Sem heranca, o cenario passaria verde mesmo com a subida por
  //      ClassParent quebrada (recursivo e nao-recursivo dariam a mesma
  //      contagem). Com heranca (InnerA em TBase, InnerB em TDerived),
  //      recursivo = 2, nao-recursivo = 1 — divergencia visivel.
  //   2. TInner como classe nomeada torna visivel a regra "so tipo classe":
  //      TObject cru inline esconderia essa restricao no proprio teste.
{$M+}
  TInner = class end;

  TBase = class
    InnerA: TInner;
  end;

  TPortableFieldFixture = class(TBase)
    InnerB: TInner;
  end;
{$M-}

  // Fixture com heranca para os cenarios de metodo do ciclo 010 / issue #25.
  // D-25.5 do ADR: usa APENAS published (nao public) para que a contagem
  // exata (Length(GetMethods)=2 em TMethodDerived) valha nos dois
  // compiladores — o Delphi enumera public+published enquanto o FPC so
  // enumera published, e a diferenca sobre published-so e simetrica.
  //
  // D-25.2 do ADR: TMethodBase publica Alpha; TMethodDerived (que herda de
  // TMethodBase) publica Gama. Isso permite provar M1 (mutacao "desligar
  // subida por ClassParent em MethodTokens" → cenario `_Exact` falha).
  //
  // Efeito colateral observavel: os metodos incrementam um contador de
  // modulo (Slice 4 do plan). O contador nao pode viver dentro de var da
  // classe — precisa ser globalmente inspecionavel pelo cenario. Contador
  // em variavel de unit satisfaz e nao contamina outros cenarios porque
  // cada cenario zera antes de invocar.
{$M+}
  TMethodBase = class
  published
    procedure Alpha;
  end;

  TMethodDerived = class(TMethodBase)
  published
    procedure Gama;
  end;
{$M-}

procedure Scenario_GetProperties_ReturnsPublishedProps;
procedure Scenario_GetValue_Integer_Roundtrip;
procedure Scenario_GetValue_String_Roundtrip;
procedure Scenario_GetValue_Currency_Roundtrip;
procedure Scenario_MissingM_RaisesEModernRTTIError;
procedure Scenario_GetFields_EnumeratesInheritedPublishedClassFields;
procedure Scenario_GetMethods_CountsPublishedInherited_Exact;
procedure Scenario_GetMethod_ByName_FindsInherited;
procedure Scenario_Method_Invoke_NoArgs;

implementation

uses
  ModernSyntax.Invoker;

var
  // Contador do efeito colateral observavel de Alpha/Gama — inspecionado
  // pelo cenario Scenario_Method_Invoke_NoArgs. Cada cenario zera antes de
  // invocar para nao vazar estado entre execucoes.
  GMethodInvokeCounter: Integer;

{ TMethodBase }

procedure TMethodBase.Alpha;
begin
  Inc(GMethodInvokeCounter);
end;

{ TMethodDerived }

procedure TMethodDerived.Gama;
begin
  Inc(GMethodInvokeCounter);
end;

procedure Fail(const AMsg: string);
begin
  // D-25.7 do ADR issue #25 (fecha ModernSyntax #35): antes esta linha
  // levantava Exception generica, o que fazia FPCUnit classificar como
  // "error" e (dependendo do runner) devolver exit code 0 sobre vermelho.
  // ETestScenarioFailed e uma classe propria — os frameworks distinguem
  // "failed" (asserticao) de "error" (excecao inesperada) e o exit code
  // reflete o vermelho corretamente.
  raise ETestScenarioFailed.Create(AMsg);
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

procedure Scenario_GetFields_EnumeratesInheritedPublishedClassFields;
var
  LFields: TArray<TModernRTTIField>;
  LIdx: Integer;
  LFoundA, LFoundB: Boolean;
begin
  LFields := TModernRTTI.GetType(TPortableFieldFixture).GetFields;
  // Contagem EXATA (D12 do ADR issue #21): >= 1 esconderia regressao
  // da subida por ClassParent; >= 2 esconderia duplicacao.
  if Length(LFields) <> 2 then
    Fail(Format('GetFields devolveu %d campos; esperado exatamente 2 (InnerA herdado + InnerB proprio)',
      [Length(LFields)]));

  // Verificacao por busca de nome — ordem NAO e especificada (D10 do ADR).
  LFoundA := False;
  LFoundB := False;
  for LIdx := 0 to High(LFields) do
  begin
    if LFields[LIdx].Name = 'InnerA' then LFoundA := True;
    if LFields[LIdx].Name = 'InnerB' then LFoundB := True;
  end;
  if not LFoundA then
    Fail('Campo InnerA (herdado de TBase) ausente do retorno de GetFields');
  if not LFoundB then
    Fail('Campo InnerB (declarado em TPortableFieldFixture) ausente do retorno de GetFields');
end;

function HasMethod(const AMethods: TArray<TModernRTTIMethod>;
  const AName: string): Boolean;
var
  LIdx: Integer;
begin
  Result := False;
  for LIdx := 0 to High(AMethods) do
    if SameText(AMethods[LIdx].Name, AName) then
      Exit(True);
end;

procedure Scenario_GetMethods_CountsPublishedInherited_Exact;
var
  LMethods: TArray<TModernRTTIMethod>;
begin
  // D-25.5 + prova de mutacao M1 (D-25.10) do ADR issue #25:
  //   TMethodDerived tem UM published proprio (Gama) e UM published
  //   herdado de TMethodBase (Alpha). Contagem EXATA = 2. Uma mutacao que
  //   desligue a subida por ClassParent em MethodTokens (M1) faz este
  //   cenario falhar — sem contagem exata, a mutacao passaria despercebida.
  LMethods := TModernRTTI.GetType(TMethodDerived).GetMethods;
  if Length(LMethods) <> 2 then
    Fail(Format('GetMethods devolveu %d metodos; esperado exatamente 2 ' +
      '(Alpha herdado + Gama proprio)', [Length(LMethods)]));

  // Verificacao por busca de nome — ordem NAO e especificada (XMLDoc).
  if not HasMethod(LMethods, 'Alpha') then
    Fail('Metodo Alpha (herdado de TMethodBase) ausente do retorno de GetMethods');
  if not HasMethod(LMethods, 'Gama') then
    Fail('Metodo Gama (declarado em TMethodDerived) ausente do retorno de GetMethods');
end;

procedure Scenario_GetMethod_ByName_FindsInherited;
var
  LMethod: TModernRTTIMethod;
begin
  // D-25.3 do ADR: no FPC, TObject.MethodAddress sobe a cadeia por conta
  // propria — GetMethod('Alpha') sobre TMethodDerived deve encontrar o
  // metodo herdado. No Delphi, TRttiType.GetMethod tambem alcanca herdado.
  LMethod := TModernRTTI.GetType(TMethodDerived).GetMethod('Alpha');
  if not SameText(LMethod.Name, 'Alpha') then
    Fail(Format('GetMethod("Alpha") devolveu handle com Name="%s"; esperado "Alpha"',
      [LMethod.Name]));
end;

procedure Scenario_Method_Invoke_NoArgs;
type
  // Assinatura tipada — D-25.9 do ADR: superficie TSignature do Pilar 3
  // (TModernInvoker.Invoke<T>). O invocador so aceita "metodo-de-objeto"
  // (SizeOf(TMethod)); TProc = procedure of object sem argumentos e o
  // caso mais simples.
  TAlphaProc = procedure of object;
var
  LObj: TMethodBase;
  LMethod: TModernRTTIMethod;
  LFn: TAlphaProc;
  LBefore, LAfter: Integer;
begin
  LObj := TMethodBase.Create;
  try
    GMethodInvokeCounter := 0;
    LBefore := GMethodInvokeCounter;

    LMethod := TModernRTTI.GetType(TMethodBase).GetMethod('Alpha');
    LFn := LMethod.Invoke<TAlphaProc>(LObj);
    LFn();

    LAfter := GMethodInvokeCounter;
    // Efeito colateral observavel — se Invoke nao chamou Alpha, o contador
    // nao mudou. Comparacao exata evita falso-positivo por concorrencia
    // (nao ha concorrencia neste runner, mas a assercao e explicita).
    if LAfter <> LBefore + 1 then
      Fail(Format('Invoke de Alpha nao incrementou o contador; before=%d, after=%d, esperado=%d',
        [LBefore, LAfter, LBefore + 1]));
  finally
    LObj.Free;
  end;
end;

end.
