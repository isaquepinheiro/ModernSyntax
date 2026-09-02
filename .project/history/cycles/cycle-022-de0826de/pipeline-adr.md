---
type: adr
kind: artifact
title: "ADR D-51.1 — else raise EModernRTTIError nos dois sites de Visibility do backend Delphi (issue #51)"
description: "Supercede parcialmente D-42.2: intencao fail-loud preservada; mecanismo substituido de case-sem-else para case-com-else-raise no backend Delphi."
status: draft
cycle: "022"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/de0826deb51365cb442a8acd3e0fd103
tags: [adr, modernrtti, rtti, issue-51, bug, delphi, visibility, d-51-1, d-42-2]
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
sources:
  - id: investigation-51
    title: "Relatorio de investigacao — Issue #51 (run 2e4913d83ea2e1f06b3d8e8589bcbc4f)"
  - id: d-42-2
    resource: "/project-evolution.md"
    title: "D-42.2 — case explicito de 4 ramos (ciclo 015, issue #42)"
  - id: esp
    resource: "esp.md"
    title: "ESP — issue #51"
---

> **Fonte:** este ADR deriva do relatorio de investigacao da issue #51
> (run `2e4913d83ea2e1f06b3d8e8589bcbc4f`), cujas decisoes foram acordadas
> com o mantenedor em 1 volta de discussao. Onde este documento diverge
> do relatorio, a divergencia e declarada explicitamente.
>
> **Nao ha divergencia.** Todas as decisoes abaixo refletem o que foi
> acordado na investigacao, sem acrescimo nem omissao.

# ADR D-51.1 — else raise EModernRTTIError no backend Delphi (issue #51)

## Contexto

