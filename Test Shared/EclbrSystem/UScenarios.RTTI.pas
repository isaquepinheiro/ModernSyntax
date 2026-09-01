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
  ModernSyntax.RTTI,
  ModernSyntax.Attributes;

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

  // Fixtures da issue #26 (TModernValue.AsType<T>). Declaradas AQUI para
  // que o cenario compartilhado e o teste local do FPC (que precisa do
  // TypeInfo(TPonto)^.Name na mensagem de excecao) enxerguem o mesmo tipo.
  // Toca #21 (heranca — nao aqui) e #38 (multiplicidade 2+ no mesmo nivel)
  // de graca no enum TColor.
  TPonto = record
    X, Y: Integer;
  end;

  TColor = (clRed, clGreen, clBlue);

  // Classe simples para o cenario _Object — nao precisa de {$M+}: o cenario
  // roundtripa a referencia via TValue.From<TObject>, nao inspeciona
  // propriedades.
  TValueObj = class
  private
    FTag: Integer;
  public
    constructor Create(ATag: Integer);
    property Tag: Integer read FTag;
  end;

  // Fixtures da issue #27 (for..in sobre as colecoes).
  //
  // TAttrForIn e TAlvoForInAttrs suportam Scenario_Attributes_ForIn_...:
  // o cenario registra UMA instancia de TAttrForIn contra TAlvoForInAttrs
  // via ModernAttributes.Register, itera LType.Attributes e valida que a
  // instancia registrada aparece na coleção.
  TAttrForIn = class(TModernAttribute)
  private
    FTag: string;
  public
    constructor Create(const ATag: string);
    property Tag: string read FTag;
  end;

  TAlvoForInAttrs = class(TObject);

  // Classe SEM published (nem M+) para Scenario_EmptyCollection_ForIn_...:
  // LType.Fields deve devolver coleção vazia — nem levantar, nem laço
  // infinito. Precisa ser distinta de TNoRttiFixture (que carrega
  // FSilent private) porque no Delphi TRttiType.GetFields tambem lista
  // private fields e a contagem 0 exige classe sem NENHUM campo.
  TEmptyForIn = class(TObject);

  // Classe com metodo published que carrega parametros — usada por
  // Scenario_Parameters_ForIn_IteratesRealParameters (Delphi-only na
  // casca — no FPC o irmao Scenario_Parameters_ForIn_RaisesOnFPC ataca
  // o mesmo metodo esperando EModernRTTIError).
{$M+}
  TMethodWithParams = class
  published
    procedure Beta(AArg: Integer; const AText: string);
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
// Cenarios da issue #26 — TModernValue.AsType<T> nos 5 tipos do CA + record
// e enum. Todos de TIPO EXATO (D-9 do ADR): o cenario Delphi-widening
// (From<Integer>(42).AsType<Int64>) foi REMOVIDO pela decisao. CA-5
// preservado (zero diretiva por compilador neste arquivo).
procedure Scenario_ModernValue_AsType_String;
procedure Scenario_ModernValue_AsType_Integer;
procedure Scenario_ModernValue_AsType_Boolean;
procedure Scenario_ModernValue_AsType_Double;
procedure Scenario_ModernValue_AsType_Object;
procedure Scenario_ModernValue_AsType_Record;
procedure Scenario_ModernValue_AsType_Enum;
// Cenarios da issue #27 — for..in sobre as coleções. Cinco comuns aos dois
// compiladores + par distinto para Parameters (RaisesOnFPC vs IteratesReal).
procedure Scenario_Fields_ForIn_IteratesFields;
procedure Scenario_Properties_ForIn_IteratesProperties;
procedure Scenario_Methods_ForIn_IteratesMethods;
procedure Scenario_Attributes_ForIn_IteratesAttributes;
procedure Scenario_EmptyCollection_ForIn_DoesNotLoop;
procedure Scenario_Parameters_ForIn_RaisesOnFPC;
procedure Scenario_Parameters_ForIn_IteratesRealParameters;
// Cenarios da issue #28 — TModernRTTIContext. Um FPC-only na casca
// (EmptyRegistry_Raises) porque o pool nativo do Delphi torna registry-vazio
// impossivel de simular (padrao "dois cenarios distintos" da #25).
procedure Scenario_Context_GetTypes_EmptyRegistry_Raises;
procedure Scenario_Context_GetTypes_AfterTwoRegisterType_ContainsBoth;
procedure Scenario_Context_FindType_Class_Found;
procedure Scenario_Context_FindType_NotFound_ReturnsNil;
procedure Scenario_Context_CopyByValue_SharesState_NoUseAfterFree;
// Cenarios da issue #42 — TModernVisibility. Par distinto para Method
// (FPC-only levanta / Delphi-only devolve mvPublished) + um cenario
// cross-compiler para Property (dado real nos dois lados). Padrao "dois
// cenarios distintos + duas cascas" da #25 governa APENAS o par de Method.
procedure Scenario_Method_Visibility_FPC_Raises;
procedure Scenario_Method_Visibility_Delphi_Returns_mvPublished;
procedure Scenario_Property_Visibility_Returns_mvPublished;

