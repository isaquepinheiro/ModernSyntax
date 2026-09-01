---
type: plan
kind: artifact
title: "PLAN — Enumerators nas colecoes (issue #27)"
description: "Um unico PR em duas slices coordenadas: (1) cinco properties alias na unit publica + uses ModernSyntax.Attributes; (2) sete cenarios compartilhados + 6+6 wrappers nas cascas, com mutacao obrigatoria fazendo Fields ficar vermelho. Ordem escolhida para deixar o compilador falar em cada etapa."
status: stable
cycle: "012"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, plan, issue-27, fpc, delphi, enumerators]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# PLAN — issue #27

**Escopo:** um único PR. Slices são **passos ordenados dentro do mesmo
commit-set**, não entregas independentes — a issue só está fechada
quando as duas fecham. Ordem escolhida para deixar o compilador falar em
cada etapa: se algo quebra, a slice em curso é a culpada.

Todas as decisões vêm do [adr](pipeline-adr.md). Todos os critérios de
`Aceito quando` estão no [esp](pipeline-esp.md).

## Slice 1 — Cinco properties alias na unit pública

**Fim:** `TModernRTTITypeHelper` expõe `Fields`, `Properties`, `Methods`,
`Attributes`; `TModernRTTIMethod` expõe `Parameters`. Corpos triviais
(delegação a `Get*` existentes; `GetAttributes` novo delega a
`ModernAttributes.GetAttributes`). Nenhum teste ainda — a slice é
adição contida na unit pública.

**Arquivos:**

- `Source/ModernSyntax.RTTI.pas`:
  - **`uses` da `interface`:** adicionar `ModernSyntax.Attributes`.
    Única aresta nova. Verificar antes de qualquer teste que
    `PTestRTTI.lpr` compila em x86_64 — se houver ciclo (não esperado,
    ver R1 do [esp](pipeline-esp.md)), morre aqui.
  - **`TModernRTTITypeHelper` (linhas 282–307 hoje):** adicionar quatro
    properties públicas + um método privado `GetAttributes`:
    ```pascal
    strict private
      function GetAttributes: TArray<TObject>;
    public
      property Fields:     TArray<TModernRTTIField>    read GetFields;
      property Properties: TArray<TModernRTTIProperty> read GetProperties;
      property Methods:    TArray<TModernRTTIMethod>   read GetMethods;
      property Attributes: TArray<TObject>             read GetAttributes;
    ```
    XMLDoc curto em cada uma no tom dos vizinhos.
  - **`implementation`:**
    ```pascal
    function TModernRTTITypeHelper.GetAttributes: TArray<TObject>;
    begin
      Result := ModernAttributes.GetAttributes(FType.Handle);
    end;
    ```
  - **`TModernRTTIMethod` (linhas 220–271 hoje):** adicionar uma
    property:
    ```pascal
    property Parameters: TArray<TModernRTTIParameter> read GetParameters;
    ```
    XMLDoc **obrigatório** com o texto exato do D-6 do [adr](pipeline-adr.md):
    *"No FPC, acessar `Parameters` levanta `EModernRTTIError` — a
    assinatura de método de classe não existe no FPC 3.2.2"*.
  - **NÃO tocar** os `Get*` existentes, nem
    `TModernRTTIField.GetValue<T>`, nem os backends
    (`ModernSyntax.RTTI.Delphi.pas`, `ModernSyntax.RTTI.FPC.pas`),
    nem `.lpi`/`.lpr`.

**Aceito quando:**

- `PTestRTTI.lpr` compila em x86_64 na fábrica (`SKILL.md:129-141`), sem
  qualquer cenário novo — verde por proteção dos cenários existentes.
