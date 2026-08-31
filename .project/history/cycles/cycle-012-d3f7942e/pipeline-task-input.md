---
type: task-input
kind: artifact
title: "TASK-INPUT — Enumerators nas colecoes: for..in sobre Fields, Properties, Methods, Parameters, Attributes (issue #27)"
description: "Handoff operacional: cinco properties alias no TModernRTTITypeHelper e no TModernRTTIMethod transformam LType.GetFields em LType.Fields nos dois compiladores; for..in ja funciona sobre TArray<T>; sete cenarios em UScenarios + seis wrappers em cada casca; mutacao obrigatoria: property de Fields devolve nil e o cenario fica vermelho."
status: stable
cycle: "012"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, task-input, issue-27, fpc, delphi, enumerators, for-in, feature]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
---

# TASK-INPUT — issue #27

## Título

Enumerators nas coleções: `for..in` sobre `Fields`, `Properties`,
`Methods`, `Parameters`, `Attributes` — property alias sobre `TArray<T>`
nos dois compiladores.

## Tipo / labels

- `type: feature`
- `route: feature`
- labels: `enhancement`, `rtti`, `fpc`, `delphi`, `pilar-4`

## Escopo curto

Adicionar quatro properties alias ao `TModernRTTITypeHelper` **existente**
(`Fields`, `Properties`, `Methods`, `Attributes`) e uma property alias
ao `TModernRTTIMethod` (`Parameters`) em `Source/ModernSyntax.RTTI.pas`.
Cada property delega ao `Get*` já existente (ou, no caso de `Attributes`,
a um novo `GetAttributes` privado que chama
`ModernAttributes.GetAttributes(FType.Handle)`).

Adicionar `ModernSyntax.Attributes` na `uses` da `interface` — única
aresta nova de dependência.

`Get*` continuam existindo e inalterados — a issue promete "mantendo
também o acesso por array onde já existe".

**Zero enumerator/collection novo**, **zero `TModernXxxEnumerator`**,
**zero `TModernXxxCollection`**: `for..in` sobre `TArray<T>` já compila
e roda nos dois compiladores/bitness (medido).

`Types` fica **fora** — vai com a issue **#28** (aberta), que precisa
entregar `TModernRTTI.GetTypes` antes; expor `property Types` na mesma
passada, lá.

`Parameters` no FPC continua levantando `EModernRTTIError` (D-26,
`RTTI.FPC.pas:352-357`). A property é alias puro; XMLDoc declara em
voz alta.

## Checklist de aceitação

- [ ] `TModernRTTITypeHelper` (`Source/ModernSyntax.RTTI.pas:282-307`
      hoje) recebe quatro properties públicas:
      - `property Fields: TArray<TModernRTTIField> read GetFields;`
      - `property Properties: TArray<TModernRTTIProperty> read GetProperties;`
      - `property Methods: TArray<TModernRTTIMethod> read GetMethods;`
      - `property Attributes: TArray<TObject> read GetAttributes;`
      **Zero `{$IFDEF}` em qualquer uma.**
- [ ] O helper recebe um método privado
      `function GetAttributes: TArray<TObject>;` com corpo trivial:
      `Result := ModernAttributes.GetAttributes(FType.Handle);`.
- [ ] `TModernRTTIMethod` (`Source/ModernSyntax.RTTI.pas:220-271` hoje)
      recebe:
      `property Parameters: TArray<TModernRTTIParameter> read GetParameters;`.
      **Zero `{$IFDEF}`.**
- [ ] XMLDoc da property `Parameters` carrega o texto exato do D-6 do
      [adr](pipeline-adr.md): *"No FPC, acessar `Parameters` levanta
      `EModernRTTIError` — a assinatura de método de classe não existe
      no FPC 3.2.2"*.
- [ ] `Source/ModernSyntax.RTTI.pas` importa `ModernSyntax.Attributes`
      na `uses` da `interface`.
- [ ] Após a edição,
      `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua
      mostrando **apenas** a diretiva da `uses` da `implementation`
      (não regride o ganho da #26).
- [ ] Os quatro `Get*` (`GetFields`, `GetProperties`, `GetMethods`,
      `GetParameters`) permanecem **inalterados**.
- [ ] `TModernRTTIField.GetValue<T>` **não é tocado**.
- [ ] Backends `ModernSyntax.RTTI.Delphi.pas` e
      `ModernSyntax.RTTI.FPC.pas` **não são tocados** (a issue não
      exige função nova de backend).
- [ ] Sete cenários novos em
      `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, todos usando
      `Fail(...)` (não `Assert`, não `Exception` bruta), **zero
      `{$IFDEF FPC}`** (CA-5):
      `Scenario_Fields_ForIn_IteratesFields`,
      `Scenario_Properties_ForIn_IteratesProperties`,
      `Scenario_Methods_ForIn_IteratesMethods`,
      `Scenario_Attributes_ForIn_IteratesAttributes`,
      `Scenario_EmptyCollection_ForIn_DoesNotLoop`,
      `Scenario_Parameters_ForIn_RaisesOnFPC`,
      `Scenario_Parameters_ForIn_IteratesRealParameters`.
