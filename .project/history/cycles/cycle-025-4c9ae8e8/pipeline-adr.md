---
type: adr
kind: artifact
title: "ADR D-60.1 — else raise EModernRTTIError no PropertyVisibility do backend FPC (issue #60)"
description: "Segundo movimento de D-51.1: estende a guarda fail-loud ao backend FPC. Supercede D-51.8. Registra a distincao SFPCNo* vs SFPCUnknown* como nova convencao."
cycle: "025"
agent: architect
workflow: equipe-bug
node: architect
resource: aefos://run/4c9ae8e8f3b0ca77a166f343e7d3f098
generated:
  by: "equipe-bug@node:architect"
  at: "2026-09-02T00:00:00Z"
tags: [adr, fpc, rtti, visibility, bug, issue-60, modernrtti, cycle-025, d-60-1, d-51-8]
sources:
  - id: investigation-60
    resource: "aefos://run/b33995300ee8f88b88df1cf389b6248b"
    title: "Relatorio de investigacao — Issue #60 (run b33995300ee8f88b88df1cf389b6248b)"
  - id: adr-51
    resource: "/history/cycles/cycle-022-de0826de/pipeline-adr.md"
    title: "ADR D-51.1 — else raise no backend Delphi (ciclo 022)"
---

> **Fonte:** este ADR deriva do relatório de investigação da issue #60
> (run `b33995300ee8f88b88df1cf389b6248b`), acordado com o mantenedor em
> 1 volta de discussão (5 questões). Onde este documento diverge do
> relatório, a divergência é declarada explicitamente.
>
> **Não há divergência.** Todas as decisões abaixo refletem o que foi
> acordado na investigação, sem acréscimo nem omissão.

# ADR D-60.1 — `else raise` no backend FPC (issue #60)

## Contexto

