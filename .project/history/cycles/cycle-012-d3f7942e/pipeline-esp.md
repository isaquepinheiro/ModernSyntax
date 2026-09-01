---
type: spec
kind: artifact
title: "ESP — Enumerators nas colecoes: for..in sobre Fields, Properties, Methods, Parameters, Attributes (issue #27)"
description: "Cinco properties novas alias de Get* transformam LType.GetFields em LType.Fields; for..in ja funciona sobre TArray<T> nos dois compiladores; zero enumerator/collection novo; Types fica para a #28; Attributes so por-tipo; Parameters no FPC continua levantando EModernRTTIError (D-26); CA-5 preservado com dois cenarios distintos e cascas divergentes."
status: draft
cycle: "012"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, rtti, spec, issue-27, fpc, delphi, enumerators, for-in]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-27-report
    title: "REPORT — Issue #27 (run 9db5013b320820890838e1578fb0df4f) — PRESENT"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§3 enumerators, §7 arquitetura fisica)"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — receita FPC, mutacao, traps"
---

# ESP — Enumerators nas colecoes (issue #27)

## 1. Objetivo

Fazer o consumidor escrever `for LField in LType.Fields do` — nas seis
coleções listadas no enunciado, menos `Types` (delegada explicitamente à
issue **#28**, ver §2) — funcionando nos **dois** compiladores, **sem
`{$IFDEF FPC}` no teste** (CA-5), sem quebrar quem já usa os `Get*`, e
cobrindo coleção vazia sem laço infinito nem exceção.

O relatório de investigação mediu no FPC 3.2.2 nos dois bitness que
`for C in TArray<T> do` **já compila e roda** hoje, e que os quatro `Get*`
(`GetFields`, `GetProperties`, `GetMethods`, `GetParameters`) e o
`ModernAttributes.GetAttributes(AClass)` **já devolvem `TArray<T>`**.
Consequência: a diferença entre o que a issue pede (`LType.Fields`) e o
que já existe (`LType.GetFields`) é **só o nome**. Cinco properties alias
resolvem — zero enumerator custom, zero record novo.

## 2. Escopo

Inclui:

- Adicionar **quatro properties** ao `TModernRTTITypeHelper` **existente**
  em `Source/ModernSyntax.RTTI.pas` (linhas 282–307):
  - `property Fields: TArray<TModernRTTIField> read GetFields;`
  - `property Properties: TArray<TModernRTTIProperty> read GetProperties;`
  - `property Methods: TArray<TModernRTTIMethod> read GetMethods;`
  - `property Attributes: TArray<TObject> read GetAttributes;`
- Adicionar **uma property** a `TModernRTTIMethod`
  (`Source/ModernSyntax.RTTI.pas:220-271`):
  - `property Parameters: TArray<TModernRTTIParameter> read GetParameters;`
- Adicionar **`ModernSyntax.Attributes` na `uses` da `interface`** de
  `Source/ModernSyntax.RTTI.pas` — a única aresta nova de dependência.
- Adicionar **`GetAttributes` como método privado** ao
  `TModernRTTITypeHelper` — corpo: `Result := ModernAttributes.GetAttributes(FType.Handle);`.
- Adicionar **sete cenários compartilhados** em
  `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, todos sem uma linha de
  `{$IFDEF}`:
  - `Scenario_Fields_ForIn_IteratesFields`
  - `Scenario_Properties_ForIn_IteratesProperties`
  - `Scenario_Methods_ForIn_IteratesMethods`
  - `Scenario_Attributes_ForIn_IteratesAttributes`
  - `Scenario_EmptyCollection_ForIn_DoesNotLoop`
  - `Scenario_Parameters_ForIn_RaisesOnFPC` (try/except + `Fail(...)`)
  - `Scenario_Parameters_ForIn_IteratesRealParameters`
- Cascas: adicionar **seis `published` procedures** em
  `Test FPC/EclbrSystem/UTestMS.RTTI.pas` (cinco comuns +
  `Scenario_Parameters_ForIn_RaisesOnFPC`), e **seis `[Test]` methods** em
  `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` (cinco comuns +
  `Scenario_Parameters_ForIn_IteratesRealParameters`). Padrão "dois
  cenários distintos + duas cascas" da #25.
- XMLDoc obrigatório da nova property `TModernRTTIMethod.Parameters`
  declarando, na voz das outras divergências:
  *"No FPC, acessar `Parameters` levanta `EModernRTTIError` — a
  assinatura de método de classe não existe no FPC 3.2.2"* (D-26,
  `RTTI.FPC.pas:352-357`).

Fora de escopo:

- **12 records `TModernXxxEnumerator` + `TModernXxxCollection`.** Motivo
  medido: `for..in` sobre `TArray<T>` já entrega o que a issue pede;
  introduzir 12 tipos públicos novos seria a maior expansão de superfície
  pública do framework sem entregar nada mensurável a mais. `Source/` tem
  zero `GetEnumerator` hoje.
- **`Types`.** Depende de `TModernRTTI.GetTypes`, que não existe no FPC
  3.2.2 e tem issue própria aberta (**#28**). Quando a #28 entregar
  `GetTypes: TArray<TModernRTTIType>`, `for LType in TModernRTTI.Types do`
  funciona **de graça** pelo mesmo mecanismo — a #28 nasce sabendo
  (registrar no PR desta) que deve expor `property Types` na mesma passada.
- **`Attributes` por-membro** (`LField.Attributes`, `LProperty.Attributes`,
  `LMethod.Attributes`). No FPC não existe em `vmtFieldTable`/
  `vmtMethodTable`; cairia na política "levanta em vez de mentir" (D-26)
  em três a quatro pontos e multiplicaria por 3 a superfície nova sem que
  a issue peça explicitamente. Vira issue própria se e quando fizer falta.
- `AttributeEnumerate` como função de backend (caminho b). Sem enumerator
  novo, não há duplicação a evitar; o encapsulamento do (b) tem custo
  maior (nova função em cada backend) que benefício (uma aresta a menos
  em `uses`).
- Alterar os `Get*` existentes, os runners (`PTestRTTI.lpr`,
  `PTestRTTI.dpr`), o `.lpi`, ou qualquer outra unit de `Source/`.

## 3. Regras de negócio

- **§7 do API-MAP é lei:** tipo público jamais sob `{$IFDEF}` de
  compilador; corpo de método idem. O único `{$IFDEF}` da unit pública
  fica na cláusula `uses` (já estabelecido pela família das issues
  #21/#25/#26). As cinco properties vivem na `interface` sem uma linha
  condicional; a divergência (`Parameters` levanta no FPC) mora no
  backend, não no tipo público.
- **Um único helper ativo por tipo.** Pascal só admite **um** record
  helper ativo por tipo em escopo; um segundo esconderia
  `GetMethods`/`GetMethod`. As quatro properties entram no
  `TModernRTTITypeHelper` **existente**
  (`Source/ModernSyntax.RTTI.pas:282`).
- **Superfície mínima, delegação pura.** Cada property é um alias de
  `Get*`; o corpo é uma expressão. Nada de tabela, dispatch ou cache
  novo — os `Get*` já materializam o array com o cache que existir.
- **`Attributes` só por-tipo.** `LType.Attributes` delega a
  `ModernAttributes.GetAttributes(FType.Handle)` — caminho (a) do
  relatório. `LField.Attributes`/`LProperty.Attributes`/
  `LMethod.Attributes` **não** entram nesta issue.
- **Paridade de assinatura nos backends.** Como **não** há função nova
  de backend (`AttributeEnumerate` foi descartado), o portão de
  compilação continua o mesmo — os `Get*` existentes já têm paridade.
- **D-26 preservada.** `Parameters` no FPC continua levantando
  `EModernRTTIError`; a XMLDoc da property pública declara isso na voz
  das outras divergências.
- **CA-5:** zero `{$IFDEF FPC}` no código de teste compartilhado
  (`UScenarios.RTTI.pas`). A divergência de `Parameters` mora em qual
  casca publica qual cenário — mesmo padrão da #25.
- **`Fail(...)` (levanta `ETestScenarioFailed`), nunca `Assert`, nunca
  `Exception` bruta.** Padrão fixado na #25/#26 (PR #37, issue #35);
  `SKILL.md` não passa `-Sa`, `Assert` vira no-op silencioso e o runner
  devolveu exit 0 sobre vermelho na #35.
- **`AssertException` NÃO EXISTE neste repo** — não usar. O cenário
  compartilhado é Pascal puro que levanta via `Fail(...)`; o padrão
  literal medido em `UScenarios.RTTI.pas:315-323` é try/except + `Fail`.

## 4. Critérios de aceitação

- [ ] Após a edição, `TModernRTTITypeHelper` (linhas 282–307 hoje) tem
      quatro properties públicas — `Fields`, `Properties`, `Methods`,
      `Attributes` — cada uma delegando a `Get*` (ou, no caso de
      `Attributes`, a um novo método privado `GetAttributes`).
      **Zero `{$IFDEF}` na declaração dessas properties.**
- [ ] `TModernRTTIMethod` tem uma nova property `Parameters` delegando a
      `GetParameters` (linha 246). **Zero `{$IFDEF}`.**
- [ ] XMLDoc da property `Parameters` carrega o texto explícito, na voz
      das outras divergências: *"No FPC, acessar `Parameters` levanta
      `EModernRTTIError` — a assinatura de método de classe não existe
      no FPC 3.2.2"*.
- [ ] `Source/ModernSyntax.RTTI.pas` importa `ModernSyntax.Attributes`
      na `uses` da `interface`. Após a edição,
      `grep -n "{\$IFDEF" Source/ModernSyntax.RTTI.pas` continua
      mostrando **apenas** a diretiva da `uses` da `implementation`
      (não regride o ganho da #26).
- [ ] Os quatro `Get*` (`GetFields`, `GetProperties`, `GetMethods`,
      `GetParameters`) e `TModernRTTIField.GetValue<T>` permanecem
      **inalterados**.
- [ ] `for X in LType.Fields do` compila e roda para `Fields`,
      `Properties`, `Methods`, `Attributes` nos dois compiladores;
      `for LP in LMethod.Parameters do` compila em ambos e no FPC
      levanta `EModernRTTIError`.
- [ ] Enumerar coleção vazia (classe sem `published`) não levanta e não
      entra em laço infinito — cenário explícito
      `Scenario_EmptyCollection_ForIn_DoesNotLoop`.
- [ ] Sete cenários novos em
      `Test Shared/EclbrSystem/UScenarios.RTTI.pas`, todos usando
      `Fail(...)` (não `Assert`, não `Exception` bruta), **zero
      `{$IFDEF FPC}`** (CA-5). O padrão do
      `Scenario_Parameters_ForIn_RaisesOnFPC` é literal:
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
- [ ] `grep -c "IFDEF" "Test Shared/EclbrSystem/UScenarios.RTTI.pas"`
      **não aumenta** em relação ao baseline pré-issue.
- [ ] `grep -n "AssertException" "Test Shared/" "Test FPC/" "Test Delphi/"`
      continua vazio (o símbolo não existe, não introduzir).
- [ ] `Test FPC/EclbrSystem/UTestMS.RTTI.pas` recebe **seis** published:
      os cinco comuns +
      `Scenario_Parameters_ForIn_RaisesOnFPC` (não o irmão que itera).
- [ ] `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` recebe **seis**
      `[Test]`: os cinco comuns +
      `Scenario_Parameters_ForIn_IteratesRealParameters` (não o irmão
      que espera exceção).
- [ ] `PTestRTTI.lpr` compila e passa em x86_64 na fábrica.
- [ ] Autor confirma i386 (`SKILL.md:122-124` — fábrica sem `ppc386`) e
      Delphi 12 manualmente, e declara no corpo do PR.
- [ ] Um teste que use `for..in` sobre qualquer uma das cinco properties
      (ou o par `Parameters`) compila **sem `{$IFDEF FPC}` no código do
      teste** (CA-5 — critério explícito do enunciado da issue).
- [ ] Prova de mutação declarada no corpo do PR (padrão
      `SKILL.md:79-89, 92-97`): trocar temporariamente
      `property Fields ... read GetFields` por
      `property Fields ... read GetFieldsNil` (função que devolve `nil`)
      faz `Scenario_Fields_ForIn_IteratesFields` **ficar vermelho** —
      runner devolve `exit != 0`. Reverter antes de commitar.

## 5. Restrições

- **Sem enumerator/collection novo.** Zero record novo, zero
  `GetEnumerator`, zero `TModernXxxCollection`. A entrega é property
  alias sobre `TArray<T>` já existente.
- **Sem tocar `Get*`.** A issue promete manter o acesso por array —
  cumpre.
- **Sem tocar `TModernRTTIField.GetValue<T>`.**
- **Sem introduzir função nova de backend** — sem `AttributeEnumerate`,
  sem `TypeEnumerate`.
- **Sem `Attributes` por-membro** — fica para issue própria.
- **Sem `Types` nesta issue** — delegada à #28 (aberta). Registrar no
  corpo do PR a nota para a #28 nascer sabendo: expor
  `property Types: TArray<TModernRTTIType>` na mesma passada.
- **Sem alterar `.lpi`/`.lpr`/`.dpr`.** `-Fu"Source"` já resolve.
- **Sem segundo record helper para `TModernRTTIType`** — proibição
  linguística (Pascal só admite um ativo por tipo em escopo).
- **Sem `AssertException(...)`** — símbolo não existe no repo. Usar
  try/except + `Fail(...)`.

## 6. Riscos

- **R1 — `ModernSyntax.Attributes` na `uses` da `interface` de
  `RTTI.pas` pode criar ciclo?** Medição do relatório:
  `ModernSyntax.Attributes` importa `Generics.Collections`, `SyncObjs` e
  (no Delphi) `Rtti` — todos RTL padrão nos dois compiladores. Não
  importa `ModernSyntax.RTTI`. Sem risco de ciclo. Primeira coisa a
  verificar na Slice 1: `PTestRTTI` compila em x86_64 assim que a `uses`
  for adicionada.
- **R2 — `Attributes` por-tipo devolve `TArray<TObject>`.** É o contrato
  que `ModernAttributes.GetAttributes(AClass)` já publica hoje
  (`Attributes.pas:111`). O consumidor faz `if LAttr is TMyAttribute`
  como sempre. Cobrir a forma no `Scenario_Attributes_ForIn_...` é
  suficiente; a divergência semântica "atributo Delphi nativo x instância
  registrada no FPC" já é pré-existente da família da #21.
- **R3 — Mutação obrigatória exige forma de trocar o read acessor.**
  Duas opções: (i) criar `GetFieldsNil: TArray<TModernRTTIField>; begin
  Result := nil; end;` local ao ciclo e trocar o `read` da property
  temporariamente; (ii) editar `GetFields` para retornar `nil`. Slice 3
  do plan usa (i) — menor superfície, mais fácil reverter, independente
  de cache. Só o cenário de `Fields` fica vermelho; os outros continuam
  verdes — isso É o critério.
- **R4 — Compilação Delphi não medida na fábrica.** As properties novas
  são Pascal trivial (delegação a método já existente), padrão idêntico
  ao das outras seis já no `TModernRTTITypeHelper`. Evidência forte por
  analogia. Registrar literal no PR: *"assumido pelo padrão do repo;
  primeira coisa a confirmar no build Delphi do ciclo de implementação"*.
- **R5 — `for..in` sobre `TArray<T>` retornado por método** — medido
  pelo analista no FPC 3.2.2 nos dois bitness (relatório item M-A). Zero
  risco de compilação/execução; sintaxe básica suportada há muito nos
  dois compiladores.
- **R6 — CA-5 na sombra:** as `[Test]`/`published` da casca são
  wrappers de cenário compartilhado; nenhuma linha de `{$IFDEF}` entra
  em `UScenarios.RTTI.pas`. Grep automático do baseline preserva o
  critério mecânico.
