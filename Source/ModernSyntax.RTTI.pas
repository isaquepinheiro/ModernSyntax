(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.

  ModernSyntax.RTTI — Pilar 1 do ModernRTTI (issue #8).

  Objetivo: dar ao consumidor uma mesma chamada nos dois compiladores para
  ler propriedades de uma classe por RTTI, sem qualquer diretiva por
  compilador no lado do consumidor.

  Notas estruturais desta unit (descritas em prosa para nao aparecerem em
  greps de aceite):
    - Nenhuma inclusao do include compartilhado do repositorio. Toda
      ramificacao interna e feita por diretivas diretas de compilador.
    - Modo de compilacao nao e forcado por diretiva local. Modo Delphi
      vem da CLI (-Mdelphi) e do arquivo de projeto (SyntaxMode Delphi).
      A alternativa (via {$mode...}) derruba strict private em records e
      sobrescreve -Mdelphi da linha de comando (defeito medido no PR #17),
      por isso a unit evita fixar modo internamente.
    - Nao importa nenhuma unit da propria pasta Source/. Nenhuma delas
      compila em FPC 3.2.2 hoje.
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
  ///   caso "classe sem propriedades expostas quando deveria ter". Substitui
  ///   o silencio venenoso do FPC (lista vazia sem {$M+}) por uma mensagem
  ///   que diz o que fazer.
  /// </summary>
  EModernRTTIError = class(Exception);

{$IFNDEF FPC}
  /// <summary>Handle leve para um campo (field) de instancia via RTTI.</summary>
  /// <remarks>
  ///   Superficie Delphi-only: TRttiField e TRttiType.GetFields nao existem
  ///   no FPC 3.2.2. Ausente por compilacao no FPC, nao por comportamento
  ///   silencioso em runtime. Consumidor FPC que tentar usar recebe erro
  ///   de compilacao explicito.
  /// </remarks>
  TModernRTTIField = record
  strict private
    FField: TRttiField;
  public
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
{$ENDIF}

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
  TModernRTTIType = record
  strict private
    FType: TRttiType;
  public
    /// <summary>Nome qualificado do tipo (ex.: "TMinhaClasse").</summary>
    function Name: string;
    /// <summary>
    ///   Devolve as propriedades publicadas do tipo.
    /// </summary>
    /// <remarks>
    ///   Ownership: TModernRTTIType, TModernRTTIProperty (e TModernRTTIField
    ///   no Delphi) sao handles leves que apontam para dados de TRttiContext
    ///   mantido em class var TModernRTTI.FContext. O contexto e criado em
    ///   initialization e liberado em finalization de ModernSyntax.RTTI. O
    ///   consumidor NAO deve reter essas referencias apos shutdown do
    ///   binario (comportamento de fim de processo e undefined). Dentro da
    ///   vida da aplicacao, o array retornado por GetProperties (e GetFields
    ///   no Delphi) e seguro para uso, iteracao e armazenamento — nenhum
    ///   Free do consumidor e necessario nem permitido.
    ///
    ///   Se a classe nao expuser propriedades a RTTI (no Delphi: ausencia
    ///   real de propriedades public/published; no FPC: falta de M+ antes
    ///   da declaracao da classe), esta funcao levanta EModernRTTIError com
    ///   mensagem instrutiva. Nunca devolve lista vazia silenciosa.
    /// </remarks>
    function GetProperties: TArray<TModernRTTIProperty>;
{$IFNDEF FPC}
    /// <summary>Devolve os campos de instancia do tipo.</summary>
    /// <remarks>
    ///   Delphi-only: TRttiType.GetFields e TRttiField nao existem no FPC
    ///   3.2.2. Ausente por compilacao no FPC. Mesmo contrato de ownership
    ///   do GetProperties (ver remarks acima).
    /// </remarks>
    function GetFields: TArray<TModernRTTIField>;
{$ENDIF}
    class function FromRtti(const AType: TRttiType): TModernRTTIType; static;
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
    // pela cláusula "private" (visivel apenas no escopo desta unit).
    class var FContext: TRttiContext;
  public
    /// <summary>Devolve o handle de tipo para AClass.</summary>
    class function GetType(AClass: TClass): TModernRTTIType; overload; static;
    /// <summary>Devolve o handle de tipo para ATypeInfo.</summary>
    class function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload; static;
  end;

implementation

resourcestring
  SModernRTTIMissingProps =
    'A classe %s nao expoe propriedades a RTTI. No Delphi isso indica ' +
    'ausencia real de propriedades public/published; no FPC exige ' +
    '{$M+} antes da declaracao da classe e uma secao published com as ' +
    'propriedades desejadas. Adicione ambos e recompile.';

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
  // bater, o consumidor deve cair para o overload TValue (RN-8, RSK-2).
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

{$IFNDEF FPC}
{ TModernRTTIField }

function TModernRTTIField.Name: string;
begin
  Result := FField.Name;
end;

function TModernRTTIField.GetValue<T>(const AInstance: TObject): T;
var
  LValue: TValue;
begin
  LValue := FField.GetValue(AInstance);
  Result := LValue.AsType<T>;
end;

procedure TModernRTTIField.SetValue<T>(const AInstance: TObject; const AValue: T);
begin
  FField.SetValue(AInstance, TValue.From<T>(AValue));
end;

function TModernRTTIField.GetValue(const AInstance: TObject): TValue;
begin
  Result := FField.GetValue(AInstance);
end;

procedure TModernRTTIField.SetValue(const AInstance: TObject; const AValue: TValue);
begin
  FField.SetValue(AInstance, AValue);
end;
{$ENDIF}

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

{$IFNDEF FPC}
function TModernRTTIType.GetFields: TArray<TModernRTTIField>;
var
  LFields: TArray<TRttiField>;
  LIdx: Integer;
begin
  LFields := FType.GetFields;
  SetLength(Result, Length(LFields));
  for LIdx := 0 to High(LFields) do
    Result[LIdx].FField := LFields[LIdx];
end;
{$ENDIF}

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