O ciclo 022 (issue #51, ADR D-51.1[^adr-51]) inseriu `else raise EModernRTTIError.CreateFmt`
nos dois sites de Visibility do backend Delphi. O backend FPC ficou intocado por D-51.8,
cuja premissa era: "FPC confirma exaustividade em compile-time — `else` seria código morto."

Essa premissa foi medida na run `b33995300ee8f88b88df1cf389b6248b` e é falsa.[^investigation-60]

| Compilador | Diagnóstico de compilação | Valor para enum não mapeado |
|------------|--------------------------|------------------------------|
| Delphi (4 alvos) | W1035 | 204 · 16 · 252 · 16 |
| FPC 3.2.2 i386 | **nenhum** | **229** |
| FPC 3.2.2 x86_64 | **nenhum** | **0 = `mvPrivate`** |

O FPC compila limpo, sem erro, sem warning, sem hint. No x86_64, o valor não mapeado é
`0`, que é `mvPrivate` — um `TModernVisibility` semanticamente plausível. Silencioso e
convincente é a pior combinação de falha.

Adicionalmente, medição do alcance real revelou que **apenas `mvPublished` chega ao
`PropertyVisibility` pela API pública do FPC** (a RTTI do FPC expõe somente properties
`published`). Três dos quatro ramos do `case` são código morto hoje — não por defeito,
mas porque o dado nunca chega. O `else` não guarda contra dado atual; guarda contra o
`TMemberVisibility` do RTL crescer.

**D-51.8 é supersedido** por D-60.1 para o site `PropertyVisibility` do FPC. A premissa
de exaustividade em compile-time era falsa; o mecanismo de guarda é necessário.

---

## D-60.1 — Mecanismo (agreed, volta 1, Q1 e Q3)

Inserir em `PropertyVisibility` do `Source/ModernSyntax.RTTI.FPC.pas`, antes do `end;`
do `case`:

```pascal
else
  raise EModernRTTIError.CreateFmt(SFPCUnknownVisibility,
    [Ord(TRttiProperty(AToken).Visibility), 'PropertyVisibility']);
```

Cópia literal do Delphi ([^adr-51] D-51.1, `RTTI.Delphi.pas:374-377`) trocando
apenas o nome da resourcestring. O discriminante entre sites é o `%s` do nome da
função — não variação textual entre backends (que seria drift novo).

**Não tocar:** `MethodVisibility` do FPC — já levanta com `SFPCNoVisibility` por design
(`vmtMethodTable` não carrega o dado); este é o segundo padrão semântico, não defeito.

---

## D-60.2 — `resourcestring SFPCUnknownVisibility` na `implementation` (agreed, volta 1, Q2)

Declarar `SFPCUnknownVisibility` na seção `resourcestring` da `implementation` de
`Source/ModernSyntax.RTTI.FPC.pas`, após `SFPCNoParamType` (linha 193), formando o
grupo #60. **Nenhum símbolo novo na interface.**

Segue D-51.3[^adr-51]: a seção `resourcestring` da `implementation` é o lugar correto;
sem teste externo que precisasse do símbolo, não há justificativa para ampliar a
superfície pública.

---

## D-60.3 — Nome `SFPCUnknownVisibility`, não `SFPCNo*` (agreed, volta 1, Q2)

**Nova convenção registrada:** `SFPCNo*` e `SFPCUnknown*` têm semânticas distintas dentro
do backend FPC:

| Prefixo | Semântica | Exemplo |
|---------|-----------|---------|
| `SFPCNo*` | Feature indisponível — o dado **não existe** no RTTI do FPC | `SFPCNoVisibility` (o `vmtMethodTable` não carrega visibilidade de método) |
| `SFPCUnknown*` | Enum mapeado mas sem ramo — o dado **existe**, não bate com nenhum ramo | `SFPCUnknownVisibility` (property tem visibilidade, mas não foi mapeada) |

A simetria que governa o nome é **entre backends** (`SDelphiUnknownVisibility` ↔
`SFPCUnknownVisibility`), não dentro de um backend só. Reciclar `SFPCNoVisibility` ou
criar `SFPCNoPropertyVisibility` misturaria as semânticas. O nome ratificado na
investigação é `SFPCUnknownVisibility`.

---

## D-60.4 — Mensagem cópia literal do Delphi, trocando só `#51` → `#60` (agreed, volta 1, Q3)

```
'TMemberVisibility desconhecido (Ord=%d) em %s — TModernVisibility precisa de novo ramo (issue #60).'
```

Mesma falha, mesma mensagem — discriminante é o `%s` do nome da função. A medição
(ordinal 0 = `mvPrivate` no x86_64) vai para o XMLDoc e para o ADR, não para a
mensagem de runtime: quem recebe a exceção precisa saber o que aconteceu, não ler
um estudo de compilador. Qualquer variação textual entre as cascas seria drift novo,
não informação adicional.

---

## D-60.5 — XMLDoc de `TModernVisibility` entra no PR (agreed, volta 1, Q1)

`Source/ModernSyntax.RTTI.pas:79-85` afirma em presente que "o `case` sem `else` é
correto hoje" e aponta "Ver #60". Após a fix, essa afirmação vira falsa. Mergear ciente
de publicar afirmação errada no XMLDoc público é exatamente o defeito que a issue #62
acabou de custar consertar.

**O XMLDoc entra no PR.** A prosa nova:
- Descreve o que os **dois** backends fazem *após* as guardas: ambos levantam
  `EModernRTTIError` no primeiro chamador.
- Coloca a medição (sem erro, sem warning, sem hint; ordinal 229 no i386, 0 = `mvPrivate`
  no x86_64) **no passado**, como razão histórica da guarda existir.
- Não faz nenhuma afirmação sobre exaustividade em compile-time no FPC (o compilador
  continua sem essa análise; a fix não muda isso).
- Cita D-51.1 (issue #51, Delphi) e D-60.1 (issue #60, FPC).

**Descartado:** deixar o XMLDoc como follow-up. Mergeado com afirmação falsa, fica como
#62 ficou — uma issue inteira para consertar drift que era barato consertar junto.

---

## D-60.6 — Comentário de `PropertyVisibility` cita ambas as issues (agreed, volta 1, Q5)

O comentário do `PropertyVisibility` do FPC (`RTTI.FPC.pas:474-487`) é reescrito para:
- Citar #51 e #60 como primeiro e segundo movimento da mesma decisão D-51.1 estendida.
- Retirar "seria código morto" — a frase era baseada na premissa falsa de exaustividade.
- Descrever a medição (sem erro, sem warning, sem hint; 229/i386, 0/x86_64) como razão
  histórica da guarda, no passado — não como afirmação sobre o presente do compilador.
- Preservar a nota de que **não há ramo `mvAutomated`** no `TMemberVisibility` do FPC
  3.2.2 (`rtti.pp:308`) — esse identificador não existe e incluí-lo não compilaria.
- Preservar a disciplina de labels qualificados (`TMemberVisibility.` para o `case`,
  `TModernVisibility.` para o `Result`) pelos mesmos motivos do backend Delphi.

Citar a linhagem #51 ↔ #60 previne que a próxima arqueologia enfrente o que o D-42.2
enfrentou: comentário que dizia o que decidir sem dizer por quê, com a premissa nunca
medida.

---

## D-60.7 — PR declara plataforma; sem checklist de cobertura humana (agreed, volta 1, Q4)

PR body carrega frase declarativa: "compilado em FPC 3.2.2 x86_64; i386 e os 4 alvos
Delphi ficam com o autor."

**Sem checklist de combinações.** A fronteira é a mesma de todo o ciclo: a fábrica
roda FPC x86_64 e declara isso; i386 e Delphi ficam com o autor, verificados antes do
merge. Adicionar checklist bloqueante inverteria o desenho — a fábrica entrega, o
autor prova depois. Mesma razão de D-62.4 do ciclo 024.

---

## D-60.8 — Nenhum teste novo para o ramo `else raise` (agreed, volta 1, implícito)

O ramo é inalcançável por dado real. O valor vem de `TRttiProperty(AToken).Visibility`,
RTTI real, não injetável. Mesma fronteira declarada da issue #51 (D-51.7[^adr-51]).

O PR declara essa fronteira explicitamente em vez de simular um teste que fingiria
cobrir o ramo.

**Contagem FPC permanece 42** (`grep -c "procedure Test"` em
`Test FPC/EclbrSystem/UTestMS.RTTI.pas`). O cenário
`Scenario_Property_Visibility_Returns_mvPublished` (`UScenarios.RTTI.pas:1086-1111`)
continua exercitando o único ramo alcançável.

---

## Convenções governantes

| ID | Fonte | O que governa nesta issue |
|----|-------|--------------------------|
| D-51.3 | [^adr-51] | `resourcestring` na `implementation` — D-60.2 |
| D-51.4 | [^adr-51] | Mensagem `%d + %s` — D-60.4 |
| D-51.5 | [^adr-51] | Sem `AOwner` — `PropertyVisibility(AToken: Pointer)` não recebe `AOwner` |
| D-51.7 | [^adr-51] | Ramo inalcançável, sem teste — D-60.8 |
| **D-60.3** | **esta run** | **`SFPCNo*` vs `SFPCUnknown*` — nova convenção** |

## Alternativas descartadas

| Alternativa | Por que descartada |
|-------------|-------------------|
| Reaproveitar `SFPCNoVisibility` | Semântica errada: `SFPCNo*` = feature indisponível; aqui o dado existe. Ver D-60.3. |
| Nome `SFPCNoPropertyVisibility` | Mesmo problema semântico; perde a simetria com `SDelphiUnknownVisibility`. Ver D-60.3. |
| Divergir textualmente a mensagem do FPC | Drift novo, não informação adicional. Discriminante já é o `%s`. Ver D-60.4. |
| Deixar XMLDoc como follow-up | Mergearia afirmação falsa no XMLDoc público; custaria issue nova. Ver D-60.5. |
| Checklist de cobertura humana no pipeline | Inverte o desenho fábrica/autor. Ver D-60.7. |
| Teste para o ramo `else raise` | Ramo inalcançável por dado real, não injetável. Ver D-60.8. |
| Tocar `MethodVisibility` do FPC | Já levanta com `SFPCNoVisibility` por design — sem defeito. |
| Tocar backend Delphi | PR #59 já corrigiu. |

## Consequências

- `PropertyVisibility` do FPC passa a falhar loudly se `TMemberVisibility` do RTL crescer.
- O único ramo alcançável por dado real (`mvPublished → TModernVisibility.mvPublished`)
  permanece inalterado — sem regressão esperada no `Scenario_Property_Visibility_Returns_mvPublished`.
- O XMLDoc de `TModernVisibility` passa a descrever o comportamento real dos dois backends
  após as guardas, sem afirmar exaustividade em compile-time no FPC.
- D-51.8 é supersedido para o site `PropertyVisibility` do FPC.
- Contagem FPC: 42 (sem mudança).
- Backend Delphi: intocado.