- `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` **continua**
  mostrando apenas a diretiva da `uses` da `implementation` (não regride
  o ganho da #26).

## Slice 2 — Cenários compartilhados + wrappers de casca + mutação

**Fim:** os sete cenários provam `for..in` sobre as cinco properties
(mais o par `Parameters`) nos dois compiladores; as duas cascas publicam
o que faz sentido em cada backend; a mutação obrigatória confirma que
`Scenario_Fields_ForIn_IteratesFields` fica vermelho quando a property
mente.

**Arquivos:**

- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — adicionar sete
  procedures, todas `procedure ... ; begin ... end;` sem `Assert`, sem
  `Exception` bruta, **zero `{$IFDEF FPC}`**:
  - `Scenario_Fields_ForIn_IteratesFields` — sobre `TPortableFieldFixture`
    (linha 82 hoje). Conta com `LCount := 0; for LField in LType.Fields
    do Inc(LCount);` e `Fail(...)` se `LCount` não bater com o esperado
    da fixture.
  - `Scenario_Properties_ForIn_IteratesProperties` — sobre
    `TPortableFixture` (linha 50).
  - `Scenario_Methods_ForIn_IteratesMethods` — sobre `TMethodDerived`
    (linha 110).
  - `Scenario_Attributes_ForIn_IteratesAttributes` — usar classe já
    marcada com `TAttribute` no `Test Shared/`, ou declarar fixture
    local; conta atributos por-tipo via `LType.Attributes`.
  - `Scenario_EmptyCollection_ForIn_DoesNotLoop` — classe sem
    `published`; `for LField in LType.Fields do Inc(LCount);` deve dar
    `LCount = 0` e não levantar. Um `Fail(...)` se `LCount <> 0`.
  - `Scenario_Parameters_ForIn_RaisesOnFPC` — padrão literal
    (`UScenarios.RTTI.pas:315-323`):
    ```pascal
    LRaised := False;
    try
      LMethod.Parameters;
    except
      on E: EModernRTTIError do LRaised := True;
    end;
    if not LRaised then
      Fail('esperava EModernRTTIError e nada foi levantado');
    ```
  - `Scenario_Parameters_ForIn_IteratesRealParameters` — itera com
    `for LP in LMethod.Parameters do Inc(LCount);` e compara com o
    esperado da fixture.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — adicionar **seis**
  `published` procedures:
  - `TestFields_ForIn_IteratesFields` → chama
    `Scenario_Fields_ForIn_IteratesFields`.
  - `TestProperties_ForIn_IteratesProperties` → idem.
  - `TestMethods_ForIn_IteratesMethods` → idem.
  - `TestAttributes_ForIn_IteratesAttributes` → idem.
  - `TestEmptyCollection_ForIn_DoesNotLoop` → idem.
  - `TestParameters_ForIn_RaisesOnFPC` →
    `Scenario_Parameters_ForIn_RaisesOnFPC` (não o irmão).
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — adicionar **seis**
  `[Test]` methods:
  - Os mesmos cinco comuns.
  - `TestParameters_ForIn_IteratesRealParameters` →
    `Scenario_Parameters_ForIn_IteratesRealParameters` (não o irmão).

**Aceito quando:**

- `PTestRTTI.lpr` compila e passa em x86_64 na fábrica com todos os
  cenários novos verdes.
- `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"` **não
  aumenta** em relação ao baseline pré-issue.
- `grep -n "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"`
  continua vazio.
- **Prova de mutação executada e declarada no corpo do PR** (padrão
  `SKILL.md:79-89, 92-97`): declarar um `function GetFieldsNil:
  TArray<TModernRTTIField>; begin Result := nil; end;` **temporariamente**
  no helper e trocar `read GetFields` por `read GetFieldsNil`; recompilar
  com `rm -rf /tmp/fpcbuild` primeiro; `TestFields_ForIn_IteratesFields`
  fica vermelho, runner devolve `exit != 0`. Reverter (remover o helper
  auxiliar e restaurar `read GetFields`) **antes** de commitar.
- Autor confirma manualmente a compilação Delphi (dcc32) e a execução
  dos seis `[Test]` no Delphi 12; declara resultado no corpo do PR.
- Autor confirma manualmente compilação FPC i386 (fábrica não tem
  `ppc386` — `SKILL.md:122-124`).

## Impactos consolidados

| arquivo | ação |
|---|---|
| `Source/ModernSyntax.RTTI.pas` (interface `uses`) | adiciona `ModernSyntax.Attributes` |
| `Source/ModernSyntax.RTTI.pas` (`TModernRTTITypeHelper`) | +4 properties (`Fields`, `Properties`, `Methods`, `Attributes`) + 1 método privado `GetAttributes` |
| `Source/ModernSyntax.RTTI.pas` (`TModernRTTIMethod`) | +1 property `Parameters` com XMLDoc D-6 |
| `Test Shared/EclbrSystem/UScenarios.RTTI.pas` | +7 cenários (5 comuns + par `Parameters`); zero `{$IFDEF}` |
| `Test FPC/EclbrSystem/UTestMS.RTTI.pas` | +6 `published` (5 comuns + `Parameters` raises) |
| `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` | +6 `[Test]` (5 comuns + `Parameters` itera) |

Runners (`PTestRTTI.lpr`, `PTestRTTI.dpr`), `.lpi`, backends
(`ModernSyntax.RTTI.Delphi.pas`, `ModernSyntax.RTTI.FPC.pas`) e
`ModernSyntax.Attributes.pas`: **inalterados.**

## O que este plano NÃO faz

- Não introduz nenhum `TModernXxxEnumerator` ou `TModernXxxCollection`.
- Não introduz `TypeEnumerate` ou `AttributeEnumerate` em nenhum backend.
- Não expõe `Types` no `TModernRTTI` — fica com a #28.
- Não expõe `Attributes` por-membro (`LField.Attributes` etc.).
- Não toca os `Get*` existentes, nem `TModernRTTIField.GetValue<T>`.
- Não introduz segundo record helper para `TModernRTTIType`.
- Não altera `.lpi`/`.lpr`/`.dpr` de nenhum runner.
- Não retrofita nenhuma outra unit de `Source/` para o FPC.
- **Não usa `AssertException`** (não existe no repo).