- [ ] `Scenario_Parameters_ForIn_RaisesOnFPC` usa **exatamente** o
      padrão try/except + `Fail(...)` medido em
      `UScenarios.RTTI.pas:315-323`. **NÃO usa `AssertException(...)`**
      (símbolo não existe no repo).
- [ ] `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      **não aumenta** em relação ao baseline pré-issue.
- [ ] `grep -n "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"`
      continua vazio.
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` recebe **seis** `published`
      procedures: cinco delegando aos comuns +
      `TestParameters_ForIn_RaisesOnFPC` delegando a
      `Scenario_Parameters_ForIn_RaisesOnFPC`. **Não publica** o irmão
      que itera.
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebe **seis** `[Test]`
      methods: cinco delegando aos comuns +
      `TestParameters_ForIn_IteratesRealParameters` delegando a
      `Scenario_Parameters_ForIn_IteratesRealParameters`. **Não publica**
      o irmão que espera exceção.
- [ ] `PTestRTTI.lpr` compila e passa em x86_64 na fábrica. Autor
      confirma i386 (`SKILL.md:122-124`) e Delphi 12 manualmente, e
      declara no corpo do PR.
- [ ] Um teste que use `for..in` sobre qualquer uma das cinco properties
      compila **sem `{$IFDEF FPC}` no código do teste** (CA-5,
      critério explícito do enunciado).
- [ ] Corpo do PR: `Closes #27`.
- [ ] Corpo do PR declara a mutação executada
      (`SKILL.md:79-89, 92-97`): declarar temporariamente
      `function GetFieldsNil: TArray<TModernRTTIField>; begin
      Result := nil; end;` no helper e trocar `read GetFields` por
      `read GetFieldsNil`; após `rm -rf /tmp/fpcbuild` e recompilar,
      `TestFields_ForIn_IteratesFields` **fica vermelho** (`exit != 0`).
      Reverter antes de commitar. Sem essa prova, o teste não vale nada.
- [ ] Corpo do PR declara, sem suavizar: *"assumido pelo padrão do
      repo que property alias `read Get*` compila no Delphi 12 no
      `TModernRTTITypeHelper` existente; primeira coisa a confirmar no
      build Delphi"*.
- [ ] Corpo do PR registra a nota para a **issue #28**: quando
      implementar `TModernRTTI.GetTypes: TArray<TModernRTTIType>`,
      expor **também** `property Types: TArray<TModernRTTIType> read
      GetTypes` na mesma passada — `for LType in TModernRTTI.Types do`
      funciona de graça pelo mesmo mecanismo.

## Arquivos provavelmente impactados

- `Source/ModernSyntax.RTTI.pas` — adiciona `ModernSyntax.Attributes`
  na `uses` da `interface`; adiciona 4 properties + 1 método privado
  `GetAttributes` ao `TModernRTTITypeHelper`; adiciona 1 property
  `Parameters` ao `TModernRTTIMethod` com XMLDoc.
- `Test Shared/EclbrSystem/UScenarios.RTTI.pas` — 7 cenários novos
  (5 comuns + par `Parameters`); zero `{$IFDEF}`.
- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` — 6 `published` (5 delegando +
  1 `Parameters` raises).
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` — 6 `[Test]` (5 delegando +
  1 `Parameters` itera).

**Runners e backends não mudam:** `PTestRTTI.lpr`, `PTestRTTI.dpr`,
`.lpi`, `ModernSyntax.RTTI.Delphi.pas`, `ModernSyntax.RTTI.FPC.pas` e
`ModernSyntax.Attributes.pas` **inalterados**. `-Fu"Source"` já resolve.

## Comandos de verificação (fábrica x86_64)

```
rm -rf /tmp/fpcbuild
mkdir -p /tmp/fpcbuild
fpc -Mdelphi \
    -Fu"Source" -Fu"Test Shared/EclbrSystem" -Fu"Test FPC/EclbrSystem" \
    -FU/tmp/fpcbuild -FE/tmp/fpcbuild \
    "Test FPC/EclbrSystem/PTestRTTI.lpr"
/tmp/fpcbuild/PTestRTTI --all -a --format=plain ; echo "exit=$?"
```

Espera-se `exit=0` no verde. Sob a mutação (property de `Fields`
delegando a `GetFieldsNil` que retorna `nil`), espera-se `exit != 0`
com `TestFields_ForIn_IteratesFields` vermelho (prova de que o teste
não é decorativo).

Verificações de grep:

```
grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas          # so a diretiva da uses da implementation
grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"  # nao aumenta
grep -n "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"  # continua vazio
```

## Referências

- [esp](pipeline-esp.md) — critérios formais.
- [adr](pipeline-adr.md) — decisão e o que foi descartado.
- [plan](pipeline-plan.md) — ordem de execução em 2 slices.
- [API-MAP §§3, 7](../../../strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL — receita FPC + traps](../../../SKILL.md)
