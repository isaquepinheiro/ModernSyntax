---
type: adr
kind: decision
title: "ADR — Enumerators nas colecoes: property alias sobre TArray<T>, zero enumerator novo (issue #27)"
description: "Restatement da decisao que fechou a discussao da issue #27 (2 voltas): for..in ja funciona sobre TArray<T> nos dois compiladores; cinco properties alias no TModernRTTITypeHelper existente + Parameters em TModernRTTIMethod entregam a issue; 12 records enumerator/collection sao descartados; Types sai para a #28; Attributes so por-tipo via caminho (a); dois cenarios distintos + duas cascas para Parameters; mutacao obrigatoria: property de Fields devolve nil e o cenario fica vermelho."
status: stable
cycle: "012"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/d3f7942e59d0ba69094d93420fef84db
tags: [modernrtti, adr, issue-27, fpc, delphi, enumerators, for-in]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: issue-27-report
    title: "REPORT — Issue #27 (run 9db5013b320820890838e1578fb0df4f) — PRESENT"
  - id: api-map
    resource: "/strategy/2026-08-27-modernrtti/API-MAP.md"
    title: "ModernRTTI API-MAP (§3 enumerators, §7 arquitetura fisica)"
  - id: adr-026
    resource: "/history/cycles/cycle-011-38e3bcee/pipeline-adr.md"
    title: "ADR ciclo 011 — D-26: onde o dado nao existe, nao devolva valor que seja resposta legitima"
  - id: skill
    resource: "/SKILL.md"
    title: "SKILL — toolchain e traps"
---

# ADR — issue #27

Este documento **deriva do relatório de investigação** que fechou a
discussão da issue #27 (duas voltas, humano + agente, run
`9db5013b320820890838e1578fb0df4f`). Ele registra a decisão em vigor,
nos termos que a conversa acertou. Não reabre nada — o próximo portão é
escrever código.