implementation

uses
  Math,
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

{ TValueObj }

constructor TValueObj.Create(ATag: Integer);
begin
  inherited Create;
  FTag := ATag;
end;

{ TAttrForIn }

constructor TAttrForIn.Create(const ATag: string);
begin
  inherited Create;
  FTag := ATag;
end;

{ TMethodWithParams }

procedure TMethodWithParams.Beta(AArg: Integer; const AText: string);
begin
  // Corpo vazio — o cenario nao invoca Beta; apenas le seus parametros
  // via LMethod.Parameters (no Delphi) ou verifica o raise (no FPC).
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

// --- Issue #26 — TModernValue.AsType<T> --------------------------------------

procedure Scenario_ModernValue_AsType_String;
var
  LResult: string;
begin
  LResult := TModernValue.From<string>('abc').AsType<string>;
  if LResult <> 'abc' then
    Fail(Format('AsType<string> devolveu "%s"; esperado "abc"', [LResult]));
end;

procedure Scenario_ModernValue_AsType_Integer;
var
  LResult: Integer;
begin
  LResult := TModernValue.From<Integer>(42).AsType<Integer>;
  if LResult <> 42 then
    Fail(Format('AsType<Integer> devolveu %d; esperado 42', [LResult]));
end;

procedure Scenario_ModernValue_AsType_Boolean;
var
  LResult: Boolean;
begin
  LResult := TModernValue.From<Boolean>(True).AsType<Boolean>;
  if LResult <> True then
    Fail(Format('AsType<Boolean> devolveu %s; esperado True', [BoolToStr(LResult, True)]));
end;

procedure Scenario_ModernValue_AsType_Double;
var
  LResult: Double;
begin
  LResult := TModernValue.From<Double>(3.14).AsType<Double>;
  // SameValue com tolerancia epsilon (Math): TValue.From<Double>(3.14) no
  // FPC 3.2.2 armazena o literal como Extended; a extracao para Double
  // devolve o Double mais proximo (3.1400000000000001), que difere do
  // literal 3.14 quando comparado bit-a-bit. SameValue com o epsilon
  // padrao do tipo Double resolve — o roundtrip semantico e o que importa.
  if not SameValue(LResult, 3.14) then
    Fail(Format('AsType<Double> devolveu %g; esperado ~3.14', [LResult]));
end;

procedure Scenario_ModernValue_AsType_Object;
var
  LObj: TValueObj;
  LResult: TValueObj;
  LOpaque: TObject;
begin
  LObj := TValueObj.Create(7);
  try
    // Ida-e-volta por TObject (tipo declarado como TValue "sabe"). Nos dois
    // compiladores, IsType(TypeInfo(TObject)) e verdadeiro sobre From<TObject>.
    LOpaque := TModernValue.From<TObject>(LObj).AsType<TObject>;
    LResult := TValueObj(LOpaque);
    if LResult <> LObj then
      Fail('AsType<TObject> nao devolveu a mesma referencia');
    if LResult.Tag <> 7 then
      Fail(Format('AsType<TObject> preservou referencia mas Tag=%d; esperado 7', [LResult.Tag]));
  finally
    LObj.Free;
  end;
