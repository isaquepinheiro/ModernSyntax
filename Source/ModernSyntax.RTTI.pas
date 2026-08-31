(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI — casca publica do ModernRTTI (Pilares 1 + 4).

  Objetivo: dar ao consumidor uma mesma chamada nos dois compiladores para
  ler propriedades, campos e metodos por RTTI, sem qualquer diretiva por
  compilador no lado do consumidor.

  Arquitetura §7 do API-MAP / D-25.1 do ADR issue #25:
    - Esta unit publica NAO tem {$IFDEF} em nenhuma declaracao de tipo.
    - O unico {$IFDEF} da unit vive na uses da implementation, selecionando
      ModernSyntax.RTTI.Delphi ou ModernSyntax.RTTI.FPC.
    - Ambos os backends expoem a MESMA superficie de funcoes livres — a
      compilacao e o portao que garante paridade de assinatura.

  Notas estruturais:
    - Nenhuma inclusao do include compartilhado do repositorio. Toda
      ramificacao interna e feita por diretivas diretas de compilador.
    - Modo de compilacao nao e forcado por diretiva local. Modo Delphi
      vem da CLI (-Mdelphi) e do arquivo de projeto (SyntaxMode Delphi).
      A alternativa via {$mode...} derruba strict private em records e
      sobrescreve -Mdelphi da linha de comando (defeito medido no PR #17),
      por isso a unit evita fixar modo internamente.
    - Nao importa nenhuma unit da propria pasta Source/ na interface. Os
      backends sao consumidos apenas pela implementation (unico ifdef).
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.RTTI;

interface

uses
  SysUtils,
  TypInfo,
  Rtti;

type
  /// <summary>
  ///   Excecao instrutiva levantada quando a RTTI encontra um caso sem dado
  ///   (por exemplo, propriedades sem {$M+} no FPC, ou metodo pedido que
  ///   nao existe). Substitui o silencio venenoso do FPC (lista vazia sem
  ///   {$M+}) por uma mensagem que diz o que fazer. Tambem cobre os seis
  ///   membros de TModernRTTIMethod sem fonte no FPC (D-25.4 do ADR
  ///   issue #25) e TModernRTTIParameter no FPC (D-25.6).
  /// </summary>
  EModernRTTIError = class(Exception);

  // Forward-declaracoes internas nao existem para records em Pascal; a ordem
  // abaixo respeita a dependencia estatica: Field/Property/Type precisam
  // preceder Method/Parameter, e Type precisa preceder Method (ReturnType) /
  // Parameter (ParamType).

  /// <summary>Handle leve para um campo (field) de instancia via RTTI.</summary>
  /// <remarks>
  ///   Superficie unica nos dois compiladores; o mecanismo mora nos backends.
  ///   O estado privado (D-25.1 do ADR issue #25) e neutro: FOwner (classe
  ///   declarante), FName (nome do campo), FToken (offset como Pointer no
  ///   FPC, TRttiField como Pointer no Delphi).
  /// </remarks>
  TModernRTTIField = record
  strict private
    FOwner: TClass;
    FName: string;
    FToken: Pointer;
  public
    /// <summary>
    ///   Factory interna — nao faz parte da API publica. Chamada pelos
    ///   backends para construir handles neutros.
    /// </summary>
    class function FromToken(AOwner: TClass; const AName: string;
      AToken: Pointer): TModernRTTIField; static;
    /// <summary>Nome do campo.</summary>
    function Name: string;
    /// <summary>Le o valor do campo em AInstance e converte para T.</summary>
    function GetValue<T>(const AInstance: TObject): T; overload;
    /// <summary>Escreve AValue no campo em AInstance.</summary>
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <summary>Overload cru sobre TValue.</summary>
    /// <remarks>
    ///   Escape hatch: obriga o consumidor a importar Rtti. Prefira o
    ///   overload generico. A unit Rtti no FPC 3.2.2 e marcada experimental
    ///   e emite aviso a cada build no consumidor deste overload.
    /// </remarks>
    function GetValue(const AInstance: TObject): TValue; overload;
    /// <summary>Overload cru sobre TValue (escape hatch — ver remarks do overload GetValue).</summary>
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
  end;

  /// <summary>Handle leve para uma propriedade RTTI publicada.</summary>
  TModernRTTIProperty = record
  strict private
    FProp: TRttiProperty;
  public
    /// <summary>Nome da propriedade.</summary>
    function Name: string;
    /// <summary>True se a propriedade e legivel.</summary>
    function IsReadable: Boolean;
    /// <summary>True se a propriedade e escrivel.</summary>
    function IsWritable: Boolean;
    /// <summary>Le o valor da propriedade em AInstance e converte para T.</summary>
    function GetValue<T>(const AInstance: TObject): T; overload;
    /// <summary>Escreve AValue na propriedade em AInstance.</summary>
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <summary>Overload cru sobre TValue.</summary>
    /// <remarks>
    ///   Escape hatch: obriga o consumidor a importar Rtti. Prefira o
    ///   overload generico. A unit Rtti no FPC 3.2.2 e marcada experimental
    ///   e emite aviso a cada build no consumidor deste overload.
    /// </remarks>
    function GetValue(const AInstance: TObject): TValue; overload;
    /// <summary>Overload cru sobre TValue (escape hatch — ver remarks do overload GetValue).</summary>
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
    // Construtor interno usado pela unit; nao faz parte da API publica.
    class function FromRtti(const AProp: TRttiProperty): TModernRTTIProperty; static;
  end;

  /// <summary>Handle leve para um tipo lido por RTTI.</summary>
  /// <remarks>
  ///   Devolvido por TModernRTTI.GetType, TModernRTTIMethod.ReturnType e
  ///   TModernRTTIParameter.ParamType. Envolve TRttiType do compilador.
  ///
  ///   Nota: GetMethods e GetMethod moram no record helper
  ///   TModernRTTITypeHelper (declarado apos TModernRTTIMethod). Records
  ///   Pascal nao admitem forward-declaracao entre si — o helper e a
  ///   forma limpa de adicionar metodos que devolvem TModernRTTIMethod
  ///   sem quebrar a ordem estatica dos records.
  /// </remarks>
  TModernRTTIType = record
  // private (nao strict) de proposito: TModernRTTITypeHelper (mesma unit)
  // acessa FType. Encapsulamento e mantido pelo escopo private (consumidor
  // externo nao ve).
  private
    FType: TRttiType;
  public
    /// <summary>Nome qualificado do tipo (ex.: "TMinhaClasse").</summary>
    function Name: string;
    /// <summary>
    ///   Devolve as propriedades publicadas do tipo.
    /// </summary>
    /// <remarks>
    ///   Ownership: TModernRTTIType e TModernRTTIProperty sao handles leves
    ///   que apontam para dados de TRttiContext mantido em class var
    ///   TModernRTTI.FContext. O contexto e criado em initialization e
    ///   liberado em finalization de ModernSyntax.RTTI. O consumidor NAO
    ///   deve reter essas referencias apos shutdown do binario
    ///   (comportamento de fim de processo e undefined).
    ///
    ///   Se a classe nao expuser propriedades a RTTI (no Delphi: ausencia
    ///   real de propriedades public/published; no FPC: falta de {$M+} antes
    ///   da declaracao da classe), esta funcao levanta EModernRTTIError com
    ///   mensagem instrutiva. Nunca devolve lista vazia silenciosa.
    /// </remarks>
    function GetProperties: TArray<TModernRTTIProperty>;
    /// <summary>Devolve os campos de instancia do tipo, incluindo herdados.</summary>
    /// <remarks>
    ///   No Delphi, corresponde a TRttiType.GetFields — todos os campos
    ///   alcancaveis por RTTI, herdados incluidos. No FPC, corresponde aos
    ///   campos published de tipo classe, subindo a cadeia por ClassParent
    ///   (elos sem vmtFieldTable sao pulados; cadeia inteira sem campos
    ///   devolve array vazio).
    ///
    ///   A ordem dos elementos NAO e especificada — consumidores devem
    ///   buscar por nome, nao indexar por posicao.
    /// </remarks>
    function GetFields: TArray<TModernRTTIField>;
    class function FromRtti(const AType: TRttiType): TModernRTTIType; static;
  end;

  /// <summary>Handle leve para um parametro de metodo (issue #25).</summary>
  /// <remarks>
  ///   D-25.6 do ADR: no Delphi, FromToken popula FName e FTypeToken com
  ///   dado real de TRttiParameter.Name e TRttiParameter.ParamType.
  ///   NO FPC, TModernRTTIParameter nunca e construido — GetParameters
  ///   levanta EModernRTTIError antes. Se um consumidor construir manualmente
  ///   um Default(TModernRTTIParameter) e chamar Name ou ParamType no FPC,
  ///   ambos levantam EModernRTTIError (mesma disciplina de D-25.4).
  /// </remarks>
  TModernRTTIParameter = record
  strict private
    FOwner: TClass;
    FName: string;
    FTypeToken: Pointer;
  public
    class function FromToken(AOwner: TClass; const AName: string;
      ATypeToken: Pointer): TModernRTTIParameter; static;
    /// <summary>
    ///   Nome do parametro. No Delphi devolve o nome real; NO FPC levanta
    ///   EModernRTTIError.
    /// </summary>
    function Name: string;
    /// <summary>
    ///   Tipo do parametro. No Delphi devolve o TModernRTTIType do tipo
    ///   declarado; NO FPC levanta EModernRTTIError.
    /// </summary>
    function ParamType: TModernRTTIType;
  end;

  /// <summary>Handle leve para um metodo (issue #25).</summary>
  /// <remarks>
  ///   Superficie unica nos dois compiladores. Dos oito membros publicos,
  ///   dois tem dado real nos dois lados (Name, Invoke); os outros seis
  ///   (GetParameters, ReturnType, IsConstructor, IsClassMethod, IsStatic,
  ///   Visibility) NO FPC levantam EModernRTTIError (D-25.4). Motivo: a
  ///   vmtMethodTable do FPC 3.2.2 (typinfo.pp:388-396) so carrega Name
  ///   e CodeAddress; distincoes finas moram em TIntfMethodEntry (uso
  ///   interfaces) e nao existem para RTTI de classe. Devolver False/nil
  ///   seria "mentira indistinguivel da verdade" — o consumidor nao teria
  ///   como distinguir "nao sei" de "nao e".
  /// </remarks>
  TModernRTTIMethod = record
  strict private
    FOwner: TClass;
    FName: string;
    FToken: Pointer;
  public
    class function FromToken(AOwner: TClass; const AName: string;
      AToken: Pointer): TModernRTTIMethod; static;
    /// <summary>Nome do metodo.</summary>
    function Name: string;
    /// <summary>
    ///   Invoca o metodo em AInstance, tipando o resultado como TSignature
    ///   (assinatura do padrao TModernInvoker.Invoke — D-25.9 do ADR).
    /// </summary>
    /// <remarks>
    ///   Consumidor declara `type TFn = function(...) : T of object;` e
    ///   passa `TFn` como TSignature. O corpo delega a TModernInvoker, que
    ///   usa TObject.MethodAddress internamente. Nenhum mecanismo paralelo.
    /// </remarks>
    function Invoke<TSignature>(const AInstance: TObject): TSignature; overload;
    /// <summary>Overload de classe — invoca metodo de classe em AClass.</summary>
    function Invoke<TSignature>(const AClass: TClass): TSignature; overload;
    /// <summary>
    ///   Devolve os parametros do metodo. NO FPC levanta EModernRTTIError
    ///   (D-25.4) — vmtMethodTable nao lista parametros.
    /// </summary>
    function GetParameters: TArray<TModernRTTIParameter>;
    /// <summary>
    ///   Tipo de retorno do metodo. NO FPC levanta EModernRTTIError —
    ///   vmtMethodTable nao registra tipo de retorno.
    /// </summary>
    function ReturnType: TModernRTTIType;
    /// <summary>
    ///   True se e um construtor. NO FPC levanta EModernRTTIError — a
    ///   distincao construtor/metodo nao existe em vmtMethodTable.
    /// </summary>
    function IsConstructor: Boolean;
    /// <summary>
    ///   True se e metodo de classe. NO FPC levanta EModernRTTIError.
    /// </summary>
    function IsClassMethod: Boolean;
    /// <summary>
    ///   True se e metodo static (sem Self implicito). NO FPC levanta
    ///   EModernRTTIError.
    /// </summary>
    function IsStatic: Boolean;
    /// <summary>
    ///   Visibilidade declarada do metodo. NO FPC levanta EModernRTTIError —
    ///   vmtMethodTable so registra published.
    /// </summary>
    function Visibility: TMemberVisibility;
  end;

  /// <summary>
  ///   Record helper que adiciona GetMethods/GetMethod a TModernRTTIType.
  ///   Necessario porque records Pascal nao admitem forward-declaracao
  ///   entre si — TModernRTTIType e declarado antes de TModernRTTIMethod
  ///   (porque Method.ReturnType devolve TModernRTTIType), e o helper e a
  ///   forma limpa de completar a superficie de Type sem quebrar a ordem.
  ///   O consumidor chama AType.GetMethods normalmente — a existencia do
  ///   helper e detalhe da unit publica.
  /// </summary>
  TModernRTTITypeHelper = record helper for TModernRTTIType
    /// <summary>Devolve os metodos do tipo (issue #25).</summary>
    /// <remarks>
    ///   COBERTURA DIFERE ENTRE COMPILADORES (D-25.5 do ADR issue #25):
    ///   no Delphi, TRttiType.GetMethods alcanca metodos public e published;
    ///   no FPC, a vmtMethodTable so lista published — Length(GetMethods)
    ///   pode divergir entre compiladores para a mesma classe. E limite
    ///   honesto de mecanismo, nao bug. Fixture compartilhada deve usar
    ///   APENAS published para que asserticoes de contagem exata valham
    ///   nos dois.
    ///
    ///   No FPC, sobe a cadeia por ClassParent (D-25.2 e D-25.3); iteracao
    ///   pela property indexada LTab^.Entry[i], nao aritmetica literal.
    ///   Elos sem vMethodTable sao pulados, nao erram.
    ///
    ///   Ordem NAO e especificada — busque por nome.
    /// </remarks>
    function GetMethods: TArray<TModernRTTIMethod>;
    /// <summary>Localiza um metodo por nome (issue #25).</summary>
    /// <remarks>
    ///   No FPC usa TObject.MethodAddress, que sobe a cadeia de heranca
    ///   por conta propria (D-25.3 do ADR). Se nao encontrar, levanta
    ///   EModernRTTIError com mensagem que menciona a classe e o nome.
    /// </remarks>
    function GetMethod(const AName: string): TModernRTTIMethod;
  end;

  /// <summary>Entry point para leitura de RTTI portavel.</summary>
  /// <remarks>
  ///   Ownership: os handles devolvidos por GetType (e por chamadas em
  ///   cadeia como GetType(T).GetProperties) apontam para dados de
  ///   TRttiContext mantido em class var FContext. O contexto e criado em
  ///   initialization e liberado em finalization desta unit. Consumidor
  ///   nao deve reter referencias apos shutdown do binario.
  /// </remarks>
  TModernRTTI = record
  private
    // Nao-strict de proposito: o bloco initialization/finalization
    // desta unit acessa FContext diretamente. Encapsulamento e mantido
    // pela clausula "private" (visivel apenas no escopo desta unit).
    class var FContext: TRttiContext;
  public
    /// <summary>Devolve o handle de tipo para AClass.</summary>
    class function GetType(AClass: TClass): TModernRTTIType; overload; static;
    /// <summary>Devolve o handle de tipo para ATypeInfo.</summary>
    class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;

implementation

// Unico {$IFDEF} da unit publica (D-25.1 do ADR issue #25) — selecao do
// backend. Os dois backends expoem a mesma superficie de funcoes livres;
// a compilacao e o portao que garante paridade de assinatura.
uses
  {$IFDEF FPC}
  ModernSyntax.RTTI.FPC,
  {$ELSE}
  ModernSyntax.RTTI.Delphi,
  {$ENDIF}
  ModernSyntax.Invoker;

resourcestring
  SModernRTTIMissingProps =
    'A classe %s nao expoe propriedades a RTTI. No Delphi isso indica ' +
    'ausencia real de propriedades public/published; no FPC exige ' +
    '{$M+} antes da declaracao da classe e uma secao published com as ' +
    'propriedades desejadas. Adicione ambos e recompile.';
  SModernRTTIMethodNotFound =
    'Metodo "%s" nao encontrado em %s. No FPC exige {$M+} antes da ' +
    'declaracao da classe e uma secao published; no Delphi verifique se ' +
    'ha declaracao public ou published visivel a RTTI.';
  SModernRTTIGetMethodsNotClass =
    'GetMethods so opera sobre tipo classe; %s nao e TRttiInstanceType.';
  SModernRTTIGetMethodNotClass =
    'GetMethod so opera sobre tipo classe; %s nao e TRttiInstanceType.';

{ TModernRTTIProperty }

class function TModernRTTIProperty.FromRtti(const AProp: TRttiProperty): TModernRTTIProperty;
begin
  Result.FProp := AProp;
end;

function TModernRTTIProperty.Name: string;
begin
  Result := FProp.Name;
end;

function TModernRTTIProperty.IsReadable: Boolean;
begin
  Result := FProp.IsReadable;
end;

function TModernRTTIProperty.IsWritable: Boolean;
begin
  Result := FProp.IsWritable;
end;

function TModernRTTIProperty.GetValue<T>(const AInstance: TObject): T;
var
  LValue: TValue;
begin
  LValue := FProp.GetValue(AInstance);
{$IFDEF FPC}
  // FPC 3.2.2 TValue nao tem AsType<T> generico. Extract raw data com
  // refcount handling correto para tipos gerenciados. Se o tamanho nao
  // bater, o consumidor deve cair para o overload TValue.
  if LValue.DataSize <> SizeOf(T) then
    raise EModernRTTIError.CreateFmt(
      'GetValue<T>: tamanho incompativel na propriedade %s ' +
      '(TValue=%d bytes, T=%d bytes). Use o overload TValue para leitura crua.',
      [FProp.Name, LValue.DataSize, SizeOf(T)]);
  LValue.ExtractRawData(@Result);
{$ELSE}
  Result := LValue.AsType<T>;
{$ENDIF}
end;

procedure TModernRTTIProperty.SetValue<T>(const AInstance: TObject; const AValue: T);
begin
  FProp.SetValue(AInstance, TValue.From<T>(AValue));
end;

function TModernRTTIProperty.GetValue(const AInstance: TObject): TValue;
begin
  Result := FProp.GetValue(AInstance);
end;

procedure TModernRTTIProperty.SetValue(const AInstance: TObject; const AValue: TValue);
begin
  FProp.SetValue(AInstance, AValue);
end;

{ TModernRTTIField }

class function TModernRTTIField.FromToken(AOwner: TClass; const AName: string;
  AToken: Pointer): TModernRTTIField;
begin
  Result.FOwner := AOwner;
  Result.FName := AName;
  Result.FToken := AToken;
end;

function TModernRTTIField.Name: string;
begin
  Result := FName;
end;

function TModernRTTIField.GetValue<T>(const AInstance: TObject): T;
var
  LOk: Boolean;
  LValue: TValue;
begin
  // Delega ao backend a leitura crua. Se os tamanhos nao baterem (FieldReadRaw
  // devolve False no Delphi para tipos gerenciados que nao passam pelo path
  // rapido), cai no overload TValue com AsType/ExtractRawData.
  LOk := FieldReadRaw(FOwner, FToken, AInstance, @Result, SizeOf(T));
  if LOk then
    Exit;
  LValue := FieldReadValue(FOwner, FToken, AInstance);
  if LValue.DataSize <> SizeOf(T) then
    raise EModernRTTIError.CreateFmt(
      'GetValue<T>: tamanho incompativel no campo %s ' +
      '(TValue=%d bytes, T=%d bytes). Use o overload TValue para leitura crua.',
      [FName, LValue.DataSize, SizeOf(T)]);
  LValue.ExtractRawData(@Result);
end;

procedure TModernRTTIField.SetValue<T>(const AInstance: TObject; const AValue: T);
begin
  // Delega ao backend. FPC copia por Move; Delphi monta um TValue tipado
  // sobre o slot e chama TRttiField.SetValue.
  FieldWriteRaw(FOwner, FToken, AInstance, @AValue, SizeOf(T));
end;

function TModernRTTIField.GetValue(const AInstance: TObject): TValue;
begin
  Result := FieldReadValue(FOwner, FToken, AInstance);
end;

procedure TModernRTTIField.SetValue(const AInstance: TObject; const AValue: TValue);
begin
  FieldWriteValue(FOwner, FToken, AInstance, AValue);
end;

{ TModernRTTIType }

class function TModernRTTIType.FromRtti(const AType: TRttiType): TModernRTTIType;
begin
  Result.FType := AType;
end;

function TModernRTTIType.Name: string;
begin
  Result := FType.Name;
end;

function TModernRTTIType.GetProperties: TArray<TModernRTTIProperty>;
var
  LProps: TArray<TRttiProperty>;
  LTypeData: PTypeData;
  LIdx: Integer;
  LHasPublishedProps: Boolean;
begin
  LProps := FType.GetProperties;
  if (Length(LProps) = 0) and (FType is TRttiInstanceType) then
  begin
    LHasPublishedProps := False;
    if FType.Handle <> nil then
    begin
      LTypeData := GetTypeData(FType.Handle);
      if (LTypeData <> nil) and (LTypeData^.PropCount > 0) then
        LHasPublishedProps := True;
    end;
    if not LHasPublishedProps then
      raise EModernRTTIError.CreateFmt(SModernRTTIMissingProps, [FType.Name]);
  end;
  SetLength(Result, Length(LProps));
  for LIdx := 0 to High(LProps) do
    Result[LIdx] := TModernRTTIProperty.FromRtti(LProps[LIdx]);
end;

function TModernRTTIType.GetFields: TArray<TModernRTTIField>;
begin
  if not (FType is TRttiInstanceType) then
  begin
    Result := nil;
    Exit;
  end;
  // Delega ao backend — a enumeracao real (por vmtFieldTable no FPC, por
  // TRttiType.GetFields no Delphi) mora em ModernSyntax.RTTI.<compilador>.
  Result := FieldEnumerate(TRttiInstanceType(FType).MetaclassType);
end;

{ TModernRTTITypeHelper }

function TModernRTTITypeHelper.GetMethods: TArray<TModernRTTIMethod>;
begin
  if not (FType is TRttiInstanceType) then
    raise EModernRTTIError.CreateFmt(SModernRTTIGetMethodsNotClass, [FType.Name]);
  Result := MethodEnumerate(TRttiInstanceType(FType).MetaclassType);
end;

function TModernRTTITypeHelper.GetMethod(const AName: string): TModernRTTIMethod;
begin
  if not (FType is TRttiInstanceType) then
    raise EModernRTTIError.CreateFmt(SModernRTTIGetMethodNotClass, [FType.Name]);
  if not MethodLookup(TRttiInstanceType(FType).MetaclassType, AName, Result) then
    raise EModernRTTIError.CreateFmt(SModernRTTIMethodNotFound, [AName, FType.Name]);
end;

{ TModernRTTIParameter }

class function TModernRTTIParameter.FromToken(AOwner: TClass;
  const AName: string; ATypeToken: Pointer): TModernRTTIParameter;
begin
  Result.FOwner := AOwner;
  Result.FName := AName;
  Result.FTypeToken := ATypeToken;
end;

function TModernRTTIParameter.Name: string;
begin
  Result := ParameterName(FOwner, FName, FTypeToken);
end;

function TModernRTTIParameter.ParamType: TModernRTTIType;
begin
  Result := ParameterParamType(FOwner, FTypeToken);
end;

{ TModernRTTIMethod }

class function TModernRTTIMethod.FromToken(AOwner: TClass; const AName: string;
  AToken: Pointer): TModernRTTIMethod;
begin
  Result.FOwner := AOwner;
  Result.FName := AName;
  Result.FToken := AToken;
end;

function TModernRTTIMethod.Name: string;
begin
  Result := FName;
end;

function TModernRTTIMethod.Invoke<TSignature>(const AInstance: TObject): TSignature;
begin
  // D-25.9 do ADR: delega ao mecanismo do Pilar 3 (TObject.MethodAddress).
  // Nao introduz mecanismo paralelo.
  Result := TModernInvoker.Invoke<TSignature>(AInstance, FName);
end;

function TModernRTTIMethod.Invoke<TSignature>(const AClass: TClass): TSignature;
begin
  Result := TModernInvoker.Invoke<TSignature>(AClass, FName);
end;

function TModernRTTIMethod.GetParameters: TArray<TModernRTTIParameter>;
begin
  Result := MethodGetParameters(FOwner, FToken);
end;

function TModernRTTIMethod.ReturnType: TModernRTTIType;
begin
  Result := MethodReturnType(FOwner, FToken);
end;

function TModernRTTIMethod.IsConstructor: Boolean;
begin
  Result := MethodIsConstructor(FOwner, FToken);
end;

function TModernRTTIMethod.IsClassMethod: Boolean;
begin
  Result := MethodIsClassMethod(FOwner, FToken);
end;

function TModernRTTIMethod.IsStatic: Boolean;
begin
  Result := MethodIsStatic(FOwner, FToken);
end;

function TModernRTTIMethod.Visibility: TMemberVisibility;
begin
  Result := MethodVisibility(FOwner, FToken);
end;

{ TModernRTTI }

class function TModernRTTI.GetType(AClass: TClass): TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(FContext.GetType(AClass));
end;

class function TModernRTTI.GetType(ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(FContext.GetType(ATypeInfo));
end;

initialization
  TModernRTTI.FContext := TRttiContext.Create;

finalization
  TModernRTTI.FContext.Free;

end.