O ciclo 015 (issue #42, ADR D-42.2) deliberou que `MethodVisibility` e
`PropertyVisibility` usariam um `case` **explicito de exatamente 4 ramos**
sem `else` no backend Delphi. A premissa era: se `TMemberVisibility` do
Delphi ganhasse um valor adicional, **o compilador acusaria erro no primeiro
build** — tornando o `else` desnecessario e ate arriscado (um cast silenciaria
o valor novo).

A premissa foi medida e e falsa. Delphi nao faz analise de exaustividade em
`case` sobre enum. Ele emite **W1035** e compila; em runtime, o valor
nao coberto produz lixo no `Result`, com ordinal variando por compilador e
por bitness.

**Evidencia medida (4 alvos, run 2e4913d83ea2e1f06b3d8e8589bcbc4f):**

| Alvo | W1035 | Valor de lixo (ordinal) |
|------|-------|-------------------------|
| Delphi 23.0 / Win32 | SIM | 204 |
| Delphi 23.0 / Win64 | SIM | 16 |
| Delphi 37.0 / Win32 | SIM | 252 |
| Delphi 37.0 / Win64 | SIM | 16 |

3 valores distintos em 4 alvos: **indeterminado e nao reprodutivel entre
bitness** — confirmando "pior que um Ord() fora de faixa" (issue #51).

Efeito hoje: `main` (67b3b71) compila com 2 W1035 em todos os 4 alvos
Delphi. Sao os **unicos** warnings do repo nesses alvos — um warning
legitimo novo se mistura ao ruido.

---

## Decisao — D-51.1

**Adotar a opcao (a) da issue #51: `else raise EModernRTTIError.CreateFmt`
nos dois sites do backend Delphi.**

### D-51.1 — Mecanismo (agreed, volta 1)

Inserir em `MethodVisibility` e `PropertyVisibility`, antes do `end;` do
`case`:

```pascal
else
  raise EModernRTTIError.CreateFmt(
    SDelphiUnknownVisibility,
    [Ord(<token>.Visibility), '<nome-da-funcao>']);
```

Onde `<token>` e `TRttiMethod(AToken)` / `TRttiProperty(AToken)` e
`<nome-da-funcao>` e `'MethodVisibility'` / `'PropertyVisibility'`.

### D-51.2 — Criterio de desempate (agreed, volta 1)

**W1035 nao e o criterio.** Medido: tanto `else com cast` quanto `else
que levanta` matam W1035 igualmente nos 4 alvos. O criterio real e
**fail-loud vs. errado-em-silencio**:

- `else TModernVisibility(Ord(...))` — ordinal 4, deterministico,
  **silencioso**. E exatamente o que o comentario original queria evitar.
- `else raise EModernRTTIError` — excecao nomeando ordinal + funcao,
  **alto**. E o unico dos candidatos que entrega o comportamento prometido
  por D-42.2.

O ADR registra o desempate assim e nao como "so o raise mata o warning"
— para que a proxima pessoa nao conclua que o cast seria equivalente.

### D-51.3 — resourcestring privada na implementation (agreed, volta 1)

Declarar `SDelphiUnknownVisibility` na secao `implementation` de
`ModernSyntax.RTTI.Delphi.pas`, **nao** na `interface`. Segue o padrao
de `SFPCNoVisibility` / `SFPCNoReturnType`.

**Contraste explicito com PR #58:** naquele PR, `SModernRTTINilHandle`
foi promovida para a `interface` porque um cenario de teste em outra unit
precisava do simbolo. Aqui, o ramo `else raise` e inalcancavel por dado
real e **nao tera teste** — portanto nao ha justificativa para ampliar a
superficie publica.

### D-51.4 — Nome da funcao na mensagem (agreed, volta 1)

Com `AOwner` fora (ver D-51.5), o nome da funcao e o unico discriminante
entre os dois sites. Mensagens de biblioteca caem em log sem stack trace
e precisam se bastar sozinhas. Uma resourcestring unica `%d + %s` serve
ambos os sites: DRY e simetrica.

### D-51.5 — AOwner fora da mensagem (agreed, volta 1)

`PropertyVisibility(AToken: Pointer)` nao recebe `AOwner` (linha `:88`).
Adiciona-lo quebraria a simetria e ampliaria o escopo; o codigo em
`:322-324` ja rejeita explicitamente adicionar `AOwner` ("seria ruido —
AOwner ficaria morto"). A nota permanece no comentario de
`PropertyVisibility`.

### D-51.6 — D-42.2 intocado; supersecao registrada por D-51.1 (agreed, volta 1)

D-42.2 nao e editado. Registro de decisao que se edita deixa de ser
registro. D-42.2 estava **correto na intencao** (fail-loud) e **errado no
mecanismo** (apostou em exaustividade que o Delphi nao faz) — isso e
historia util. A supersecao e **parcial**: a intencao fail-loud de D-42.2
e preservada; o mecanismo e substituido.

### D-51.7 — Ramo inalcancavel, sem teste (agreed, volta 1)

`TMemberVisibility` do Delphi tem exatamente 4 valores em
`System.TypInfo.pas:232` (hoje). O ramo `else raise` e inalcancavel por
dado real. Documentado como tal nos comentarios; nenhum cenario de teste
novo e criado.

### D-51.8 — Backend FPC intocado (agreed, volta 1)

`Source/ModernSyntax.RTTI.FPC.pas` nao muda. La a decisao original
(case de 4 ramos sem else) e valida: FPC confirma exaustividade em
compile-time (`TMemberVisibility` do FPC tem 4 valores em `rtti.pp:308`).
A divergencia de forma entre os dois backends (Delphi: case + else raise;
FPC: case sem else) e correta e documentada.

---

## Alternativas descartadas

| Alternativa | Por que descartada |
|-------------|-------------------|
| **Opcao (b) — pre-inicializar `Result`** | Troca lixo indeterminado por valor errado deterministico; ainda silencioso. Nao entrega fail-loud. |
| **Opcao (c) — `{$WARN NO_RETVAL OFF}` local** | Nao muda comportamento em runtime; lixo 204/16/252/16 persiste. W1035 morto por supressao, nao por conserto. |
| **else com cast `TModernVisibility(Ord(...))`** | Mata W1035 igualmente, mas produz ordinal 4 deterministico e silencioso — exatamente o que D-42.2 queria evitar. |
| **Promover `SDelphiUnknownVisibility` para `interface`** | Sem teste externo que justifique; contraste com PR #58 registrado em D-51.3. |
| **Editar D-42.2** | Registro que se edita deixa de ser registro. D-42.2 preservado; supersecao feita por D-51.1. |
| **Novo cenario para o ramo `else raise`** | Ramo inalcancavel por dado real; custo sem cobertura de caso real. |

---

## Consequencias

- Build dos 4 alvos Delphi passa de 2 W1035 para zero warning.
- Se `TMemberVisibility` do Delphi crescer (ex.: `mvAutomated`), o
  primeiro chamador que topar com o novo valor recebe `EModernRTTIError`
  nomeada em vez de lixo silencioso.
- Backend FPC continua zero-warning, zero mudanca.
- Testes existentes: nenhum quebra (os 2 cenarios de Visibility exercitam
  apenas `mvPublished`, inalterado).
- Contratos publicos: inalterados (`TModernVisibility` com 4 valores;
  assinaturas intactas).