end;

procedure Scenario_ModernValue_AsType_Record;
var
  LIn, LOut: TPonto;
begin
  LIn.X := 10;
  LIn.Y := 20;
  LOut := TModernValue.From<TPonto>(LIn).AsType<TPonto>;
  if (LOut.X <> 10) or (LOut.Y <> 20) then
    Fail(Format('AsType<TPonto> devolveu (%d,%d); esperado (10,20)', [LOut.X, LOut.Y]));
end;

procedure Scenario_ModernValue_AsType_Enum;
var
  LResult: TColor;
begin
  // Multiplicidade 2+ no mesmo nivel (toca #38): TColor tem tres valores;
  // roundtripamos clGreen (nem o primeiro nem o ultimo) — mutacao que
  // devolva sempre clRed ou lixo falha na igualdade.
  LResult := TModernValue.From<TColor>(clGreen).AsType<TColor>;
  if LResult <> clGreen then
    Fail(Format('AsType<TColor> devolveu ordinal %d; esperado %d (clGreen)',
      [Ord(LResult), Ord(clGreen)]));
end;

// --- Issue #27 — for..in sobre as coleções -----------------------------------

procedure Scenario_Fields_ForIn_IteratesFields;
var
  LField: TModernRTTIField;
  LCount: Integer;
  LFoundA, LFoundB: Boolean;
begin
  // Fixture TPortableFieldFixture: InnerA herdado de TBase + InnerB proprio
  // = 2 campos. `for..in` sobre LType.Fields deve iterar exatamente 2 vezes
  // e visitar ambos.
  LCount := 0;
  LFoundA := False;
  LFoundB := False;
  for LField in TModernRTTI.GetType(TPortableFieldFixture).Fields do
  begin
    Inc(LCount);
    if LField.Name = 'InnerA' then LFoundA := True;
    if LField.Name = 'InnerB' then LFoundB := True;
  end;
  if LCount <> 2 then
    Fail(Format('for..in Fields visitou %d campos; esperado exatamente 2', [LCount]));
  if not LFoundA then
    Fail('for..in Fields nao visitou InnerA (herdado de TBase)');
  if not LFoundB then
    Fail('for..in Fields nao visitou InnerB (declarado em TPortableFieldFixture)');
end;

procedure Scenario_Properties_ForIn_IteratesProperties;
var
  LProp: TModernRTTIProperty;
  LCount: Integer;
  LFoundNumber, LFoundName, LFoundAmount: Boolean;
begin
  // Fixture TPortableFixture: Number, Name, Amount = 3 propriedades published.
  LCount := 0;
  LFoundNumber := False;
  LFoundName := False;
  LFoundAmount := False;
  for LProp in TModernRTTI.GetType(TPortableFixture).Properties do
  begin
    Inc(LCount);
    if SameText(LProp.Name, 'Number') then LFoundNumber := True;
    if SameText(LProp.Name, 'Name') then LFoundName := True;
    if SameText(LProp.Name, 'Amount') then LFoundAmount := True;
  end;
  if LCount < 3 then
    Fail(Format('for..in Properties visitou %d propriedades; esperado ao menos 3', [LCount]));
  if not (LFoundNumber and LFoundName and LFoundAmount) then
    Fail(Format('for..in Properties perdeu propriedade (Number=%d, Name=%d, Amount=%d)',
      [Ord(LFoundNumber), Ord(LFoundName), Ord(LFoundAmount)]));
end;

procedure Scenario_Methods_ForIn_IteratesMethods;
var
  LMethod: TModernRTTIMethod;
  LCount: Integer;
  LFoundAlpha, LFoundGama: Boolean;
