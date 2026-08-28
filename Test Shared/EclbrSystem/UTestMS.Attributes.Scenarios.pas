(*
  ------------------------------------------------------------------------------
  ModernSyntax — Test scenarios for ModernSyntax.Attributes.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Cenarios compartilhados entre as cascas Delphi (DUnitX) e FPC (FPCUnit).
  Sem framework de teste. Sem `{$IFDEF}`. A excecao e o contrato — cada
  cenario levanta ETestScenarioFailed na falha.

  Ver `.project/pipeline/esp.md` (RN-1..RN-10, CA-*).
  ------------------------------------------------------------------------------
*)

unit UTestMS.Attributes.Scenarios;

// Nota: nenhuma diretiva {$MODE ...} aqui. O modo Delphi para esta unit
// quando compilada pelo FPC vem do projeto (.lpi) via
// <SyntaxMode Value="Delphi"/>. Ver cycle-003 DEV-6.

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  ModernSyntax.Attributes;

type
  ETestScenarioFailed = class(Exception);

  TMyAttr = class(TModernAttribute)
  private
    FTag: string;
  public
    constructor Create(const ATag: string);
    property Tag: string read FTag;
  end;

  TOtherAttr = class(TModernAttribute);

  // Classes-alvo dos cenarios portaveis. Nenhuma leva anotacao nativa
  // no lado shared (a anotacao nativa vive na casca Delphi, dentro de
  // {$IFDEF HAS_NATIVE_ATTRS}).
  TAlvoBase = class(TObject);
  TAlvoDoRegister = class(TAlvoBase);
  TAlvoNuncaRegistrada = class(TAlvoBase);
  TAlvoDedup = class(TAlvoBase);
  TAlvoDuas = class(TAlvoBase);
  TAlvoNativePlusRegister = class(TAlvoBase);

// Cenarios compartilhados.
procedure Scenario_Register_ThenGetAttributes_ReturnsRegistered;
procedure Scenario_GetAttributes_NeverRegistered_ReturnsEmpty;
procedure Scenario_Register_SameInstanceTwice_IsDeduplicated;
procedure Scenario_Register_TwoInstances_BothAppear;
procedure Scenario_NativePlusRegister_IsIdentical;

implementation

{ TMyAttr }

constructor TMyAttr.Create(const ATag: string);
begin
  inherited Create;
  FTag := ATag;
end;

{ Helpers de asserção — a excecao e o contrato. }

procedure Fail(const AMsg: string);
begin
  raise ETestScenarioFailed.Create(AMsg);
end;

procedure AssertTrue(const ACondition: Boolean; const AMsg: string);
begin
  if not ACondition then
    Fail(AMsg);
end;

procedure AssertEqualsInt(const AExpected, AActual: Integer; const AMsg: string);
begin
  if AExpected <> AActual then
    Fail(Format('%s: expected %d, got %d', [AMsg, AExpected, AActual]));
end;

procedure AssertEqualsStr(const AExpected, AActual: string; const AMsg: string);
begin
  if AExpected <> AActual then
    Fail(Format('%s: expected "%s", got "%s"', [AMsg, AExpected, AActual]));
end;

{ Cenarios }

procedure Scenario_Register_ThenGetAttributes_ReturnsRegistered;
var
  LResult: TArray<TObject>;
begin
  ModernAttributes.Register(TAlvoDoRegister, [TMyAttr.Create('a')]);
  LResult := ModernAttributes.GetAttributes(TAlvoDoRegister);
  AssertEqualsInt(1, Length(LResult), 'attribute count for TAlvoDoRegister');
  AssertTrue(LResult[0] is TMyAttr, 'attribute[0] is TMyAttr');
  AssertEqualsStr('a', TMyAttr(LResult[0]).Tag, 'attribute tag');
end;

procedure Scenario_GetAttributes_NeverRegistered_ReturnsEmpty;
var
  LResult: TArray<TObject>;
begin
  LResult := ModernAttributes.GetAttributes(TAlvoNuncaRegistrada);
  AssertEqualsInt(0, Length(LResult), 'never-registered returns empty');
end;

procedure Scenario_Register_SameInstanceTwice_IsDeduplicated;
var
  LAttr: TMyAttr;
  LResult: TArray<TObject>;
begin
  LAttr := TMyAttr.Create('x');
  ModernAttributes.Register(TAlvoDedup, [LAttr]);
  ModernAttributes.Register(TAlvoDedup, [LAttr]);
  LResult := ModernAttributes.GetAttributes(TAlvoDedup);
  AssertEqualsInt(1, Length(LResult), 'dedup by identity: same instance twice = one entry');
  AssertTrue(LResult[0] = LAttr, 'the only entry is the same instance');
end;

procedure Scenario_Register_TwoInstances_BothAppear;
var
  LResult: TArray<TObject>;
  LSeenA, LSeenB: Boolean;
  LIdx: Integer;
  LTag: string;
begin
  ModernAttributes.Register(TAlvoDuas, [TMyAttr.Create('a'), TMyAttr.Create('b')]);
  LResult := ModernAttributes.GetAttributes(TAlvoDuas);
  AssertEqualsInt(2, Length(LResult), 'two distinct instances = two entries');
  LSeenA := False;
  LSeenB := False;
  for LIdx := 0 to High(LResult) do
  begin
    AssertTrue(LResult[LIdx] is TMyAttr, 'entry is TMyAttr');
    LTag := TMyAttr(LResult[LIdx]).Tag;
    if LTag = 'a' then LSeenA := True;
    if LTag = 'b' then LSeenB := True;
  end;
  AssertTrue(LSeenA, 'tag "a" present');
  AssertTrue(LSeenB, 'tag "b" present');
end;

procedure Scenario_NativePlusRegister_IsIdentical;
var
  LResult: TArray<TObject>;
begin
  // "Prova viva de CA-2": a classe TAlvoNativePlusRegister nao leva
  // anotacao nativa (a anotacao real vive na casca Delphi). O cenario
  // portavel afirma o resultado do lado da chamada `Register`.
  //
  // No FPC: nao ha `[MyAttr]` nativo por definicao, entao o resultado
  // e 1 entrada TMyAttr('reg').
  // No Delphi: se a classe recebesse anotacao nativa, a regra 2 do
  // ADENDO descartaria a nativa em favor da registrada, resultando
  // igualmente em 1 entrada TMyAttr('reg'). Este cenario, portanto,
  // afirma o resultado *identico entre compiladores*.
  ModernAttributes.Register(TAlvoNativePlusRegister, [TMyAttr.Create('reg')]);
  LResult := ModernAttributes.GetAttributes(TAlvoNativePlusRegister);
  AssertEqualsInt(1, Length(LResult), 'native+register identical count');
  AssertTrue(LResult[0] is TMyAttr, 'entry is TMyAttr');
  AssertEqualsStr('reg', TMyAttr(LResult[0]).Tag, 'entry tag is "reg"');
end;

end.
