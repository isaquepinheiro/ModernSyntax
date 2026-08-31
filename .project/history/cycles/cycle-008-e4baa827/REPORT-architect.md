---
type: cycle-report
kind: report
title: "REPORT — architect (ciclo 008, issue #21)"
description: "Design dossier de issue #21: TModernRTTIField portável nos dois compiladores, um tipo com dois mecanismos por dentro; substitui D12 do ADR do ciclo 006."
status: stable
cycle: "008"
agent: architect
workflow: equipe-feature
node: architect
resource: aefos://run/e4baa827945b3dd3a372629b831d73a9
tags: [modernrtti, rtti, architect, issue-21, fpc, delphi, cycle-report]
generated:
  by: "equipe-feature@node:architect"
  at: "2026-08-31T00:00:00Z"
sources:
  - id: investigation
    title: "REPORT — Issue #21 (investigate run aed3171c29de093b8b839c7e0c028bff)"
  - id: adr-006
    resource: "../cycle-006-0432fa58/pipeline-adr.md"
    title: "ADR — Pilar 1 ModernRTTI (D12 substituída)"
---

# REPORT — architect (ciclo 008, issue #21)

## O que este ciclo entrega

Design de issue #21: `TModernRTTIField` e `TModernRTTIType.GetFields`
deixam de ser Delphi-only (D12 do [ADR ciclo 006](../cycle-006-0432fa58/pipeline-adr.md))
e passam a ter **superfície pública única nos dois compiladores**,
ramificando por dentro (FPC via `vmtFieldTable` tipada + subida por
`ClassParent`; Delphi mantém `TRttiField`).

Quatro artefatos gerados em `.project/pipeline/`:

- [esp](pipeline-esp.md) — 16 regras de negócio (RN-1 a RN-16), 8
  critérios de aceitação, 4 riscos.
- [adr](pipeline-adr.md) — 13 decisões (D1..D13) derivadas verbatim do
  REPORT do `investigate`. D13 substitui D12 do ciclo 006; ADR
  histórico permanece intocado.
- [plan](pipeline-plan.md) — 3 fatias sequenciais (produção; cenário
  compartilhado com fixture de herança; casca fina FPC).
- [task-input](pipeline-task-input.md) — 3 arquivos modificados, 8 CAs
  como checklist executável, receita de build FPC.

## Escopo

**fits.** Uma única demanda tecnicamente coesa: um tipo, dois
mecanismos. As três fatias do plano são fatiadas para revisibilidade,
mas **não** são independentes: sem produção, os testes não linkam;
sem cenário compartilhado, a casca FPC não tem o que chamar. TEST 1
(size) falha — três arquivos, ~50 linhas de mudança líquida.

## Como o REPORT do `investigate` foi consumido

O REPORT é PRESENT. As 13 decisões do [adr](pipeline-adr.md) espelham
as travas das 3 voltas da discussão:

- **Volta 1** — enquadramento (RTTI FPC é padrão vivo, não falta) → D11;
  overload `TValue` opção (a) → D9; nil = array vazio → D7.
- **Volta 2** — `vmtFieldTable` tipada via `PVmt` → D4; property
  `Field[i]` → D5; subida por `ClassParent` → D6; fixture com herança
  → D12.
- **Volta 3** — factories `FromRaw`/`FromRtti` distintas → D3; ordem
  NÃO especificada → D10; cast `string(ShortString)` → D8.

**Divergências em relação ao REPORT:** nenhuma.

## Substituição de D12 (ciclo 006)

D13 do [adr](pipeline-adr.md) registra a **substituição** (não reversão)
de D12 do [ADR ciclo 006](../cycle-006-0432fa58/pipeline-adr.md). O ADR
histórico permanece intocado. Consumidores que se protegiam com
`{$IFDEF FPC}` para não referenciar `TModernRTTIField` continuam
compilando (o `{$IFDEF}` fica desnecessário, mas não quebra).

Este é o **segundo caso da família** em que "não existe no FPC" se
revelou "existe por outro caminho" — o primeiro foi o Pilar 3 (issue
#10, ciclo 005), com `TObject.MethodAddress` no lugar de
`TRttiMethod.Invoke`. A nota do REPORT é registrada como conclusão do
ciclo: **"a conclusão 'impossível' merece uma segunda medição antes de
virar decisão"**.

## Pontos de atenção para o `developer`

1. **Nunca aritmética de ponteiro** com a constante `vmtFieldTable` —
   D4 do [adr](pipeline-adr.md). Usar `PVmt(LClass)^.vFieldTable`.
2. **Nunca `LTab^.Fields[i]`** como array — D5 do adr. Usar
   `LTab^.Field[i]` (property que caminha corretamente).
3. **Sempre `string(LEntry^.Name)`** — D8 do adr. Sem o cast, warning
   ou perda em não-ASCII.
4. **Sempre subir por `ClassParent`** — D6 do adr. Sem subida, D6
   falha e o teste da fatia 2 (`Length = 2` exato) pega.
5. **Factories distintas por branch** — D3 do adr. `FromRaw` no FPC,
   `FromRtti` no Delphi. Nomes iguais + assinaturas diferentes sob
   `{$IFDEF}` é armadilha.
6. **Fixture Delphi não medida neste ciclo** — RSK-1 do [esp](pipeline-esp.md).
   Se `dcc32` reclamar de `{$M+}` em bloco com herança, alternar para
   `{$M+}` só em `TInner`.
7. **`rm -rf <out>`** antes de cada build FPC — SKILL.md trap 2.

## Referências

- [pipeline-esp.md](pipeline-esp.md)
- [pipeline-adr.md](pipeline-adr.md)
- [pipeline-plan.md](pipeline-plan.md)
- [pipeline-task-input.md](pipeline-task-input.md)
- [ADR ciclo 006 (D12 substituída)](../cycle-006-0432fa58/pipeline-adr.md)