begin
  // Fixture TMethodDerived: Alpha (herdado de TMethodBase) + Gama (proprio)
  // = 2 metodos published. Simetria com GetMethods_CountsPublishedInherited_Exact.
  LCount := 0;
  LFoundAlpha := False;
  LFoundGama := False;
  for LMethod in TModernRTTI.GetType(TMethodDerived).Methods do
  begin
    Inc(LCount);
    if SameText(LMethod.Name, 'Alpha') then LFoundAlpha := True;
    if SameText(LMethod.Name, 'Gama') then LFoundGama := True;
  end;
  if LCount <> 2 then
    Fail(Format('for..in Methods visitou %d metodos; esperado exatamente 2 ' +
      '(Alpha herdado + Gama proprio)', [LCount]));
  if not LFoundAlpha then
    Fail('for..in Methods nao visitou Alpha (herdado)');
  if not LFoundGama then
    Fail('for..in Methods nao visitou Gama (proprio)');
end;

procedure Scenario_Attributes_ForIn_IteratesAttributes;
var
  LAttr: TObject;
  LCount, LTaggedCount: Integer;
begin
  // Registra UMA instancia de TAttrForIn('for-in') contra TAlvoForInAttrs.
  // `for..in LType.Attributes` deve iterar ao menos uma vez e visitar essa
  // instancia. Uso de `>= 1` em vez de igualdade absorve a possibilidade
  // (medida na regra 2 do ADENDO do ciclo 004) de atributos nativos
  // adicionais no Delphi — o cenario compartilhado nao pode assumir
  // ausencia total no Delphi.
  ModernAttributes.Register(TAlvoForInAttrs, [TAttrForIn.Create('for-in')]);

  LCount := 0;
  LTaggedCount := 0;
  for LAttr in TModernRTTI.GetType(TAlvoForInAttrs).Attributes do
  begin
    Inc(LCount);
    if (LAttr is TAttrForIn) and (TAttrForIn(LAttr).Tag = 'for-in') then
      Inc(LTaggedCount);
  end;
  if LCount < 1 then
    Fail(Format('for..in Attributes visitou %d atributos; esperado ao menos 1', [LCount]));
  if LTaggedCount < 1 then
    Fail('for..in Attributes nao visitou a instancia TAttrForIn("for-in") registrada');
end;

procedure Scenario_EmptyCollection_ForIn_DoesNotLoop;
var
  LField: TModernRTTIField;
  LCount: Integer;
begin
  // Fixture TEmptyForIn: classe sem NENHUM campo. `for..in Fields` deve
  // iterar 0 vezes — nem levantar, nem cair em laço infinito. Esta e a
  // asserção do robusto sobre coleção vazia (CA explicito da issue #27).
  LCount := 0;
  for LField in TModernRTTI.GetType(TEmptyForIn).Fields do
    Inc(LCount);
  if LCount <> 0 then
    Fail(Format('for..in Fields sobre classe vazia iterou %d vezes; esperado 0', [LCount]));
end;

procedure Scenario_Parameters_ForIn_RaisesOnFPC;
var
  LMethod: TModernRTTIMethod;
  LRaised: Boolean;
begin
  // D-26 (ADR ciclo 011): no FPC, TModernRTTIMethod.GetParameters/Parameters
  // levanta EModernRTTIError — vmtMethodTable nao lista parametros. Este
  // cenario e publicado APENAS na casca FPC (padrao "dois cenarios distintos +
  // duas cascas" da #25); a casca Delphi publica o irmao que itera.
  //
  // Padrao try/except + Fail(...) literal (UScenarios.RTTI.pas:315-323) —
  // sem chamar helper de terceiros (simbolo equivalente inexistente no repo).
  LMethod := TModernRTTI.GetType(TMethodWithParams).GetMethod('Beta');
  LRaised := False;
  try
    LMethod.Parameters;
  except
    on E: EModernRTTIError do LRaised := True;
  end;
  if not LRaised then
    Fail('esperava EModernRTTIError e nada foi levantado');
end;

procedure Scenario_Parameters_ForIn_IteratesRealParameters;
var
  LMethod: TModernRTTIMethod;
  LParam: TModernRTTIParameter;
  LCount: Integer;
