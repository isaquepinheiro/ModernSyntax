(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI — Pilar 1/4 do ModernRTTI (issues #8 e #25).

  Objetivo: dar ao consumidor uma mesma chamada nos dois compiladores para
  ler propriedades, campos e metodos de uma classe por RTTI, sem qualquer
  diretiva por compilador no lado do consumidor.

  Arquitetura §7 do API-MAP (issue #25): esta unit e a **casca publica** —
  zero {$IFDEF} em declaracao de tipo. O unico {$IFDEF} da unit mora na
  `uses` da implementation, selecionando o backend Delphi ou FPC. Backends
  expoem a mesma superficie de funcoes livres.

  Notas estruturais:
    - Nenhuma inclusao do include compartilhado do repositorio. Toda
      ramificacao interna vai para o backend.
    - Modo de compilacao nao e forcado por diretiva local. Modo Delphi
      vem da CLI (-Mdelphi) e do arquivo de projeto. A alternativa (via
      {$mode...}) derruba strict private em records (defeito medido no
      PR #17).
    - Nao importa nenhuma unit da propria pasta Source/ que nao seja
      backend ou o Invoker (delegado por TModernRTTIMethod.Invoke).
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
  ///   Excecao instrutiva levantada quando a leitura de RTTI encontra o
  ///   caso "classe sem propriedades expostas quando deveria ter", ou
  ///   quando um membro nao tem fonte no compilador atual (padrao
  ///   estabelecido por GetProperties e formalizado no ADR/issue #25).
  ///   Substitui o silencio venenoso do FPC (lista vazia sem {$M+}) por
  ///   uma mensagem que diz o que fazer.
  /// </summary>
  EModernRTTIError = class(Exception);

  /// <summary>Visibilidade de membro RTTI, portavel entre compiladores.</summary>
  /// <remarks>
  ///   Mesma ordem e semantica de System.Rtti.TMemberVisibility em Delphi
  ///   e FPC 3.2.2. No FPC, Visibility em TModernRTTIMethod levanta
  ///   EModernRTTIError — vmtMethodTable nao carrega esse dado (D-25.4).
  /// </remarks>
  TModernRTTIVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);

  /// <summary>Handle leve para um campo (field) de instancia via RTTI.</summary>
  /// <remarks>
  ///   Arquitetura §7 (issue #25): superficie publica sem {$IFDEF}. Estado
  ///   privado neutro (FOwner/FName/FToken). No Delphi, o token envolve
  ///   TRttiField. No FPC 3.2.2, vFieldTable nao e populada para classes
  ///   gerais e os metodos levantam EModernRTTIError com mensagem
  ///   instrutiva — mesmo padrao de D-25.4.
  /// </remarks>
  TModernRTTIField = record
  strict private
    FOwner: TClass;
    FName: string;
    FToken: Pointer;
  public
    /// <summary>Nome do campo.</summary>
    function Name: string;
    /// <summary>Le o valor do campo em AInstance e converte para T.</summary>
    function GetValue<T>(const AInstance: TObject): T; overload;
    /// <summary>Escreve AValue no campo em AInstance.</summary>
    procedure SetValue<T>(const AInstance: TObject; const AValue: T); overload;
    /// <summary>Overload cru sobre TValue (escape hatch).</summary>
    function GetValue(const AInstance: TObject): TValue; overload;
    /// <summary>Overload cru sobre TValue (escape hatch).</summary>
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
    // Construtor interno usado pela unit; nao faz parte da API publica.
    class function FromToken(AOwner: TClass; const AName: string;
      AToken: Pointer): TModernRTTIField; static;
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
    /// <summary>Overload cru sobre TValue (escape hatch).</summary>
    function GetValue(const AInstance: TObject): TValue; overload;
    /// <summary>Overload cru sobre TValue (escape hatch).</summary>
    procedure SetValue(const AInstance: TObject; const AValue: TValue); overload;
    // Construtor interno usado pela unit; nao faz parte da API publica.
    class function FromRtti(const AProp: TRttiProperty): TModernRTTIProperty; static;
  end;

  /// <summary>Handle leve para um parametro de metodo via RTTI.</summary>
  /// <remarks>
  ///   Arquitetura §7 (issue #25): superficie publica sem {$IFDEF}. Estado
  ///   privado neutro (FOwner/FName/FToken/FTypeToken). No Delphi, tokens
  ///   envolvem TRttiParameter e TRttiType respectivamente. No FPC 3.2.2,
  ///   vmtMethodTable nao carrega lista de parametros: Name e ParamType
  ///   levantam EModernRTTIError (D-25.4).
  /// </remarks>
  TModernRTTIParameter = record
  strict private
    FOwner: TClass;
    FName: string;
    FToken: Pointer;
    FTypeToken: Pointer;
  public
    /// <summary>Nome do parametro. No FPC levanta EModernRTTIError.</summary>
    function Name: string;
    /// <summary>
    ///   PTypeInfo do parametro. Portavel entre compiladores; consumidor
    ///   pode envolver com TModernRTTI.GetType(ParamType) para obter o
    ///   handle rico. No FPC levanta EModernRTTIError (vmtMethodTable nao
    ///   carrega esse dado).
    /// </summary>
    function ParamType: PTypeInfo;
    // Construtor interno usado pelos backends.
    class function FromToken(AOwner: TClass; const AName: string;
      AToken, ATypeToken: Pointer): TModernRTTIParameter; static;
  end;

  /// <summary>Handle leve para um metodo via RTTI.</summary>
  /// <remarks>
  ///   Arquitetura §7 (issue #25): superficie publica sem {$IFDEF}. Estado
  ///   privado neutro (FOwner/FName/FToken).
  ///
  ///   Divergencia declarada por compilador (D-25.4 do ADR):
  ///     - Name e Invoke funcionam em ambos os compiladores.
  ///     - Delphi envolve System.Rtti.TRttiMethod, entao IsConstructor,
  ///       IsClassMethod, IsStatic, Visibility, ReturnType e GetParameters
  ///       devolvem dados reais.
  ///     - FPC 3.2.2 le vmtMethodTable (typinfo.pp:388-396), que carrega
  ///       apenas Name e CodeAddress. Os seis membros acima levantam
  ///       EModernRTTIError com mensagem apontando vmtMethodTable e
  ///       TIntfMethodEntry. Precedente: TModernRTTIType.GetProperties.
  /// </remarks>
  TModernRTTIMethod = record
  strict private
    FOwner: TClass;
    FName: string;
    FToken: Pointer;
  public
    /// <summary>Nome do metodo.</summary>
    function Name: string;
    /// <summary>
    ///   Devolve um metodo tipado como TSignature ligado a AInstance,
    ///   usando TObject.MethodAddress via ModernSyntax.Invoker (Pilar 3).
    /// </summary>
    /// <remarks>
    ///   D-25.9: assinatura segue o padrao do TModernInvoker.Invoke&lt;T&gt;
    ///   — o consumidor declara `type TFn = procedure(...) of object;` antes
    ///   de invocar, evitando prometer o que o FPC nao pode entregar
    ///   (vmtMethodTable nao da tipos dos parametros).
    /// </remarks>
    function Invoke<TSignature>(const AInstance: TObject): TSignature; overload;
    /// <summary>
    ///   Overload de classe: devolve um metodo tipado como TSignature ligado
    ///   a AClass. Usa TObject.MethodAddress na classe.
    /// </summary>
    function Invoke<TSignature>(const AClass: TClass): TSignature; overload;
    /// <summary>
    ///   Parametros do metodo. No FPC 3.2.2 levanta EModernRTTIError
    ///   (vmtMethodTable nao carrega essa metadata).
    /// </summary>
    function GetParameters: TArray<TModernRTTIParameter>;
    /// <summary>
    ///   PTypeInfo do retorno (nil para procedures). Portavel entre
    ///   compiladores; consumidor pode envolver com TModernRTTI.GetType.
    ///   No FPC 3.2.2 levanta EModernRTTIError (vmtMethodTable nao carrega
    ///   esse dado).
    /// </summary>
    function ReturnType: PTypeInfo;
    /// <summary>True se e um construtor. No FPC levanta EModernRTTIError.</summary>
    function IsConstructor: Boolean;
    /// <summary>True se e metodo de classe. No FPC levanta EModernRTTIError.</summary>
    function IsClassMethod: Boolean;
    /// <summary>True se e metodo static. No FPC levanta EModernRTTIError.</summary>
    function IsStatic: Boolean;
    /// <summary>Visibilidade do metodo. No FPC levanta EModernRTTIError.</summary>
    function Visibility: TModernRTTIVisibility;
    // Construtor interno usado pelos backends.
    class function FromToken(AOwner: TClass; const AName: string;
      AToken: Pointer): TModernRTTIMethod; static;
  end;

  /// <summary>Handle leve para um tipo lido por RTTI.</summary>
  TModernRTTIType = record
  strict private
    FType: TRttiType;
    FClass: TClass;
  public
    /// <summary>Nome do tipo (ex.: "TMinhaClasse").</summary>
    function Name: string;
    /// <summary>
    ///   Devolve as propriedades publicadas do tipo.
    /// </summary>
    /// <remarks>
    ///   Se a classe nao expuser propriedades a RTTI, levanta
    ///   EModernRTTIError com mensagem instrutiva.
    /// </remarks>
    function GetProperties: TArray<TModernRTTIProperty>;
    /// <summary>
    ///   Devolve os campos de instancia do tipo.
    /// </summary>
    /// <remarks>
    ///   No Delphi, envolve TRttiType.GetFields. No FPC 3.2.2, vFieldTable
    ///   nao e populada para classes gerais — este metodo devolve array
    ///   vazio e os acessos ao token levantam EModernRTTIError (D-25.4).
    /// </remarks>
    function GetFields: TArray<TModernRTTIField>;
    /// <summary>
    ///   Devolve os metodos do tipo.
    /// </summary>
    /// <remarks>
    ///   Cobertura difere por compilador (D-25.5):
    ///     - Delphi enumera metodos `public` E `published`.
    ///     - FPC 3.2.2 enumera apenas os `published`, iterando a
    ///       vmtMethodTable e subindo a cadeia por ClassParent.
    ///   Para a mesma classe, Length(GetMethods) pode divergir entre os
    ///   compiladores — e limite honesto, nao bug. Consumidores portaveis
    ///   devem trabalhar apenas com metodos `published` e buscar por nome.
    /// </remarks>
    function GetMethods: TArray<TModernRTTIMethod>;
    /// <summary>
    ///   Busca um metodo por nome. Levanta EModernRTTIError se nao achar.
    /// </summary>
    /// <remarks>
    ///   No FPC 3.2.2 usa TObject.MethodAddress, que sobe a cadeia sozinho
    ///   — sem laco proprio por ClassParent (D-25.3).
    /// </remarks>
    function GetMethod(const AName: string): TModernRTTIMethod;
    // Construtor interno usado pela unit; nao faz parte da API publica.
    class function FromRtti(const AType: TRttiType): TModernRTTIType; static;
    // Fabrica para tipos vindos apenas de TClass (usado pelo FPC).
    class function FromClass(AClass: TClass): TModernRTTIType; static;
  end;

  /// <summary>Entry point para leitura de RTTI portavel.</summary>
  TModernRTTI = record
  private
    class var FContext: TRttiContext;
  public
    /// <summary>Devolve o handle de tipo para AClass.</summary>
    class function GetType(AClass: TClass): TModernRTTIType; overload; static;
    /// <summary>Devolve o handle de tipo para ATypeInfo.</summary>
    class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
    /// <summary>Acesso publico ao TRttiContext compartilhado — usado pelo backend Delphi.</summary>
    class function Context: TRttiContext; static;
  end;

implementation

// Backend selecionado por compilador (§7 do API-MAP — o UNICO {$IFDEF} da unit).
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
    'Metodo "%s" nao encontrado em %s. No FPC exige {$M+} e secao ' +
    'published; no Delphi exige que o metodo esteja public ou published.';

// -- TModernRTTIField ----------------------------------------------------

class function TModernRTTIField.FromToken(AOwner: TClass; const AName: string;
  AToken: Pointer): TModernRTTIField;
begin
  Result.FOwner := AOwner;
  Result.FName := AName;
  Result.FToken := AToken;
end;

function TModernRTTIField.Name: string;
begin
  if FName <> '' then
    Result := FName
  else
    Result := FieldName(FOwner, FToken);
end;

function TModernRTTIField.GetValue<T>(const AInstance: TObject): T;
var
  LValue: TValue;
begin
  LValue := FieldRead(AInstance, FOwner, FToken);
  // Extracao portavel (Delphi + FPC 3.2.2): checa tamanho e le raw.
  // FPC 3.2.2 nao tem TValue.AsType<T>; Delphi tem, mas ExtractRawData
  // funciona nos dois e evita o IFDEF que §7 baniria do corpo.
  if LValue.DataSize <> SizeOf(T) then
    raise EModernRTTIError.CreateFmt(
      'GetValue<T>: tamanho incompativel no campo %s ' +
      '(TValue=%d bytes, T=%d bytes). Use o overload TValue para leitura crua.',
      [FName, LValue.DataSize, SizeOf(T)]);
  LValue.ExtractRawData(@Result);
end;

procedure TModernRTTIField.SetValue<T>(const AInstance: TObject; const AValue: T);
begin
  FieldWrite(AInstance, FOwner, FToken, TValue.From<T>(AValue));
end;

function TModernRTTIField.GetValue(const AInstance: TObject): TValue;
begin
  Result := FieldRead(AInstance, FOwner, FToken);
end;

procedure TModernRTTIField.SetValue(const AInstance: TObject; const AValue: TValue);
begin
  FieldWrite(AInstance, FOwner, FToken, AValue);
end;

// -- TModernRTTIProperty -------------------------------------------------

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
  // Extracao portavel (Delphi + FPC 3.2.2) — mesmo raciocinio de
  // TModernRTTIField.GetValue<T>.
  if LValue.DataSize <> SizeOf(T) then
    raise EModernRTTIError.CreateFmt(
      'GetValue<T>: tamanho incompativel na propriedade %s ' +
      '(TValue=%d bytes, T=%d bytes). Use o overload TValue para leitura crua.',
      [FProp.Name, LValue.DataSize, SizeOf(T)]);
  LValue.ExtractRawData(@Result);
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

// -- TModernRTTIParameter ------------------------------------------------

class function TModernRTTIParameter.FromToken(AOwner: TClass; const AName: string;
  AToken, ATypeToken: Pointer): TModernRTTIParameter;
begin
  Result.FOwner := AOwner;
  Result.FName := AName;
  Result.FToken := AToken;
  Result.FTypeToken := ATypeToken;
end;

function TModernRTTIParameter.Name: string;
begin
  // Delphi: FName populado por FromToken em MethodGetParameters.
  // FPC: FName vazio (MethodGetParameters levanta antes; construcao manual
  //      cai em ParameterName que tambem levanta).
  if FName <> '' then
    Result := FName
  else
    Result := ParameterName(FOwner, FToken);
end;

function TModernRTTIParameter.ParamType: PTypeInfo;
begin
  Result := ParameterType(FOwner, FToken, FTypeToken);
end;

// -- TModernRTTIMethod ---------------------------------------------------

class function TModernRTTIMethod.FromToken(AOwner: TClass; const AName: string;
  AToken: Pointer): TModernRTTIMethod;
begin
  Result.FOwner := AOwner;
  Result.FName := AName;
  Result.FToken := AToken;
end;

function TModernRTTIMethod.Name: string;
begin
  if FName <> '' then
    Result := FName
  else
    Result := MethodName(FOwner, FToken);
end;

function TModernRTTIMethod.Invoke<TSignature>(const AInstance: TObject): TSignature;
begin
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

function TModernRTTIMethod.ReturnType: PTypeInfo;
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

function TModernRTTIMethod.Visibility: TModernRTTIVisibility;
begin
  Result := MethodVisibility(FOwner, FToken);
end;

// -- TModernRTTIType -----------------------------------------------------

class function TModernRTTIType.FromRtti(const AType: TRttiType): TModernRTTIType;
begin
  Result.FType := AType;
  if (AType <> nil) and (AType is TRttiInstanceType) then
    Result.FClass := TRttiInstanceType(AType).MetaclassType
  else
    Result.FClass := nil;
end;

class function TModernRTTIType.FromClass(AClass: TClass): TModernRTTIType;
begin
  Result.FType := TModernRTTI.Context.GetType(AClass);
  Result.FClass := AClass;
end;

function TModernRTTIType.Name: string;
begin
  if FType <> nil then
    Result := FType.Name
  else if FClass <> nil then
    Result := FClass.ClassName
  else
    Result := '';
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
var
  LTokens: TArray<Pointer>;
  LIdx: Integer;
  LClass: TClass;
begin
  LClass := FClass;
  if (LClass = nil) and (FType is TRttiInstanceType) then
    LClass := TRttiInstanceType(FType).MetaclassType;
  LTokens := FieldTokens(LClass);
  SetLength(Result, Length(LTokens));
  for LIdx := 0 to High(LTokens) do
    Result[LIdx] := TModernRTTIField.FromToken(LClass, '', LTokens[LIdx]);
end;

function TModernRTTIType.GetMethods: TArray<TModernRTTIMethod>;
var
  LTokens: TArray<Pointer>;
  LIdx: Integer;
  LClass: TClass;
  LName: string;
begin
  LClass := FClass;
  if (LClass = nil) and (FType is TRttiInstanceType) then
    LClass := TRttiInstanceType(FType).MetaclassType;
  LTokens := MethodTokens(LClass);
  SetLength(Result, Length(LTokens));
  for LIdx := 0 to High(LTokens) do
  begin
    LName := MethodName(LClass, LTokens[LIdx]);
    Result[LIdx] := TModernRTTIMethod.FromToken(LClass, LName, LTokens[LIdx]);
  end;
end;

function TModernRTTIType.GetMethod(const AName: string): TModernRTTIMethod;
var
  LToken: Pointer;
  LClass: TClass;
begin
  LClass := FClass;
  if (LClass = nil) and (FType is TRttiInstanceType) then
    LClass := TRttiInstanceType(FType).MetaclassType;
  LToken := MethodTokenByName(LClass, AName);
  if LToken = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTIMethodNotFound,
      [AName, LClass.ClassName]);
  Result := TModernRTTIMethod.FromToken(LClass, AName, LToken);
end;

// -- TModernRTTI ---------------------------------------------------------

class function TModernRTTI.GetType(AClass: TClass): TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(FContext.GetType(AClass));
  // Guard: se GetType nao resolveu (fpc-side sem RTTI), ainda queremos operar
  // pelo TClass — path FPC-only via vmtMethodTable.
  if (Result.Name = '') and (AClass <> nil) then
    Result := TModernRTTIType.FromClass(AClass);
end;

class function TModernRTTI.GetType(ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(FContext.GetType(ATypeInfo));
end;

class function TModernRTTI.Context: TRttiContext;
begin
  Result := FContext;
end;

initialization
  TModernRTTI.FContext := TRttiContext.Create;

finalization
  TModernRTTI.FContext.Free;

end.
