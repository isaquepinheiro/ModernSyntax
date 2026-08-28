(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
  ModernSyntax.Callback

  Fundacao transversal de callbacks portaveis entre Delphi XE+ e FPC 3.2.2.
  Tres interfaces de contrato (IModernFunc, IModernProc, IModernPredicate)
  sem GUID, e um factory Callback com o metodo "&Of" sobrecarregado para
  "method of object" nos tres formatos.

  NOTA sobre o nome do metodo do factory. A ESP/ADR/task-input escrevem
  "Callback.Of". Em Pascal, "of" e palavra reservada (case-insensitive)
  em Delphi e em FPC 3.2.2 — a declaracao "class function Of(...)" nao
  compila. A forma valida do MESMO identificador e a fuga com "&":
    Callback.&Of(Self.MinhaProc)
  Tanto Delphi quanto FPC aceitam "&Of" e o simbolo se chama "Of". O
  consumidor precisa escrever o "&" na chamada. Nao ha alternativa que
  preserve o nome "Of" sem quebrar a linguagem; renomear para "OfMethod"
  ou "From" seria decisao de design nao coberta pelo ADR (D-A3 falou
  literalmente "Of"). Reportado no implement-report.md.

  Ramificacao IFDEF FPC vai DIRETO neste arquivo. A unit NAO inclui
  ModernSyntax.inc (contorna o bug de digitacao invertida na linha 256
  do .inc, descrito no ADR D-A5).

  As classes wrapper TFuncOfObjectWrapper, TProcOfObjectWrapper e
  TPredicateOfObjectWrapper ficam declaradas na secao "interface" por
  exigencia do FPC 3.2.2: o compilador expande o template generico no
  ponto de uso do factory (declarado na "interface"), onde simbolos da
  secao "implementation" nao sao visiveis (erro medido:
    "Global Generic template references static symtable"
  ). O consumidor nao instancia os wrappers diretamente; o unico ponto
  de entrada e Callback.&Of, que devolve a interface.
  ------------------------------------------------------------------------------
*)

{$IFDEF FPC}
  {$MODE DELPHI}
  {$MODESWITCH ADVANCEDRECORDS}
{$ENDIF}

unit ModernSyntax.Callback;

interface

uses
  SysUtils;

type
  { Contratos de chamada — SEM GUID (D-A2 do ADR).
    Nao ha Supports/QueryInterface no caminho de uso. O consumidor
    declara o tipo exato (IModernFunc<Integer,String>) e chama Invoke. }

  IModernFunc<T, R> = interface
    function Invoke(const AValue: T): R;
  end;

  IModernProc<T> = interface
    procedure Invoke(const AValue: T);
  end;

  IModernPredicate<T> = interface
    function Invoke(const AValue: T): Boolean;
  end;

  { Aliases para os tres sabores de "method of object" aceitos pelo
    factory. Declarados no nivel da unit porque tipos-alias genericos
    NAO podem morar dentro de um record. }

  TFuncOfObject<T, R> = function(const AValue: T): R of object;
  TProcOfObject<T> = procedure(const AValue: T) of object;
  TPredicateOfObject<T> = function(const AValue: T): Boolean of object;

  { Factory de callbacks — record de metodos de classe.
    Neste ciclo, apenas sobrecargas de "method of object". Sobrecarga
    aceitando TFunc<T,R> foi recusada (D-A6 do ADR): criaria API que
    parece portavel e nao e (FPC 3.2.2 nao tem "reference to").

    O identificador do metodo e escrito com fuga "&" porque "of" e
    palavra reservada em Pascal. O NOME do simbolo e "Of"; o consumidor
    tambem chama com "&Of". }

  Callback = record
  public
    class function &Of<T, R>(const AMethod: TFuncOfObject<T, R>): IModernFunc<T, R>; overload; static;
    class function &Of<T>(const AMethod: TProcOfObject<T>): IModernProc<T>; overload; static;
    class function &Of<T>(const AMethod: TPredicateOfObject<T>): IModernPredicate<T>; overload; static;
  end;

  { Wrapper: adapta "function of object" ao contrato IModernFunc<T,R>.
    Declarado na "interface" por exigencia do FPC 3.2.2 (D-A13 do ADR). }

  TFuncOfObjectWrapper<T, R> = class(TInterfacedObject, IModernFunc<T, R>)
  private
    FMethod: TFuncOfObject<T, R>;
  public
    constructor Create(const AMethod: TFuncOfObject<T, R>);
    function Invoke(const AValue: T): R;
  end;

  { Wrapper: adapta "procedure of object" ao contrato IModernProc<T>.
    Declarado na "interface" por exigencia do FPC 3.2.2 (D-A13 do ADR). }

  TProcOfObjectWrapper<T> = class(TInterfacedObject, IModernProc<T>)
  private
    FMethod: TProcOfObject<T>;
  public
    constructor Create(const AMethod: TProcOfObject<T>);
    procedure Invoke(const AValue: T);
  end;

  { Wrapper: adapta "function of object" que retorna Boolean ao contrato
    IModernPredicate<T>. Declarado na "interface" por exigencia do FPC
    3.2.2 (D-A13 do ADR). }

  TPredicateOfObjectWrapper<T> = class(TInterfacedObject, IModernPredicate<T>)
  private
    FMethod: TPredicateOfObject<T>;
  public
    constructor Create(const AMethod: TPredicateOfObject<T>);
    function Invoke(const AValue: T): Boolean;
  end;

implementation

{ TFuncOfObjectWrapper<T, R> }

constructor TFuncOfObjectWrapper<T, R>.Create(const AMethod: TFuncOfObject<T, R>);
begin
  inherited Create;
  FMethod := AMethod;
end;

function TFuncOfObjectWrapper<T, R>.Invoke(const AValue: T): R;
begin
  Result := FMethod(AValue);
end;

{ TProcOfObjectWrapper<T> }

constructor TProcOfObjectWrapper<T>.Create(const AMethod: TProcOfObject<T>);
begin
  inherited Create;
  FMethod := AMethod;
end;

procedure TProcOfObjectWrapper<T>.Invoke(const AValue: T);
begin
  FMethod(AValue);
end;

{ TPredicateOfObjectWrapper<T> }

constructor TPredicateOfObjectWrapper<T>.Create(const AMethod: TPredicateOfObject<T>);
begin
  inherited Create;
  FMethod := AMethod;
end;

function TPredicateOfObjectWrapper<T>.Invoke(const AValue: T): Boolean;
begin
  Result := FMethod(AValue);
end;

{ Callback }

class function Callback.&Of<T, R>(const AMethod: TFuncOfObject<T, R>): IModernFunc<T, R>;
begin
  Result := TFuncOfObjectWrapper<T, R>.Create(AMethod);
end;

class function Callback.&Of<T>(const AMethod: TProcOfObject<T>): IModernProc<T>;
begin
  Result := TProcOfObjectWrapper<T>.Create(AMethod);
end;

class function Callback.&Of<T>(const AMethod: TPredicateOfObject<T>): IModernPredicate<T>;
begin
  Result := TPredicateOfObjectWrapper<T>.Create(AMethod);
end;

end.