begin
  // Publicado APENAS na casca Delphi (par distinto). Beta(AArg: Integer;
  // const AText: string) tem exatamente 2 parametros; `for..in Parameters`
  // deve visitar os dois.
  LMethod := TModernRTTI.GetType(TMethodWithParams).GetMethod('Beta');
  LCount := 0;
  for LParam in LMethod.Parameters do
    Inc(LCount);
  if LCount <> 2 then
    Fail(Format('for..in Parameters visitou %d parametros; esperado exatamente 2 (AArg, AText)',
      [LCount]));
end;

// --- Issue #28 — TModernRTTIContext ------------------------------------------

function CtxHasTypeByName(const ATypes: TArray<TModernRTTIType>;
  const AName: string): Boolean;
var
  LIdx: Integer;
begin
  // Busca por nome (nao por Length) — o pool nativo do Delphi tem contagem
  // indefinida, e o cenario compartilhado precisa valer nos dois.
  Result := False;
  for LIdx := 0 to High(ATypes) do
    if SameText(ATypes[LIdx].Name, AName) then
      Exit(True);
end;

procedure Scenario_Context_GetTypes_EmptyRegistry_Raises;
var
  LCtx: TModernRTTIContext;
  LRaised: Boolean;
  LMsg: string;
begin
  // MUTACAO OBRIGATORIA (D-28.10 do ADR ciclo 013): remover o `raise
  // EModernRTTIError` do ContextGetTypes no backend FPC
  // (ModernSyntax.RTTI.FPC.pas) deve tornar este cenario vermelho. Se
  // ficar verde, a proteção do D-28.4 foi silenciada.
  //
  // Este cenario e publicado APENAS na casca FPC — o pool nativo do
  // Delphi torna registry-vazio impossivel de simular (padrao "dois
  // cenarios distintos" da #25).
  LCtx := TModernRTTIContext.Create;
  LRaised := False;
  LMsg := '';
  try
    LCtx.GetTypes;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  if not LRaised then
    Fail('GetTypes sobre registry vazio nao levantou EModernRTTIError — ' +
      'proteção D-28.4 silenciada');
  if Pos('RegisterType', LMsg) = 0 then
    Fail(Format('EModernRTTIError sem mensagem instrutiva (mencao a RegisterType): "%s"', [LMsg]));
end;

procedure Scenario_Context_GetTypes_AfterTwoRegisterType_ContainsBoth;
var
  LCtx: TModernRTTIContext;
  LTypes: TArray<TModernRTTIType>;
begin
  // Registra dois tipos e verifica presenca dos dois pela busca por nome
  // no array. NAO usa Length — o pool nativo do Delphi tem contagem
  // indefinida (regra 2 do ADENDO do ciclo 004, tocando #38).
  LCtx := TModernRTTIContext.Create;
  LCtx.RegisterType(TypeInfo(TPortableFixture));
  LCtx.RegisterType(TypeInfo(TInner));
  LTypes := LCtx.GetTypes;
  if not CtxHasTypeByName(LTypes, 'TPortableFixture') then
    Fail('GetTypes nao encontrou TPortableFixture apos RegisterType');
  if not CtxHasTypeByName(LTypes, 'TInner') then
    Fail('GetTypes nao encontrou TInner apos RegisterType');
end;

procedure Scenario_Context_FindType_Class_Found;
var
  LCtx: TModernRTTIContext;
  LResult: TModernRTTIType;
begin
  // Registra TPortableFixture e busca pelo qualified name.
  // UnitName do FPC / Delphi para esta classe = 'UScenarios.RTTI'.
  LCtx := TModernRTTIContext.Create;
  LCtx.RegisterType(TypeInfo(TPortableFixture));
  LResult := LCtx.FindType('UScenarios.RTTI.TPortableFixture');
  if LResult.IsNil then
    Fail('FindType nao encontrou "UScenarios.RTTI.TPortableFixture" apos RegisterType');
  if not SameText(LResult.Name, 'TPortableFixture') then
    Fail(Format('FindType devolveu handle com Name="%s"; esperado "TPortableFixture"',
      [LResult.Name]));
