---
type: plan
kind: artifact
title: "PLAN — TModernValue.AsType<T> (issue #26)"
description: "Um único PR em três slices coordenadas: (1) TValueOps nos dois backends com testes de compilação; (2) TModernValue público + fecha drift do §7 em GetValue<T>; (3) cenários compartilhados + published tests + exceção local ao FPC. Ordem escolhida para deixar o compilador falar em cada etapa."
status: stable
cycle: "011"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/38e3bcee8cdc184a2977006358812748
tags: [modernrtti, plan, issue-26, fpc, delphi, tvalue]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# PLAN — issue #26

**Escopo:** um único PR. Slices são **passos ordenados dentro do mesmo
commit-set**, não entregas independentes — o build só volta a passar
quando todas fecham. Ordem escolhida para deixar o compilador falar em
cada etapa: se algo quebra, a slice em curso é a culpada.

Todas as decisões vêm do [adr](pipeline-adr.md). Todos os critérios de
`Aceito quando` estão no [esp](pipeline-esp.md).

## Slice 1 — `TValueOps` em ambos os backends

**Fim:** os dois backends expõem `TValueOps.AsType<T>` com a MESMA
assinatura; a lógica delas está no lugar (Delphi delega ao nativo, FPC
faz `IsType(TypeInfo(T))` + `ExtractRawData` + raise). A unit pública
ainda não usa — o slice é uma adição contida.

**Arquivos:**

- `Source/ModernSyntax.RTTI.Delphi.pas`:
  - Adicionar na `interface`:
    ```pascal
    type
      TValueOps = record
        class function AsType<T>(const AValue: TValue): T; static;
      end;
    ```
  - Na `implementation`:
    ```pascal
    class function TValueOps.AsType<T>(const AValue: TValue): T;
    begin
      Result := AValue.AsType<T>;
    end;
    ```
  - Nada mais no backend Delphi.
- `Source/ModernSyntax.RTTI.FPC.pas`:
  - Adicionar na `interface` a mesma declaração de `TValueOps`.
  - Junto às 8 `resourcestring` existentes (linhas 82–114 hoje),
    adicionar UMA nova:
    ```pascal
    SModernValueIncompatibleType = 'incompativel: origem=%s destino=%s';
    ```
  - Na `implementation`:
    ```pascal
    class function TValueOps.AsType<T>(const AValue: TValue): T;
    begin
      if not AValue.IsType(TypeInfo(T)) then
        raise EModernRTTIError.CreateFmt(SModernValueIncompatibleType,
          [string(AValue.TypeInfo^.Name),
           string(PTypeInfo(TypeInfo(T))^.Name)]);
      AValue.ExtractRawData(@Result);
    end;
    ```

**Aceito quando:** `PTestRTTI.lpr` compila em x86_64 na fábrica. Nenhum
teste novo ainda — verde por proteção dos cenários existentes. O slice é
adição pura; nada da unit pública mudou.

**Ponto de atenção Delphi:** confirmar que record com `class function
... static` **genérico** compila no Delphi 12. É o único ponto do
desenho não medido no ciclo de análise. Se falhar, o `TValueOps` vira
`class` (não record) na mesma unit — mudança contida a este slice.

## Slice 2 — `TModernValue` público + fecha o drift do §7

