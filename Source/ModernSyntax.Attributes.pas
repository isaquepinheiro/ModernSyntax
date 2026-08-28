(*
  ------------------------------------------------------------------------------
  ModernSyntax
  Functional programming toolkit and modern syntax extension for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------

  ModernSyntax.Attributes — Pilar 2 do ModernRTTI: atributos portaveis.

  Fornece:
    - TModernAttribute: classe base *obrigatoria* para atributos portaveis
      (herda de TObject no FPC, de TCustomAttribute no Delphi). O consumidor
      escreve `TMyAttr = class(TModernAttribute)` identico nos dois
      compiladores.
    - TAttributeRecord: registro de instancias que a registry possui
      (publico na `interface` por R-FPC-Generic).
    - ModernAttributes: record fachada com `Register` e `GetAttributes`
      estaticos.

  Regras de fronteira (regra 2 do ADENDO da investigacao):
    - `[MyAttr]` nativo Delphi sozinho: retorna a instancia nativa.
    - `Register(TFoo, [TMyAttr.Create(...)])` sozinho: retorna a
      registrada nos dois compiladores.
    - Ambos simultaneos no Delphi: a *registrada prevalece por classe*
      (a instancia nativa cuja `ClassType` esta em `Owned` e descartada).

  Nao inclui `ModernSyntax.inc` (isola o bloco morto de tipo defeito
  medido em `ModernSyntax.inc:250-262`, R3 do PRD). Ramificacao por
  compilador via `{$IFDEF FPC}` direto.
  ------------------------------------------------------------------------------
*)

unit ModernSyntax.Attributes;

{$IFDEF FPC}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  SysUtils,
  Generics.Collections,
  SyncObjs
  {$IFNDEF FPC}
  , Rtti
  {$ENDIF};

type
  {$IFDEF FPC}
  TModernAttribute = class(TObject);
  {$ELSE}
  TModernAttribute = class(TCustomAttribute);
  {$ENDIF}

  /// <summary>
  ///   Registro interno de atributos por classe.
  /// </summary>
  /// <remarks>
  ///   Publico na `interface` por R-FPC-Generic: o `TDictionary` instancia
  ///   este tipo por metodo publico e o FPC 3.2.2 exige que o simbolo seja
  ///   visivel no ponto de instanciacao do template. Ver
  ///   `.project/pipeline/adr.md` (D-A9).
  /// </remarks>
  TAttributeRecord = record
    Owned: TArray<TObject>;
  end;

  /// <summary>
  ///   Fachada estatica para registrar e ler atributos portaveis.
  /// </summary>
  ModernAttributes = record
  public
    /// <summary>
    ///   Registra atributos para a classe indicada. Toma posse de cada
    ///   instancia em `AAttrs`; o consumidor NAO deve liberar.
    /// </summary>
    /// <remarks>
    ///   Append com dedup por *identidade de referencia*: a mesma instancia
    ///   registrada duas vezes conta uma; duas instancias distintas contam
    ///   duas. Se uma instancia recebida ja esta em `Owned` por identidade,
    ///   e a mesma referencia — nao ha o que liberar. Se a mesma referencia
    ///   e passada duas vezes no mesmo array (`[X, X]`), a segunda ocorrencia
    ///   e detectada pelo dedup e ignorada.
    /// </remarks>
    class procedure Register(AClass: TClass; const AAttrs: array of TObject); static;

    /// <summary>
    ///   Retorna os atributos aplicados a `AClass`.
    ///
    ///   O array retornado e uma vista emprestada. As instancias nao
    ///   pertencem ao chamador; nao libere. Elas sao gerenciadas pela
    ///   registry (para as registradas via `Register`) ou pelo
    ///   `TRttiContext` interno (para as vindas de `[MyAttr]` nativo).
    /// </summary>
    /// <remarks>
    ///   No FPC: copia de `Owned` ou array vazio (nunca `nil`, nunca
    ///   excecao).
    ///
    ///   No Delphi: `Owned` concatenado com `Native filtrado`. Uma instancia
    ///   vinda da RTTI nativa e *descartada* se `Owned` contem alguma cuja
    ///   `ClassType` seja igual — a registrada *prevalece por classe*
    ///   (regra 2 do ADENDO da investigacao). Ver `.project/pipeline/adr.md`
    ///   (D-A6).
    /// </remarks>
    class function GetAttributes(AClass: TClass): TArray<TObject>; static;
  end;

implementation

var
  FRegistry: TDictionary<TClass, TAttributeRecord>;
  FLock: TCriticalSection;
  {$IFNDEF FPC}
  FContext: TRttiContext;
  {$ENDIF}