end;

procedure Scenario_Context_FindType_NotFound_ReturnsNil;
var
  LCtx: TModernRTTIContext;
  LResult: TModernRTTIType;
begin
  // Nome inventado, nao registrado — `nil` aqui e resposta legitima
  // (RB-5 do ESP): FindType nunca levanta por miss.
  LCtx := TModernRTTIContext.Create;
  LResult := LCtx.FindType('UScenarios.RTTI.QueNaoExiste_XYZ_28');
  if not LResult.IsNil then
    Fail(Format('FindType de nome inexistente nao devolveu IsNil; obteve Name="%s"',
      [LResult.Name]));
end;

procedure Scenario_Context_CopyByValue_SharesState_NoUseAfterFree;
var
  LA, LB: TModernRTTIContext;
  LTypesFromB, LTypesFromA, LFinal: TArray<TModernRTTIType>;
  LSecondRaised: Boolean;
begin
  // D-28.10 — este cenario mata a regressao do desenho `Pointer` (M-E do
  // relatorio da issue #28). Afirma AS QUATRO coisas encadeadas:
  //   (a) B enxerga o que A registrou (LB := LA compartilha estado);
  //   (b) o estado e compartilhado nos dois sentidos (B registra, A ve);
  //   (c) apos A.Free, B.GetTypes continua com a contagem certa por
  //       busca por nome (nao ha use-after-free, nao ha lixo);
  //   (d) B.Free posterior NAO levanta (nao ha double-free).
  //
  // Se este cenario passar com FHandle: Pointer + ContextFree(Pointer)
  // de volta, a proteção morreu.
  LA := TModernRTTIContext.Create;
  LA.RegisterType(TypeInfo(TPortableFixture));
  LA.RegisterType(TypeInfo(TInner));

  // (a) copia por valor compartilha estado — refcount da IInterface
  //     agrega a copia (o record LB carrega a mesma FToken de LA).
  LB := LA;
  LTypesFromB := LB.GetTypes;
  if not CtxHasTypeByName(LTypesFromB, 'TPortableFixture') then
    Fail('(a) B.GetTypes nao viu TPortableFixture registrado por A — ' +
      'copia por valor nao compartilha estado');
  if not CtxHasTypeByName(LTypesFromB, 'TInner') then
    Fail('(a) B.GetTypes nao viu TInner registrado por A');

  // (b) B registra um terceiro, A enxerga — estado bidirecional.
  LB.RegisterType(TypeInfo(TValueObj));
  LTypesFromA := LA.GetTypes;
  if not CtxHasTypeByName(LTypesFromA, 'TValueObj') then
    Fail('(b) A.GetTypes nao viu TValueObj registrado por B — ' +
      'estado nao e compartilhado nos dois sentidos');

  // (c) A libera; B continua com contagem certa (busca por nome).
  //     Se copia fosse Pointer, aqui B.Count cairia para 1 (medido no
  //     relatorio da issue #28).
  LA.Free;
  LFinal := LB.GetTypes;
  if not CtxHasTypeByName(LFinal, 'TPortableFixture') then
    Fail('(c) apos A.Free, B.GetTypes perdeu TPortableFixture — ' +
      'use-after-free silencioso do desenho Pointer');
  if not CtxHasTypeByName(LFinal, 'TInner') then
    Fail('(c) apos A.Free, B.GetTypes perdeu TInner');
  if not CtxHasTypeByName(LFinal, 'TValueObj') then
    Fail('(c) apos A.Free, B.GetTypes perdeu TValueObj');

  // (d) segundo Free posterior NAO levanta. Se copia fosse Pointer com
  //     ContextFree(Pointer), aqui levantaria EInvalidPointer.
  LSecondRaised := False;
  try
    LB.Free;
  except
    on E: Exception do
      LSecondRaised := True;
  end;
  if LSecondRaised then
    Fail('(d) B.Free posterior levantou — regressao do desenho Pointer ' +
      '(double-free). D-28.10 do ADR silenciada.');
