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
  Rtti,
  ModernSyntax.Attributes;

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

resourcestring
  /// <summary>
  ///   Mensagem instrutiva da guarda de nil-handle uniformizada pelos seis
  ///   membros de TModernRTTIType (Name, GetProperties, GetFields, GetMethods,
  ///   GetMethod, Attributes — issues #49 e #56). Exposta na interface porque
  ///   o cenario compartilhado UScenarios.RTTI compara a mensagem por
  ///   igualdade estrita (D-56.2/D-56.3 do ADR issue #56).
  /// </summary>
  SModernRTTINilHandle =
    'handle nao inicializado (IsNil = True). Verifique IsNil antes de chamar %s.';

type
  /// <summary>
  ///   Enum publico proprio da casca de RTTI para expressar visibilidade de
  ///   membros (issue #42). Substitui `TMemberVisibility` de `TypInfo` na
  ///   superficie publica desta unit (D-42.1 do ADR issue #42) — a casca
  ///   nao vaza tipos do RTL de cada compilador. Ordem espelha
  ///   `TMemberVisibility` do Delphi/FPC: `mvPrivate < mvProtected <
  ///   mvPublic < mvPublished`. Se `TMemberVisibility` de algum
  ///   compilador vier a incluir valor adicional (ex.: `mvAutomated` no
  ///   Delphi), o backend Delphi levanta `EModernRTTIError` no primeiro
  ///   chamador (D-51.1 do ADR issue #51); no FPC os 4 ramos esgotam o
  ///   `TMemberVisibility` atual (`rtti.pp:308`), então o `case` sem
  ///   `else` é correto **hoje** — mas o FPC **tampouco** faz análise
  ///   de exaustividade: medido no 3.2.2, valor não mapeado compila
  ///   **sem erro e sem warning** e devolve lixo (229 em i386, 0 em
  ///   x86_64 — e 0 é `mvPrivate`, um valor plausível). Ver #60.
  /// </summary>
  TModernVisibility = (mvPrivate, mvProtected, mvPublic, mvPublished);

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
    /// <summary>
    ///   Visibilidade declarada da propriedade (issue #42). Devolve
    ///   dado real nos DOIS compiladores — `TRttiProperty.Visibility`
    ///   existe no Delphi e no FPC 3.2.2 (`rtti.pp:340,3776`) e devolve
    ///   `mvPublished` para propriedades declaradas em secao
    ///   `published` de classe com `{$M+}`.
    /// </summary>
    /// <remarks>
    ///   Assimetria deliberada com `TModernRTTIMethod.Visibility` (que
    ///   NO FPC levanta): aqui NAO ha raise no FPC. A visibilidade de
    ///   propriedades esta no caminho da RTL nos dois lados, entao a
    ///   casca devolve o valor mapeado por `case` explicito de 4 ramos
    ///   (D-42.2 do ADR issue #42), sem depender de `Ord`.
    /// </remarks>
    function Visibility: TModernVisibility;
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
    /// <remarks>
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar.
    /// </remarks>
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
    ///
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar.
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
    ///
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar. (Handles validos de tipos
    ///   nao-classe — records, enums — continuam devolvendo <c>nil</c>
    ///   silenciosamente; o contrato de nil-handle nao se aplica a eles.)
    /// </remarks>
    function GetFields: TArray<TModernRTTIField>;
    class function FromRtti(const AType: TRttiType): TModernRTTIType; static;
    /// <summary>
    ///   True quando o handle envolve `nil` (por exemplo, resposta de
    ///   `TModernRTTIContext.FindType` para nome nao encontrado).
    ///   `nil` aqui e resposta legitima, nao falha escondida — este
    ///   predicado torna a resposta inspecionavel sem obrigar o
    ///   consumidor a comparar `Result.Name` ou apanhar excecao.
    /// </summary>
    function IsNil: Boolean;
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
    ///   Visibilidade declarada do metodo. NO FPC levanta
    ///   `EModernRTTIError` — nao pela ausencia da RTL
    ///   (`TRttiMember.Visibility` existe em `rtti.pp:317`), mas
    ///   porque esta camada enumera metodos por `vmtMethodTable`
    ///   (D-25 do ADR issue #25) e `TVmtMethodEntry` so carrega
    ///   `Name` e `CodeAddress`; `TRttiMethod` fica fora do caminho
    ///   escolhido. Trocar para `TRttiMethod` perderia a enumeracao
    ///   por heranca da #25 (D-42.5 do ADR issue #42).
    /// </summary>
    function Visibility: TModernVisibility;
    /// <summary>
    ///   Parametros do metodo, expostos como coleção iteravel por `for..in`
    ///   (issue #27). Alias puro de `GetParameters` — a coleção subjacente
    ///   ja e `TArray<TModernRTTIParameter>` e `for..in` sobre `TArray<T>`
    ///   compila e roda nos dois compiladores.
    /// </summary>
    /// <remarks>
    ///   No FPC, acessar `Parameters` levanta `EModernRTTIError` — a
    ///   assinatura de método de classe não existe no FPC 3.2.2 (D-26 do
    ///   ADR ciclo 011; vmtMethodTable so carrega Name e CodeAddress). No
    ///   Delphi, devolve os parametros reais via TRttiMethod.GetParameters.
    ///   Mesma divergencia em voz alta que `GetParameters`.
    /// </remarks>
    property Parameters: TArray<TModernRTTIParameter> read GetParameters;
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
  strict private
    /// <summary>
    ///   Forwarders internos das properties `Fields`, `Properties` e
    ///   `Attributes` (issue #27). Nao fazem parte da API publica — o
    ///   consumidor chama `LType.Fields`, nao `LType.PropFields`.
    ///
    ///   Existem porque no FPC 3.2.2 uma `property` de record helper com
    ///   `read <Nome>` nao resolve <Nome> contra metodos do tipo alvo
    ///   (medido: "Unknown class field or method identifier GetFields"),
    ///   diferente do Delphi. Cada forwarder chama o metodo do tipo alvo
    ///   via `Self`, mantendo a delegacao pura e o corpo trivial.
    /// </summary>
    function PropFields: TArray<TModernRTTIField>;
    function PropProperties: TArray<TModernRTTIProperty>;
    function PropAttributes: TArray<TObject>;
  public
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
    ///
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar.
    /// </remarks>
    function GetMethods: TArray<TModernRTTIMethod>;
    /// <summary>Localiza um metodo por nome (issue #25).</summary>
    /// <remarks>
    ///   No FPC usa TObject.MethodAddress, que sobe a cadeia de heranca
    ///   por conta propria (D-25.3 do ADR). Se nao encontrar, levanta
    ///   EModernRTTIError com mensagem que menciona a classe e o nome.
    ///
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar.
    /// </remarks>
    function GetMethod(const AName: string): TModernRTTIMethod;
    /// <summary>
    ///   Campos do tipo, expostos como coleção iteravel por `for..in`
    ///   (issue #27). Alias puro de `GetFields`.
    /// </summary>
    property Fields: TArray<TModernRTTIField> read PropFields;
    /// <summary>
    ///   Propriedades do tipo, expostas como coleção iteravel por `for..in`
    ///   (issue #27). Alias puro de `GetProperties`.
    /// </summary>
    property Properties: TArray<TModernRTTIProperty> read PropProperties;
    /// <summary>
    ///   Metodos do tipo, expostos como coleção iteravel por `for..in`
    ///   (issue #27). Alias puro de `GetMethods`.
    /// </summary>
    property Methods: TArray<TModernRTTIMethod> read GetMethods;
    /// <summary>
    ///   Atributos por-tipo, expostos como coleção iteravel por `for..in`
    ///   (issue #27). Alias puro de `ModernAttributes.GetAttributes` — vale
    ///   nos dois compiladores (regra 2 do ADENDO do ciclo 004: no Delphi,
    ///   funde nativos com registrados; no FPC, so registrados).
    /// </summary>
    /// <remarks>
    ///   Quando <c>IsNil = True</c>, levanta <c>EModernRTTIError</c>;
    ///   verifique <c>IsNil</c> antes de chamar.
    /// </remarks>
    property Attributes: TArray<TObject> read PropAttributes;
  end;

  /// <summary>
  ///   Envolve TValue nos dois compiladores e entrega AsType&lt;T&gt; — o
  ///   unico membro do TValue medido AUSENTE no FPC 3.2.2 (issue #26).
  ///   Superficie MINIMA: From&lt;T&gt;, FromValue, AsType&lt;T&gt;. Os
  ///   demais membros do TValue (IsEmpty, TypeInfo, Kind, ToString, AsObject,
  ///   AsString, AsInteger, IsObject, From&lt;T&gt;) foram medidos OK no FPC
  ///   e o consumidor os usa direto no TValue nativo.
  /// </summary>
  /// <remarks>
  ///   Arquitetura §7 do API-MAP / D-2 do ADR issue #26: o corpo de
  ///   AsType&lt;T&gt; e uma linha, `Result := TValueOps.AsType&lt;T&gt;(FValue)`,
  ///   sem qualquer {$IFDEF} — TValueOps existe em cada backend (mesma
  ///   assinatura, homonimo), e o unico {$IFDEF} da unit publica seleciona
  ///   o backend na clausula uses.
  /// </remarks>
  TModernValue = record
  strict private
    FValue: TValue;
  public
    /// <summary>Constroi um TModernValue tipado a partir de um valor de T.</summary>
    class function From<T>(const AValue: T): TModernValue; static;
    /// <summary>Constroi um TModernValue a partir de um TValue ja existente.</summary>
    class function FromValue(const AValue: TValue): TModernValue; static;
    /// <summary>
    ///   Converte o valor envolvido para T.
    /// </summary>
    /// <remarks>
    ///   No Delphi, AsType&lt;T&gt; herda a semantica de conversao do TValue
    ///   nativo, incluindo alargamento de ordinais. No FPC 3.2.2, exige tipo
    ///   exato. Conversao entre tipos diferentes nao e garantida nos dois
    ///   compiladores; use o tipo exato para codigo portavel.
    ///
    ///   D-6 do ADR issue #26: divergencia declarada em voz alta (tom da
    ///   issue #21). Alargamento portavel entre os dois compiladores fica
    ///   como issue propria — pre-requisito e uma matriz Kind x Kind medida
    ///   contra o dcc32.
    /// </remarks>
    function AsType<T>: T;
  end;

  /// <summary>
  ///   Token opaco que carrega o estado interno de `TModernRTTIContext`
  ///   (D-28.1 do ADR issue #28). Interface **vazia de membros publicos** —
  ///   so o GUID; o backend recupera o estado tipado via cast contra a
  ///   classe privada do proprio backend (`TDelphiContextToken` ou
  ///   `TFPCContextToken`). E o refcount da `IInterface` que agrega N
  ///   copias do record `TModernRTTIContext`: o ultimo decremento libera,
  ///   tornando use-after-free e double-free **impossiveis por
  ///   construcao**.
  /// </summary>
  /// <remarks>
  ///   Frase-fronteira (D-28.2): *"`Pointer` em record e seguro enquanto
  ///   o record nao e dono; vira bomba no instante em que passa a ser."*
  ///   `TModernRTTIContext` e o primeiro record publico desta camada que
  ///   possui heap por instancia — por isso usa `IInterface` em vez de
  ///   `Pointer`.
  /// </remarks>
  IModernRTTIContextToken = interface
    ['{9D4E0C7C-2F0D-4E0A-9C7A-2D5F1A028E13}']
  end;

  /// <summary>
  ///   Contexto RTTI portavel: `Create/Free/GetType/GetTypes/FindType`
  ///   funcionam nos dois compiladores sem `{$IFDEF FPC}` no consumidor.
  ///   O estado vive atras de `IModernRTTIContextToken` opaco (refcount
  ///   agrega copias do record; o ultimo decremento libera).
  /// </summary>
  /// <remarks>
  ///   **`GetPackages` nao existe** nesta superficie. O conceito de
  ///   "pacote" e do Delphi (`TRttiContext.GetPackages` +
  ///   `TRttiPackage`); no FPC 3.2.2 nao ha primitiva equivalente. Se um
  ///   dia fizer falta, entra em issue propria com o desenho de como
  ///   representar "pacote" no FPC — precedente:
  ///   `TModernRTTIMethod.GetParameters` fora do FPC pela mesma razao.
  ///
  ///   Semantica de copia: como o campo interno e `IInterface`, `B := A`
  ///   compartilha estado — `A.RegisterType(T)` fica visivel em
  ///   `B.GetTypes`. Este e o desenho, nao um bug (D-28.10 do ADR).
  /// </remarks>
  TModernRTTIContext = record
  private
    FToken: IModernRTTIContextToken;
  public
    /// <summary>
    ///   Cria um contexto novo (registry vazio no FPC; `TRttiContext`
    ///   nativo per-instancia no Delphi).
    /// </summary>
    class function Create: TModernRTTIContext; static;
    /// <summary>
    ///   Libera o token deste record (`FToken := nil`).
    ///   **Opcional** — existe por paridade com `TRttiContext.Free` do
    ///   Delphi. O refcount da `IInterface` libera automaticamente
    ///   quando o ultimo record que segura o token sai de escopo. Chamar
    ///   `Free` num record cuja copia ainda vive nao levanta e nao
    ///   invalida a outra copia — o estado permanece enquanto qualquer
    ///   copia segurar o token (D-28.10 do ADR).
    /// </summary>
    procedure Free;
    /// <summary>
    ///   Devolve o handle de tipo para `AClass` (sem alimentar o
    ///   registry no FPC — use `RegisterType` para isso).
    /// </summary>
    function GetType(AClass: TClass): TModernRTTIType; overload;
    /// <summary>
    ///   Devolve o handle de tipo para `ATypeInfo`. No FPC, alimenta o
    ///   registry per-instancia (para que este tipo entre depois em
    ///   `GetTypes`/`FindType`); no Delphi delega ao contexto nativo.
    /// </summary>
    function GetType(ATypeInfo: PTypeInfo): TModernRTTIType; overload;
    /// <summary>
    ///   No FPC alimenta o registry per-instancia — passa a fazer
    ///   `GetTypes`/`FindType` alcancarem este `ATypeInfo`. **No Delphi
    ///   e no-op**: delega ao `GetType(ATypeInfo)` nativo. Existe para
    ///   que o codigo portavel seja identico nos dois compiladores.
    /// </summary>
    function RegisterType(ATypeInfo: PTypeInfo): TModernRTTIType;
    /// <summary>
    ///   Enumera os tipos conhecidos por este contexto.
    /// </summary>
    /// <remarks>
    ///   Divergencia de conteudo declarada em voz alta:
    ///   no Delphi enumera o **pool nativo** do `TRttiContext`
    ///   (`TRttiContext.GetTypes`); no FPC enumera o registry
    ///   **per-instancia** alimentado por `GetType`/`RegisterType`.
    ///
    ///   **NO FPC, registry vazio LEVANTA `EModernRTTIError`** com
    ///   mensagem instrutiva (`SModernRTTIError_EmptyRegistry`) — o
    ///   nome `GetTypes` promete "todos os tipos"; array vazio silencioso
    ///   seria indistinguivel de "esqueci de registrar". D-26 do ADR do
    ///   ciclo 011 (nao silenciar divergencia).
    /// </remarks>
    function GetTypes: TArray<TModernRTTIType>;
    /// <summary>
    ///   Localiza um tipo por nome qualificado (`UnitName.TypeName`).
    ///   Nao encontrado devolve `TModernRTTIType` com `IsNil = True`
    ///   (nunca levanta por miss — `nil` aqui e resposta legitima).
    /// </summary>
    /// <remarks>
    ///   **No FPC so resolve `tkClass`**: enumeracoes, records e
    ///   escalares registrados sao inalcancaveis por nome — a leitura
    ///   de `UnitName` fora de `tkClass` acessa campo inexistente
    ///   naquele layout de `TTypeData` (lixo ou AV sem erro de
    ///   compilacao). No Delphi delega ao `TRttiContext.FindType`
    ///   nativo, que cobre todos os kinds.
    /// </remarks>
    function FindType(const AQualifiedName: string): TModernRTTIType;
  end;

  /// <summary>
  ///   Handle publico proprio para o tipo de categoria **Enumeration** na
  ///   casca de RTTI (issue #43 — parent #29). Substitui `TRttiEnumerationType`
  ///   do RTL de cada compilador na superficie desta unit. O consumidor
  ///   obtem uma instancia via `TModernRTTIEnumerationType.FromTypeInfo(
  ///   TypeInfo(TMeuEnum))`.
  /// </summary>
  /// <remarks>
  ///   Estado interno (D-43.1 do ADR issue #43): `FToken: PTypeInfo` —
  ///   handle neutro, o mesmo nome nos dois backends. A fabrica
  ///   `FromTypeInfo` **nao** valida `Kind`: exigiria `resourcestring` na
  ///   unit publica, violando D-1. A guarda por `Kind` mora em CADA um dos
  ///   seis metodos (D-4/D-43.2) e usa `resourcestring` dos backends.
  ///
  ///   Contrato de erros identico nos dois compiladores por construcao
  ///   (D-2/D-43.6): o backend Delphi espelha os guards de M-1 (faixa em
  ///   `GetName`) e M-2 (raise em `GetValue` quando `-1`) antes de delegar
  ///   a `TRttiEnumerationType`.
  ///
  ///   Enums com valores explicitos (ex.: `TCod = (kX=5, kY=6)`) ficam
  ///   FORA — FPC 3.2.2 recusa `TypeInfo(TCod)` (M-3). Se um dia isso
  ///   mudar, o laco `MinValue..MaxValue` de `EnumGetNames` reintroduz
  ///   risco de indices fantasma; o ADR desta issue e o alarme.
  /// </remarks>
  TModernRTTIEnumerationType = record
  strict private
    FToken: PTypeInfo;
  public
    /// <summary>
    ///   Constroi um handle a partir do `PTypeInfo` do enum. **Nao valida
    ///   `Kind`** (D-43.1): a validacao mora em cada metodo abaixo (D-4).
    /// </summary>
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType; static;
    /// <summary>
    ///   Nome do tipo enum (ex.: `'TDia'`).
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
    ///   de `tkEnumeration` (ou e `nil`).
    /// </remarks>
    function Name: string;
    /// <summary>
    ///   Ordinal do primeiro valor do enum (ex.: 0 para `TDia`).
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
    ///   de `tkEnumeration`.
    /// </remarks>
    function MinValue: Integer;
    /// <summary>
    ///   Ordinal do ultimo valor do enum (ex.: 6 para `TDia`).
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
    ///   de `tkEnumeration`.
    /// </remarks>
    function MaxValue: Integer;
    /// <summary>
    ///   Nome do valor do enum de ordinal `AOrdinal`.
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando `AOrdinal < MinValue` ou
    ///   `AOrdinal > MaxValue` (D-43.3, M-1: `TypInfo.GetEnumName(P, -1)`
    ///   no FPC 3.2.2 devolve o primeiro nome silenciosamente). Tambem
    ///   levanta se o `FToken` tem `Kind` diferente de `tkEnumeration`.
    /// </remarks>
    function GetName(AOrdinal: Integer): string;
    /// <summary>
    ///   Ordinal do valor do enum cujo nome e `AName`.
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o nome nao existe (D-43.4, M-2:
    ///   `TypInfo.GetEnumValue` devolve `-1` — sentinela indistinguivel
    ///   de resposta legitima em enums que pudessem ter ordinais
    ///   negativos). Tambem levanta se o `FToken` tem `Kind` diferente de
    ///   `tkEnumeration`.
    /// </remarks>
    function GetValue(const AName: string): Integer;
    /// <summary>
    ///   Nomes de todos os valores do enum, de `MinValue` a `MaxValue`,
    ///   em ordem.
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
    ///   de `tkEnumeration`. Nao levanta por outra razao.
    /// </remarks>
    function GetNames: TArray<string>;
  end;

  /// <summary>
  ///   Handle leve para um `TypeInfo` de `Kind = tkPointer` (issue #44).
  /// </summary>
  /// <remarks>
  ///   Padrao consagrado da familia (`TModernRTTIEnumerationType` da issue
  ///   #43): `strict private FToken: PTypeInfo`, `FromTypeInfo` sem
  ///   guarda de `Kind` (D-1 / D-44.1 — a guarda vive nos backends via
  ///   D-4), `ReferredType` publico que delega ao backend selecionado
  ///   pelo unico `{$IFDEF}` da unit.
  /// </remarks>
  TModernRTTIPointerType = record
  strict private
    FToken: PTypeInfo;
  public
    /// <summary>
    ///   Constroi o handle a partir de `PTypeInfo`. Nao valida `Kind`
    ///   (D-44.1): a fabrica na unit publica nao pode carregar
    ///   `resourcestring` (D-1). A guarda por `Kind` vive em cada
    ///   metodo, via backend.
    /// </summary>
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIPointerType; static;
    /// <summary>
    ///   Devolve o `TModernRTTIType` do tipo apontado (o "referred" de
    ///   um `^T`). Para `PTypeInfo` de `Pointer` puro (sem tipo
    ///   apontado) devolve um `TModernRTTIType` com `IsNil = True` sem
    ///   levantar (B-44.1).
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind`
    ///   diferente de `tkPointer` (D-4).
    ///
    ///   Divergencia cross-compiler de `Name` (B-44.2): Delphi diz
    ///   `Integer`, FPC diz `LongInt`. Consumidor que afirmar sobre
    ///   `Name` deve indireta pela RTL local, ex.:
    ///   `TModernRTTI.GetType(TypeInfo(Integer)).Name`. Esta camada
    ///   **nao normaliza** — a RTL de cada compilador manda.
    /// </remarks>
    function ReferredType: TModernRTTIType;
  end;

  /// <summary>
  ///   Handle leve para um `TypeInfo` de `Kind = tkRecord` (issue #45).
  ///   Esta entrega cobre `Name` e `Size` apenas; `GetFields` fica para
  ///   issue propria condicionada a medir `TRecordElement.Name` num FPC
  ///   vivo.
  /// </summary>
  /// <remarks>
  ///   Padrao consagrado da familia (`TModernRTTIEnumerationType` da issue
  ///   #43, `TModernRTTIPointerType` da issue #44): `strict private
  ///   FToken: PTypeInfo`, `FromTypeInfo` sem guarda de `Kind` (D-1 /
  ///   D-45.1 — a guarda vive nos backends via D-4), `Name` e `Size`
  ///   publicos que delegam ao backend selecionado pelo unico `{$IFDEF}`
  ///   da unit.
  ///
  ///   `record end` (record vazio) e valido nos seis alvos e tem
  ///   `Size = 0` (D-45.8) — nenhuma guarda rejeita por `Size`.
  /// </remarks>
  TModernRTTIRecordType = record
  strict private
    FToken: PTypeInfo;
  public
    /// <summary>
    ///   Constroi o handle a partir de `PTypeInfo`. Nao valida `Kind`
    ///   (D-45.1): a fabrica na unit publica nao pode carregar
    ///   `resourcestring` (D-1). A guarda por `Kind` vive em cada metodo,
    ///   via backend.
    /// </summary>
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType; static;
    /// <summary>
    ///   Nome do tipo record como aparece na fonte (ex.:
    ///   `TRecordFixture45`).
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
    ///   de `tkRecord` (D-4). No Delphi delega a `TRttiRecordType.Name`
    ///   (cobre o caso generico/aninhado); no FPC 3.2.2 le `P^.Name` direto
    ///   (mesmo observavel medido nos alvos).
    /// </remarks>
    function Name: string;
    /// <summary>
    ///   `GetTypeData^.RecSize` — tamanho em bytes do layout do record.
    ///   `record end` (record vazio) e valido e tem `Size = 0`.
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` quando o `FToken` tem `Kind` diferente
    ///   de `tkRecord` (D-4). Paridade objetiva entre os dois backends:
    ///   ambos usam `GetTypeData(P)^.RecSize` (D-45.3 / D-45.6).
    /// </remarks>
    function Size: Integer;
  end;

  /// <summary>
  ///   Categoria RTTI para <c>tkArray</c> e <c>tkDynArray</c> (issue #46).
  ///   Ramifica publicamente por <see cref="IsDynamic"/>.
  /// </summary>
  /// <remarks>
  ///   Padrao consagrado da familia (`TModernRTTIRecordType` da issue #45,
  ///   `TModernRTTIPointerType` da issue #44): `strict private FToken:
  ///   PTypeInfo`, `FromTypeInfo` sem guarda de `Kind` (D-1 / D-46.1). A
  ///   guarda vive nos backends via D-4 (helper `ArrayRaiseWrongKind` com
  ///   guarda combinada [tkArray, tkDynArray] — drift D-46.4).
  ///
  ///   <see cref="Length"/> levanta <see cref="EModernRTTIError"/>
  ///   (<c>SArrayDynamicLength</c>) quando o array e dinamico — em ambos
  ///   os compiladores (paridade semantica, D-46.2). Use
  ///   <c>System.Length(arr)</c> em runtime para contar instancias.
  /// </remarks>
  TModernRTTIArrayType = record
  strict private
    FToken: PTypeInfo;
  public
    /// <summary>
    ///   Constroi o handle a partir de `PTypeInfo`. Nao valida `Kind`
    ///   (D-46.1): a fabrica na unit publica nao pode carregar
    ///   `resourcestring` (D-1). A guarda por `Kind` vive em cada metodo,
    ///   via backend.
    /// </summary>
    class function FromTypeInfo(P: PTypeInfo): TModernRTTIArrayType; static;
    /// <summary>
    ///   `True` se e so se o `PTypeInfo` descreve um `tkDynArray`; `False`
    ///   para `tkArray` (estatico). Levanta `EModernRTTIError` para
    ///   qualquer outro `Kind` (D-4/D-46.4).
    /// </summary>
    function IsDynamic: Boolean;
    /// <summary>
    ///   Handle para o tipo do elemento. No dinamico usa a property
    ///   `elType2` (FPC) / `TRttiDynamicArrayType.ElementType` (Delphi);
    ///   no estatico usa a property `ArrayData.ElType` (FPC) /
    ///   `TRttiArrayType.ElementType` (Delphi). Nunca os campos crus
    ///   `elType2Ref`, `elTypeRef` (D-46.5).
    /// </summary>
    function ElementType: TModernRTTIType;
    /// <summary>
    ///   Tamanho em bytes. No estatico devolve
    ///   `GetTypeData^.ArrayData.Size` (paridade objetiva entre backends).
    ///   No dinamico devolve `GetTypeData^.elSize` (tamanho do elemento).
    /// </summary>
    function Size: Integer;
    /// <summary>
    ///   Numero de elementos no array estatico (produto de todos os graus
    ///   para multidimensional, medido — equivale a
    ///   `TotalElementCount`).
    /// </summary>
    /// <remarks>
    ///   Levanta `EModernRTTIError` (`SArrayDynamicLength`) quando o array
    ///   e dinamico — em ambos os compiladores (paridade semantica,
    ///   D-46.2). RTTI de tipo nao carrega contagem de instancia; use
    ///   `System.Length(arr)` em runtime para arrays dinamicos.
    /// </remarks>
    function Length: Integer;
  end;

  /// <summary>
  ///   Categoria RTTI para <c>tkSet</c> (issue #46).
  /// </summary>
  /// <remarks>
  ///   Padrao consagrado da familia: `strict private FToken: PTypeInfo`,
  ///   `FromTypeInfo` sem guarda (D-1 / D-46.1). A guarda por `tkSet` vive
  ///   no backend via helper `SetRaiseWrongKind` (D-4).
  /// </remarks>
  TModernRTTISetType = record
  strict private
    FToken: PTypeInfo;
  public
    /// <summary>
    ///   Constroi o handle a partir de `PTypeInfo`. Nao valida `Kind`
    ///   (D-46.1). A guarda por `Kind` vive no metodo, via backend.
    /// </summary>
    class function FromTypeInfo(P: PTypeInfo): TModernRTTISetType; static;
    /// <summary>
    ///   Handle para o tipo do elemento do set. No FPC usa a property
    ///   `CompType` (nunca o campo cru `CompTypeRef` — D-46.5); no Delphi
    ///   delega a `TRttiSetType.ElementType`.
    /// </summary>
    function ElementType: TModernRTTIType;
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
    /// <remarks>
    ///   NAO alimenta `TModernRTTIContext.GetTypes` de nenhuma instancia;
    ///   para enumeracao, use `TModernRTTIContext.RegisterType` ou
    ///   `TModernRTTIContext.GetType` — este `GetType` estatico opera
    ///   sobre o `TRttiContext` global (`FContext`), nao sobre o
    ///   registry per-instancia do backend FPC.
    /// </remarks>
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

{ TModernValue }

class function TModernValue.From<T>(const AValue: T): TModernValue;
begin
  Result.FValue := TValue.From<T>(AValue);
end;

class function TModernValue.FromValue(const AValue: TValue): TModernValue;
begin
  Result.FValue := AValue;
end;

function TModernValue.AsType<T>: T;
begin
  // D-2 do ADR issue #26: uma linha, zero {$IFDEF}. O dispatch entre
  // backends e feito pelo {$IFDEF FPC} da uses da implementation acima —
  // TValueOps e homonimo em cada backend.
  Result := TValueOps.AsType<T>(FValue);
end;

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
begin
  // D-7 do ADR issue #26: fecha o unico drift do §7 do API-MAP na unit
  // publica. O bloco {$IFDEF FPC}...{$ELSE}...{$ENDIF} anterior desapareceu
  // — a divergencia real (tipo exato no FPC, alargamento nativo no Delphi)
  // vive dentro do TValueOps de cada backend. TModernRTTIField.GetValue<T>
  // NAO e tocado (fora de escopo — usa mecanismo diferente, sem TValue no
  // Delphi via FieldReadRaw). Consequencia media no FPC: se o tipo diferir,
  // a mensagem passa a ser "incompativel: origem=... destino=..." em vez
  // de "tamanho incompativel" — todos os tres roundtrips existentes
  // (Integer/String/Currency) leem no mesmo tipo que escrevem e continuam
  // verdes.
  Result := TModernValue.FromValue(FProp.GetValue(AInstance)).AsType<T>;
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

function TModernRTTIProperty.Visibility: TModernVisibility;
begin
  // Delega ao backend. Nos DOIS compiladores devolve dado real via
  // `case` explicito de 4 ramos sobre `TRttiProperty(AToken).Visibility`
  // (D-42.2 do ADR issue #42). `FProp` esta em `strict private` mas visivel
  // na `implementation` da mesma unit — passamos como `Pointer(FProp)`
  // para casar com a assinatura crua dos backends.
  Result := PropertyVisibility(Pointer(FProp));
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

function TModernRTTIType.IsNil: Boolean;
begin
  Result := FType = nil;
end;

function TModernRTTIType.Name: string;
begin
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Name']);
  Result := FType.Name;
end;

function TModernRTTIType.GetProperties: TArray<TModernRTTIProperty>;
var
  LProps: TArray<TRttiProperty>;
  LTypeData: PTypeData;
  LIdx: Integer;
  LHasPublishedProps: Boolean;
begin
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetProperties']);
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
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetFields']);
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
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetMethods']);
  if not (FType is TRttiInstanceType) then
    raise EModernRTTIError.CreateFmt(SModernRTTIGetMethodsNotClass, [FType.Name]);
  Result := MethodEnumerate(TRttiInstanceType(FType).MetaclassType);
end;

function TModernRTTITypeHelper.GetMethod(const AName: string): TModernRTTIMethod;
begin
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['GetMethod']);
  if not (FType is TRttiInstanceType) then
    raise EModernRTTIError.CreateFmt(SModernRTTIGetMethodNotClass, [FType.Name]);
  if not MethodLookup(TRttiInstanceType(FType).MetaclassType, AName, Result) then
    raise EModernRTTIError.CreateFmt(SModernRTTIMethodNotFound, [AName, FType.Name]);
end;

function TModernRTTITypeHelper.PropFields: TArray<TModernRTTIField>;
begin
  // Forwarder trivial — a logica real (e o guard `is TRttiInstanceType`)
  // vive em TModernRTTIType.GetFields. Ver comentario da declaracao dos
  // forwarders (strict private) sobre o porque de nao usar `read GetFields`
  // direto no FPC 3.2.2.
  Result := Self.GetFields;
end;

function TModernRTTITypeHelper.PropProperties: TArray<TModernRTTIProperty>;
begin
  Result := Self.GetProperties;
end;

function TModernRTTITypeHelper.PropAttributes: TArray<TObject>;
begin
  if FType = nil then
    raise EModernRTTIError.CreateFmt(SModernRTTINilHandle, ['Attributes']);
  // Issue #27: alias para a coleção ja existente do Pilar 2. Delega direto
  // — a fusao nativa+registrada (Delphi) e a copia de `Owned` (FPC) vivem
  // dentro de `ModernAttributes.GetAttributes`. Nenhum estado novo aqui.
  if (FType is TRttiInstanceType) then
    Result := ModernAttributes.GetAttributes(TRttiInstanceType(FType).MetaclassType)
  else
    Result := nil;
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

function TModernRTTIMethod.Visibility: TModernVisibility;
begin
  Result := MethodVisibility(FOwner, FToken);
end;

{ TModernRTTIContext }

class function TModernRTTIContext.Create: TModernRTTIContext;
begin
  // Delega a funcao livre do backend selecionado — a instanciacao real
  // (`TDelphiContextToken`/`TFPCContextToken`) e paridade estrita entre
  // as duas units (API-MAP §7). O refcount da IInterface aloca ao criar
  // e libera quando o ultimo record que segura FToken sai de escopo.
  Result.FToken := ContextCreate;
end;

procedure TModernRTTIContext.Free;
begin
  // D-28.6: opcional, existe por paridade com TRttiContext.Free do Delphi.
  // O ultimo decremento do refcount libera; chamar aqui apenas antecipa
  // esta contagem sobre esta copia particular do record.
  FToken := nil;
end;

function TModernRTTIContext.GetType(AClass: TClass): TModernRTTIType;
begin
  Result := ContextGetType(FToken, AClass.ClassInfo);
end;

function TModernRTTIContext.GetType(ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  Result := ContextGetType(FToken, ATypeInfo);
end;

function TModernRTTIContext.RegisterType(ATypeInfo: PTypeInfo): TModernRTTIType;
begin
  Result := ContextRegisterType(FToken, ATypeInfo);
end;

function TModernRTTIContext.GetTypes: TArray<TModernRTTIType>;
begin
  Result := ContextGetTypes(FToken);
end;

function TModernRTTIContext.FindType(const AQualifiedName: string): TModernRTTIType;
begin
  Result := ContextFindType(FToken, AQualifiedName);
end;

{ TModernRTTIEnumerationType }

class function TModernRTTIEnumerationType.FromTypeInfo(P: PTypeInfo): TModernRTTIEnumerationType;
begin
  // D-43.1 do ADR: fabrica NAO valida Kind — a guarda mora em cada metodo
  // (D-4). Validar aqui obrigaria resourcestring nesta unit publica,
  // violando D-1 (o motivo real; nao "economia").
  Result.FToken := P;
end;

function TModernRTTIEnumerationType.Name: string;
begin
  Result := EnumName(FToken);
end;

function TModernRTTIEnumerationType.MinValue: Integer;
begin
  Result := EnumMinValue(FToken);
end;

function TModernRTTIEnumerationType.MaxValue: Integer;
begin
  Result := EnumMaxValue(FToken);
end;

function TModernRTTIEnumerationType.GetName(AOrdinal: Integer): string;
begin
  Result := EnumGetName(FToken, AOrdinal);
end;

function TModernRTTIEnumerationType.GetValue(const AName: string): Integer;
begin
  Result := EnumGetValue(FToken, AName);
end;

function TModernRTTIEnumerationType.GetNames: TArray<string>;
begin
  Result := EnumGetNames(FToken);
end;

{ TModernRTTIPointerType }

class function TModernRTTIPointerType.FromTypeInfo(P: PTypeInfo): TModernRTTIPointerType;
begin
  // D-44.1 do ADR: fabrica NAO valida Kind — a guarda mora no metodo
  // (D-4), no backend. Validar aqui obrigaria resourcestring nesta unit
  // publica, violando D-1. Mesmo padrao de TModernRTTIEnumerationType.
  Result.FToken := P;
end;

function TModernRTTIPointerType.ReferredType: TModernRTTIType;
begin
  Result := PointerTypeReferredType(FToken);
end;

{ TModernRTTIRecordType }

class function TModernRTTIRecordType.FromTypeInfo(P: PTypeInfo): TModernRTTIRecordType;
begin
  // D-45.1 do ADR: fabrica NAO valida Kind — a guarda mora em cada metodo
  // (D-4), no backend. Validar aqui obrigaria resourcestring nesta unit
  // publica, violando D-1. Mesmo padrao de TModernRTTIEnumerationType e
  // TModernRTTIPointerType.
  Result.FToken := P;
end;

function TModernRTTIRecordType.Name: string;
begin
  Result := RecordTypeName(FToken);
end;

function TModernRTTIRecordType.Size: Integer;
begin
  Result := RecordTypeSize(FToken);
end;

{ TModernRTTIArrayType }

class function TModernRTTIArrayType.FromTypeInfo(P: PTypeInfo): TModernRTTIArrayType;
begin
  // D-46.1 do ADR: fabrica NAO valida Kind — a guarda mora em cada metodo
  // (D-4), no backend. Validar aqui obrigaria resourcestring nesta unit
  // publica, violando D-1. Mesmo padrao de TModernRTTIRecordType.
  Result.FToken := P;
end;

function TModernRTTIArrayType.IsDynamic: Boolean;
begin
  Result := ArrayTypeIsDynamic(FToken);
end;

function TModernRTTIArrayType.ElementType: TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(TModernRTTI.FContext.GetType(
    ArrayTypeElementType(FToken)));
end;

function TModernRTTIArrayType.Size: Integer;
begin
  Result := ArrayTypeSize(FToken);
end;

function TModernRTTIArrayType.Length: Integer;
begin
  // B-46.2 / D-46.2: em dinamico o backend levanta EModernRTTIError com
  // SArrayDynamicLength (paridade semantica entre FPC e Delphi). A casca
  // aqui apenas delega — a excecao propaga naturalmente.
  Result := ArrayTypeLength(FToken);
end;

{ TModernRTTISetType }

class function TModernRTTISetType.FromTypeInfo(P: PTypeInfo): TModernRTTISetType;
begin
  // D-46.1: fabrica sem guarda (mesmo padrao dos outros records da
  // familia).
  Result.FToken := P;
end;

function TModernRTTISetType.ElementType: TModernRTTIType;
begin
  Result := TModernRTTIType.FromRtti(TModernRTTI.FContext.GetType(
    SetTypeElementType(FToken)));
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