class procedure ModernAttributes.Register(AClass: TClass; const AAttrs: array of TObject);
var
  LRecord: TAttributeRecord;
  LAttr: TObject;
  LIdx, LJ: Integer;
  LFound: Boolean;
begin
  FLock.Enter;
  try
    if not FRegistry.TryGetValue(AClass, LRecord) then
      LRecord.Owned := nil;

    // Append com dedup por identidade de referencia.
    // Se a mesma instancia ja esta em Owned, e a mesma referencia — nao ha
    // duplicata a liberar. Ver adr.md D-A5.
    for LIdx := Low(AAttrs) to High(AAttrs) do
    begin
      LAttr := AAttrs[LIdx];
      if LAttr = nil then
        Continue;
      LFound := False;
      for LJ := 0 to High(LRecord.Owned) do
        if LRecord.Owned[LJ] = LAttr then
        begin
          LFound := True;
          Break;
        end;
      if not LFound then
      begin
        SetLength(LRecord.Owned, Length(LRecord.Owned) + 1);
        LRecord.Owned[High(LRecord.Owned)] := LAttr;
      end;
    end;

    FRegistry.AddOrSetValue(AClass, LRecord);
  finally
    FLock.Leave;
  end;
end;

class function ModernAttributes.GetAttributes(AClass: TClass): TArray<TObject>;
var
  LRecord: TAttributeRecord;
  LOwnedLen: Integer;
  LIdx: Integer;
  {$IFNDEF FPC}
  LNative: TArray<TCustomAttribute>;
  LRttiType: TRttiType;
  LJ: Integer;
  LSkip: Boolean;
  LNativeFiltered: TArray<TObject>;
  LFilteredLen: Integer;
  {$ENDIF}
begin
  Result := nil;
  FLock.Enter;
  try
    if not FRegistry.TryGetValue(AClass, LRecord) then
      LRecord.Owned := nil;

    LOwnedLen := Length(LRecord.Owned);

    {$IFDEF FPC}
    // FPC: apenas copia de Owned. Nao ha RTTI de atributos nativos.
    SetLength(Result, LOwnedLen);
    for LIdx := 0 to LOwnedLen - 1 do
      Result[LIdx] := LRecord.Owned[LIdx];
    {$ELSE}
    // Delphi: Owned + Native filtrado (regra 2 do ADENDO).
    LRttiType := FContext.GetType(AClass);
    if LRttiType <> nil then
      LNative := LRttiType.GetAttributes
    else
      LNative := nil;

    // Filtra Native: descarta toda instancia cuja ClassType ja esta em Owned.
    LNativeFiltered := nil;
    for LIdx := 0 to High(LNative) do
    begin
      LSkip := False;
      for LJ := 0 to High(LRecord.Owned) do
        if (LRecord.Owned[LJ] <> nil) and
           (LRecord.Owned[LJ].ClassType = LNative[LIdx].ClassType) then
        begin
          LSkip := True;
          Break;
        end;
      if not LSkip then
      begin
        SetLength(LNativeFiltered, Length(LNativeFiltered) + 1);
        LNativeFiltered[High(LNativeFiltered)] := LNative[LIdx];
      end;
    end;

    LFilteredLen := Length(LNativeFiltered);
    SetLength(Result, LOwnedLen + LFilteredLen);
    for LIdx := 0 to LOwnedLen - 1 do
      Result[LIdx] := LRecord.Owned[LIdx];
    for LIdx := 0 to LFilteredLen - 1 do
      Result[LOwnedLen + LIdx] := LNativeFiltered[LIdx];
    {$ENDIF}
  finally
    FLock.Leave;
  end;
end;

procedure FreeRegistryOwned;
var
  LPair: TPair<TClass, TAttributeRecord>;
  LIdx: Integer;
begin
  if FRegistry = nil then
    Exit;
  for LPair in FRegistry do
    for LIdx := 0 to High(LPair.Value.Owned) do
      if LPair.Value.Owned[LIdx] <> nil then
        LPair.Value.Owned[LIdx].Free;
end;

initialization
  FLock := TCriticalSection.Create;
  FRegistry := TDictionary<TClass, TAttributeRecord>.Create;
  {$IFNDEF FPC}
  FContext := TRttiContext.Create;
  {$ENDIF}

finalization
  FreeRegistryOwned;
  FRegistry.Free;
  FLock.Free;
  {$IFNDEF FPC}
  FContext.Free;
  {$ENDIF}

end.