end;

// --- Issue #42 — TModernVisibility -------------------------------------------

procedure Scenario_Method_Visibility_FPC_Raises;
var
  LMethod: TModernRTTIMethod;
  LRaised: Boolean;
  LMsg: string;
begin
  // R2 do ESP: no FPC, `TModernRTTIMethod.Visibility` levanta
  // `EModernRTTIError` porque esta camada enumera por vmtMethodTable
  // (D-25) — nao por ausencia da RTL (D-42.5). Cenario publicado APENAS
  // na casca FPC (padrao "dois cenarios distintos + duas cascas").
  // Fixture: reusa TMethodBase (published Alpha), ja declarada acima.
  LMethod := TModernRTTI.GetType(TMethodBase).GetMethod('Alpha');
  LRaised := False;
  LMsg := '';
  try
    LMethod.Visibility;
  except
    on E: EModernRTTIError do
    begin
      LRaised := True;
      LMsg := E.Message;
    end;
  end;
  if not LRaised then
    Fail('esperava EModernRTTIError ao chamar Method.Visibility no FPC ' +
      '(D-42.5) e nada foi levantado');
  // A mensagem reescrita (D-42.5) menciona vmtMethodTable — sinaliza a
  // raiz real (nao a falsa "nao enumeravel pela RTTI de classe").
  if Pos('vmtMethodTable', LMsg) = 0 then
    Fail(Format('EModernRTTIError sem mencao a vmtMethodTable (raiz do D-25): "%s"',
      [LMsg]));
end;

procedure Scenario_Method_Visibility_Delphi_Returns_mvPublished;
var
  LMethod: TModernRTTIMethod;
  LVis: TModernVisibility;
begin
  // R2 do ESP: no Delphi, `TModernRTTIMethod.Visibility` devolve dado real
  // via `case` explicito de 4 ramos (D-42.2). Cenario publicado APENAS
  // na casca Delphi. TMethodBase.Alpha e `published` → mvPublished.
  LMethod := TModernRTTI.GetType(TMethodBase).GetMethod('Alpha');
  LVis := LMethod.Visibility;
  if LVis <> TModernVisibility.mvPublished then
    Fail(Format('Method.Visibility devolveu ordinal %d; esperado %d (mvPublished)',
      [Ord(LVis), Ord(TModernVisibility.mvPublished)]));
end;

procedure Scenario_Property_Visibility_Returns_mvPublished;
var
  LProps: TArray<TModernRTTIProperty>;
  LProp: TModernRTTIProperty;
  LVis: TModernVisibility;
begin
  // R3 do ESP + D-42.4 do ADR: cross-compiler — devolve dado real nos
  // dois compiladores. `TRttiProperty.Visibility` existe no Delphi e no
  // FPC 3.2.2 (`rtti.pp:340,3776`).
  //
  // Fixture: reusa TPortableFixture, ja declarada com `{$M+}` e
  // propriedade `Number` published (satisfaz o requisito de "ao menos
  // uma propriedade published em classe {$M+}").
  //
  // MUTACAO OBRIGATORIA (D-42.9 / CA-9): trocar em qualquer backend
  // (Delphi ou FPC) a linha `mvPublished: Result := mvPublished;` do
  // `case` de `PropertyVisibility` por `Result := mvPrivate;` deve
  // tornar este cenario vermelho. Sem essa validacao o cenario nao paga
  // por si (pode passar por caminho errado — fixture sem published).
  LProps := TModernRTTI.GetType(TPortableFixture).GetProperties;
  LProp := GetPropByName(LProps, 'Number');
  LVis := LProp.Visibility;
  if LVis <> TModernVisibility.mvPublished then
    Fail(Format('Property.Visibility devolveu ordinal %d; esperado %d (mvPublished)',
      [Ord(LVis), Ord(TModernVisibility.mvPublished)]));
end;

end.