**Fim:** a superfície pública `TModernValue` existe e `GetValue<T>` de
`TModernRTTIProperty` deixa de carregar o único `{$IFDEF FPC}` fora da
`uses`.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas` — na `interface`, ao lado de
  `TModernRTTI`:
  ```pascal
  type
    TModernValue = record
    strict private
      FValue: TValue;
    public
      class function From<T>(const AValue: T): TModernValue; static;
      class function FromValue(const AValue: TValue): TModernValue; static;
      function AsType<T>: T;
    end;
  ```
  - XMLDoc de `AsType<T>` **obrigatório**, texto exato do D-6 do
    [adr](pipeline-adr.md).
- Corpos na `implementation`:
  ```pascal
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
    Result := TValueOps.AsType<T>(FValue);
  end;
  ```
  Zero `{$IFDEF}` no corpo.
- Substituir `TModernRTTIProperty.GetValue<T>` (hoje linhas 380–398):
  ```pascal
  function TModernRTTIProperty.GetValue<T>(const AInstance: TObject): T;
  begin
    Result := TModernValue.FromValue(FProp.GetValue(AInstance)).AsType<T>;
  end;
  ```
  O bloco `{$IFDEF FPC}...{$ELSE}...{$ENDIF}` (385–397) some.
- `TModernRTTIField.GetValue<T>` **não é tocado** (fora de escopo).

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa em x86_64 (fábrica) sem tocar em
  cenários — a suíte existente continua verde. `TestGetValue_Integer_
  Roundtrip`, `TestGetValue_String_Roundtrip`, `TestGetValue_Currency_
  Roundtrip` são os que passam pelo caminho refatorado.
- `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` mostra APENAS a
  diretiva da cláusula `uses` da `implementation`. Zero outros hits.

## Slice 3 — cenários compartilhados + published tests + exceção local FPC

**Fim:** os cenários que provam `AsType<T>` nos tipos exatos existem no
compartilhado, e o cenário de exceção nomeando origem/destino existe
apenas no runner FPC. Ambos os runners rodam.

**Arquivos:**

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — adicionar **sete**
  cenários novos, na sequência (todos `procedure ... ; begin ... end;`
  usando `Fail(...)`, sem `Assert`, sem `Exception` bruta, **zero
  `{$IFDEF FPC}`**):
  - `Scenario_ModernValue_AsType_String`: `TModernValue.From<string>('abc').AsType<string>` = `'abc'`.
  - `Scenario_ModernValue_AsType_Integer`: `TModernValue.From<Integer>(42).AsType<Integer>` = `42`.
  - `Scenario_ModernValue_AsType_Boolean`: `TModernValue.From<Boolean>(True).AsType<Boolean>` = `True`.
  - `Scenario_ModernValue_AsType_Double`: `TModernValue.From<Double>(3.14).AsType<Double>` bate em `SameValue(..., 3.14)`.
  - `Scenario_ModernValue_AsType_Object`: usa objeto local, ida-e-volta por `TObject`.
  - `Scenario_ModernValue_AsType_Record`: `type TPonto = record X, Y: Integer end;` ida-e-volta.
  - `Scenario_ModernValue_AsType_Enum`: enum com herança / multiplicidade 2+ no nível — declarar a fixture no arquivo (toca #21 e #38 de graça).
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — adicionar **oito** published:
  - Sete delegando aos cenários compartilhados (uma linha útil cada).
  - Um `published` extra **local**:
    `TestModernValue_AsType_DifferentType_RaisesWithOriginAndDestination`.
    Constrói `TValue.From<TPonto>(LRec)`, chama `AsType<string>`, captura
    `EModernRTTIError`, verifica `Pos('TPonto', E.Message) > 0` e
    `Pos('AnsiString', E.Message) > 0`. Comentário no cabeçalho:
    *"Asserção específica do backend FPC — válido até issue de
    alargamento ser resolvida."*
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — adicionar **sete**
  `[Test]` delegando aos cenários compartilhados. **Nenhum equivalente**
  ao teste de exceção do FPC.

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa em x86_64 na fábrica com todos os
  cenários novos verdes.
- `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` não
  aumenta em relação ao baseline pré-issue (CA-5 preservado).
- **Prova de mutação executada e declarada no corpo do PR:** trocar
  `if not AValue.IsType(TypeInfo(T))` por `if False` no backend FPC →
  `TestModernValue_AsType_DifferentType_...` falha, e o runner devolve
  `exit != 0`. Reverter a mutação antes de commitar.
- Autor confirma manualmente compilação Delphi (dcc32) e execução dos
  sete `[Test]` no Delphi 12; declara resultado no corpo do PR.
- Autor confirma manualmente compilação FPC i386 (fábrica não tem
  `ppc386` — SKILL.md:122–124).

## Impactos consolidados

| arquivo | ação |
|---|---|
| `Source/ModernSyntax.RTTI.pas` | adiciona `TModernValue` na interface; reescreve `TModernRTTIProperty.GetValue<T>` em uma linha; remove o `{$IFDEF FPC}` das linhas 385–397 |
| `Source/ModernSyntax.RTTI.Delphi.pas` | adiciona record `TValueOps` com `AsType<T>` delegando ao nativo |
| `Source/ModernSyntax.RTTI.FPC.pas` | adiciona record `TValueOps` com `IsType(TypeInfo(T))` + `ExtractRawData`; adiciona 1 resourcestring `SModernValueIncompatibleType` |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | 7 cenários novos + fixture record/enum; zero `{$IFDEF}` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | 7 published + 1 published local para o cenário de exceção |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | 7 `[Test]` delegando; sem equivalente do cenário de exceção |

## O que este plano NÃO faz

- Não toca `TModernRTTIField.GetValue<T>`.
- Não altera `ModernSyntax.Invoker.pas`.
- Não altera `.lpi`/`.lpr`/`.dpr` de nenhum runner (o `-Fu"Source"`
  acha os backends).
- Não retrofita outra unit do `Source/` para o FPC.
- **Não entrega o programa de medição de alargamento** (o `.dpr` com
  `TMeasure` record que a discussão deixou pronto). Ele nasce **na
  issue de alargamento**, quando esta abrir, com a matriz medida como
  pré-requisito.
- Não introduz `EModernValueError` — reusa `EModernRTTIError`.
- Não introduz enumeradores de `Values` (não existem no §3 do API-MAP).