**Não há divergência de mérito** entre este ADR e o relatório. As duas
correções da volta 2 (o `AssertException` inventado no round 1 do
arquiteto anterior e a ambiguidade da frase "cenário compartilhado
adicional… por compilador") já foram absorvidas pelo próprio relatório
antes de fechar; ficam registradas aqui só para não haver dúvida de que
a leitura correta foi transportada. Nenhum ajuste editorial próprio
deste arquiteto.

## Contexto medido

- **`for C in TArray<T> do` já compila e roda no FPC 3.2.2 nos dois
  bitness**, incluindo `TArray` nil (0 iterações, sem crash). Medição
  M-A do relatório, executada pelo analista.
- **Os quatro `Get*` já devolvem `TArray<T>`:**
  `GetProperties` (`ModernSyntax.RTTI.pas:163`),
  `GetFields` (`:175`),
  `GetParameters` (`:246`),
  `GetMethods` (`:299`). E
  `ModernAttributes.GetAttributes(AClass)` também retorna
  `TArray<TObject>` (`Attributes.pas:111`).
- **`Source/` tem zero `GetEnumerator` hoje** (grep). Introduzir 12
  records `TModernXxxEnumerator` + `TModernXxxCollection` seria a maior
  expansão de superfície pública do framework, sem entregar nada
  mensurável a mais que `for..in TArray<T>` já entrega.
- **`Types` depende de `TModernRTTI.GetTypes`, que não existe no FPC**,
  e tem issue própria aberta: **#28** (OPEN, confirmada). Trazer `Types`
  para cá seria resolver #28 dentro de #27 sem investigação própria.
- **`Parameters` no FPC levanta `EModernRTTIError`** hoje
  (`RTTI.FPC.pas:352-357`, D-26 do ciclo 010). A assinatura de método
  de classe não existe no FPC 3.2.2 — decisão certa que não muda.
- **`AssertException` não existe no repo** (grep zero em `Test Shared/`,
  `Test FPC/`, `Test Delphi/`). Cenário compartilhado é Pascal puro que
  levanta via `Fail(...)` → `ETestScenarioFailed`; padrão literal medido
  em `UScenarios.RTTI.pas:315-323`.
- **NÃO medido:** compilação Delphi da nova property no
  `TModernRTTITypeHelper`. Como é delegação trivial a método existente e
  o helper já tem seis membros do mesmo padrão, é evidência forte por
  analogia — mas evidência por analogia não é medição. **Primeira coisa
  a confirmar no build Delphi do ciclo de implementação**. Se falhar,
  investigar caso — mas o desenho não tem alternativa contida a este
  slice, porque não há genérico novo aqui (as properties devolvem
  `TArray<T>` já parametrizado por membros existentes).

## Decisão

### D-1. Superfície pública: cinco properties alias sobre `TArray<T>`

`TModernRTTITypeHelper` **existente** ganha quatro properties, cada uma
delegando a um `Get*` já existente:

```pascal
property Fields:     TArray<TModernRTTIField>    read GetFields;
property Properties: TArray<TModernRTTIProperty> read GetProperties;
property Methods:    TArray<TModernRTTIMethod>   read GetMethods;
property Attributes: TArray<TObject>             read GetAttributes;
```

`TModernRTTIMethod` ganha uma property:

```pascal
property Parameters: TArray<TModernRTTIParameter> read GetParameters;
```

**Zero `{$IFDEF}` na declaração pública. Zero corpo condicional.** Os
`Get*` continuam existindo e inalterados — a issue promete "mantendo
também o acesso por array onde já existe".

### D-2. Helper existente, não um segundo

Pascal só admite **um** record helper ativo por tipo em escopo. Um
segundo `TModernRTTITypeHelper2` esconderia `GetMethods`/`GetMethod` —
regressão silenciosa. As quatro properties entram no helper
existente em `Source/ModernSyntax.RTTI.pas:282-307`, junto às seis já
declaradas.

### D-3. `Attributes` — caminho (a): `uses ModernSyntax.Attributes` na `interface`

Dois caminhos foram considerados:

- **(a)** `RTTI.pas` importa `ModernSyntax.Attributes` na `interface` e
  `TModernRTTITypeHelper.GetAttributes` chama
  `ModernAttributes.GetAttributes(FType.Handle)` direto. Custo: uma
  aresta nova em `uses`. Benefício: zero duplicação entre backends.
- **(b)** Cada backend expõe `AttributeEnumerate(AClass): TArray<TObject>`
  delegando internamente. Custo: nova função em cada backend, mais uma
  paridade de assinatura a manter. Benefício: uma aresta a menos em `uses`.

**Adotada (a).** Sem enumerator custom, não há duplicação a evitar; o
encapsulamento que (b) preservava importa menos. `ModernSyntax.Attributes`
importa `Generics.Collections`, `SyncObjs` e (no Delphi) `Rtti` — todos
RTL padrão nos dois. Sem risco de ciclo (não importa `RTTI.pas`).

Implementação:

```pascal
// interface uses:  ..., ModernSyntax.Attributes, ...;

// TModernRTTITypeHelper (implementation):
function TModernRTTITypeHelper.GetAttributes: TArray<TObject>;
begin
  Result := ModernAttributes.GetAttributes(FType.Handle);
end;
```

### D-4. `Attributes` só por-tipo

`LType.Attributes` entra. `LField.Attributes`, `LProperty.Attributes`,
`LMethod.Attributes` **NÃO entram**. Motivos medidos:

- No FPC, atributo por-membro **não existe** em `vmtFieldTable`/
  `vmtMethodTable`. Cairia na política D-26 ("levanta em vez de mentir")
  em 3–4 pontos.
- A issue não pede explicitamente.
- Multiplica por 3 a superfície nova.

Se e quando fizer falta, vira issue própria.

### D-5. `Types` fora — vai com a #28

`TModernRTTI.GetTypes` não existe no FPC e tem issue própria (#28,
OPEN). Trazer para cá seria resolver #28 dentro de #27 sem investigação
própria. **Registrar no corpo do PR desta issue** a nota para a #28
nascer sabendo: quando implementar `GetTypes: TArray<TModernRTTIType>`,
expor também `property Types: TArray<TModernRTTIType> read GetTypes` na
mesma passada — funciona de graça pelo mesmo mecanismo (property alias +
`for..in` sobre `TArray<T>`).

### D-6. `Parameters` no FPC continua levantando — XMLDoc obrigatório

`TModernRTTIMethod.Parameters` no FPC continua levantando
`EModernRTTIError` (D-26, `RTTI.FPC.pas:352-357`). A property é alias
puro de `GetParameters`; não muda o backend. XMLDoc obrigatório, na voz
das outras divergências:

> No FPC, acessar `Parameters` levanta `EModernRTTIError` — a
> assinatura de método de classe não existe no FPC 3.2.2.

### D-7. Testes — padrão "dois cenários distintos + duas cascas"

Cinco cenários comuns em `Test Shared/EclbrSystem/UScenarios.RTTI.pas`,
mais o **par distinto** para `Parameters` — total sete, **zero
`{$IFDEF}`** (CA-5):

- `Scenario_Fields_ForIn_IteratesFields` — conta campos de
  `TPortableFieldFixture` (fixture com herança, `UScenarios.RTTI.pas:82`).
- `Scenario_Properties_ForIn_IteratesProperties` — conta properties de
  `TPortableFixture` (`:50`).
- `Scenario_Methods_ForIn_IteratesMethods` — conta métodos de
  `TMethodDerived` (`:110`).
- `Scenario_Attributes_ForIn_IteratesAttributes` — conta atributos
  por-tipo.
- `Scenario_EmptyCollection_ForIn_DoesNotLoop` — classe sem `published`;
  laço não entra, nada levanta.
- `Scenario_Parameters_ForIn_RaisesOnFPC` — try/except esperando
  `EModernRTTIError`; se não levantar, `Fail(...)`. Padrão literal
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
- `Scenario_Parameters_ForIn_IteratesRealParameters` — itera e conta
  parâmetros reais.

Cascas:

- `Test FPC/EclbrSystem/UTestMS.RTTI.pas` publica **seis** procedures:
  os cinco comuns + `Scenario_Parameters_ForIn_RaisesOnFPC`.
- `Test Delphi/EclbrSystem/UTestMS.RTTI.pas` publica **seis** `[Test]`:
  os cinco comuns + `Scenario_Parameters_ForIn_IteratesRealParameters`.

A divergência do par `Parameters` mora em **qual casca publica qual**,
não no arquivo compartilhado. Mesmo padrão da #25.

### D-8. `Fail(...)`, nunca `Assert`, nunca `Exception` bruta

Padrão fixado na #25 (PR #37, issue #35). `SKILL.md` não passa `-Sa`:
`Assert` vira no-op silencioso e o runner devolveu exit 0 sobre vermelho
na #35. `Exception` bruta é engolida da mesma forma. `Fail(...)` levanta
`ETestScenarioFailed` e é o que faz o runner devolver `exit != 0`.

### D-9. Mutação obrigatória — property de `Fields` devolve `nil`

Antes de fechar o PR: trocar o `read` de `Fields` para uma função que
retorna `nil` (não editar `GetFields` — mais fácil reverter). Executar a
suíte. `Scenario_Fields_ForIn_IteratesFields` **tem de ficar vermelho**
(runner devolve `exit != 0`). Reverter a mutação depois. Se passar
verde, o teste não vale nada. Padrão SKILL.md:79–89, 92–97.

## O que foi descartado, e a medição que derrubou

- **12 records `TModernXxxEnumerator` + `TModernXxxCollection`.**
  Descartado na volta 1 do relatório: `for..in` sobre `TArray<T>` já
  compila e roda nos dois compiladores/bitness (`for C in Fields do` → 3
  itens, ordem preservada; `for C in <array nil> do` → 0 iterações, sem
  crash — medido no FPC 3.2.2 x86_64 e i386); os quatro `Get*` já
  devolvem `TArray<T>`. **Custo evitado:** maior expansão de superfície
  pública do framework (zero `GetEnumerator` hoje em `Source/`), num
  arquivo que #25 e #26 acabaram de reorganizar. **Onus da prova alto:**
  qualquer enumerator novo teria de responder "o que ele entrega que
  `for..in` sobre o array já não entrega?"; a resposta não é mensurável
  aqui, então não entra. Regra: **menor risco ganha.**
- **`Types` no escopo desta issue.** Descartado na volta 1:
  `TModernRTTI.GetTypes` não existe no FPC 3.2.2 e a #28 está OPEN
  cobrindo exatamente isso. Trazer para cá seria resolver #28 dentro de
  #27 sem investigação própria.
- **`AttributeEnumerate` como função de backend (caminho (b)).**
  Descartado na volta 1: sem enumerator novo, não há duplicação a
  evitar; o encapsulamento tem custo maior (nova função em cada backend)
  que benefício (uma aresta a menos em `uses`).
- **`Attributes` por-membro** (`LField.Attributes`, `LProperty.Attributes`,
  `LMethod.Attributes`). Descartado na volta 1: no FPC não existe em
  `vmtFieldTable`/`vmtMethodTable`; cairia na D-26 em 3–4 pontos; a
  issue não pede explicitamente. Menor superfície.
- **`AssertException(...)` no cenário compartilhado.** Descartado na
  volta 2 pela medição: grep confirmou zero matches em `Test Shared/`,
  `Test FPC/`, `Test Delphi/` — símbolo inexistente. Foi um erro do
  round 1 do arquiteto anterior, inventado sem medir. O padrão real do
  arquivo é try/except + `Fail(...)` (`UScenarios.RTTI.pas:315-323`).
- **`Assert` puro no cenário compartilhado.** Descartado (padrão fixado
  desde a #25): `Assert` é removido sem `-Sa`; runner devolveria exit 0
  sobre vermelho.
- **`Exception` genérica em vez de `EModernRTTIError` específica.**
  Descartado (mesma razão): sem a exceção específica, o runner mascara
  o vermelho.
- **Segundo `TModernRTTITypeHelper`.** Descartado por linguagem: Pascal
  só admite um record helper ativo por tipo em escopo; um segundo
  esconderia `GetMethods`/`GetMethod`. As properties vão no existente.

## Regras registradas nesta discussão para próximos ciclos

- **`for..in` sobre `TArray<T>` é sintaxe básica suportada nos dois
  compiladores há muito tempo.** Antes de propor enumerator custom para
  uma coleção que já é `TArray<T>`, responda: *o que ele entrega que
  `for..in` sobre o array já não entrega?* Se a resposta não for
  mensurável, não entra.
- **Não invente símbolo que "parece razoável" sem grep.** O
  `AssertException` inventado no round 1 do ciclo anterior é o mesmo tipo
  de erro que a regra "menor risco ganha" (M-B do relatório) foi feita
  para prevenir. Meça o repo antes de nomear.
- **Padrão "dois cenários distintos + duas cascas" para divergência de
  comportamento entre backends.** Instituído na #25, reforçado aqui.
  Zero diretiva no compartilhado; a casca escolhe o cenário certo para
  seu backend.

## Impacto e reversibilidade

- **Adição pura.** Nada é removido; nenhum `Get*` é alterado. Quem
  chama `LType.GetFields()` hoje continua compilando amanhã.
- Nova aresta de dependência: `interface` de `Source/ModernSyntax.RTTI.pas`
  passa a importar `ModernSyntax.Attributes`. Sem risco de compilação
  (RTL padrão dos dois compiladores).
- `Parameters` no FPC mantém o comportamento (levanta `EModernRTTIError`);
  a property é alias, não muda backend. XMLDoc declara em voz alta.
- Reversão: remover as cinco properties e o método privado
  `GetAttributes`, tirar `ModernSyntax.Attributes` da `uses` da
  `interface`, remover os sete cenários e os wrappers das cascas.
  Trivial.

## Referências

- [esp](pipeline-esp.md) — critérios formais e checklist.
- [plan](pipeline-plan.md) — ordem de execução.
- [task-input](pipeline-task-input.md) — handoff operacional.
- [API-MAP §3 (enumerators) e §7 (arquitetura)](/strategy/2026-08-27-modernrtti/API-MAP.md)
- [SKILL — receita FPC + traps](/SKILL.md)
