---
type: flow-feedback
kind: report
title: "FLOW-FEEDBACK — ciclo 021 (issue #56)"
description: "Friction encontrada pelo developer no ciclo 021: o ESP/ADR/plan pediram Format(SModernRTTINilHandle, ...) no cenario compartilhado sem prever que a resourcestring estava em implementation (privada); build primeiro rebuild falhou; developer promoveu ao interface (decisao local coerente com ADR). Sugestao: architect declarar explicitamente exposicao ou nao da resourcestring."
cycle: "021"
agent: developer
workflow: equipe-bug
node: implement
resource: aefos://run/09743779c7c9860b5fa380f6979d94ca
tags: [flow-feedback, cycle-021, issue-56, architect-friction, resourcestring]
generated:
  by: "equipe-bug@node:implement"
  at: "2026-09-02T16:24:00Z"
---

# FLOW-FEEDBACK — Ciclo 021

## Friction observada

**Node afetado:** implement (developer).
**Origem:** entre `architect` (ESP/ADR/plan) e `implement`.

O ESP §2.2, o ADR D-56.2/D-56.3 e o plano Passo 2/Passo 3 pedem o
seguinte padrao no cenario compartilhado
`Test Shared/EclbrSystem/UScenarios.RTTI.pas`:

```pascal
if LMsg <> Format(SModernRTTINilHandle, ['<nome>']) then
  Fail(Format('Mensagem de <nome> incorreta: "%s"', [LMsg]));
```

O plano tambem afirma explicitamente (§Passo 1):
*"Referencia: `SModernRTTINilHandle` existe em linhas 892-893; nenhuma
`resourcestring` nova."*

Em `Source/ModernSyntax.RTTI.pas` a `resourcestring SModernRTTINilHandle`
esta declarada em `implementation` (linhas 892-893) — logo, e privada
a `ModernSyntax.RTTI` e nao pode ser referenciada por consumidor algum.
No primeiro rebuild o FPC devolveu seis erros:

```
UScenarios.RTTI.pas(1461,21) Error: Identifier not found "SModernRTTINilHandle"
... (mais cinco identicos)
```

O ESP/ADR nao consideraram essa consequencia. As opcoes praticas eram:

1. Repetir o literal `'handle nao inicializado...'` no cenario — quebra
   fonte unica de verdade.
2. Voltar `Pos(...)` no cenario — contradiz D-56.2/D-56.3 do ADR.
3. Promover `SModernRTTINilHandle` para o `interface` de `ModernSyntax.RTTI`.

Executei a opcao 3 (documentada em [REPORT-developer](REPORT-developer.md) §
"Ajuste tecnico") porque foi a unica coerente com o ADR. Mas essa e uma
mudanca de superficie publica que o ESP dizia *nao* haver ("nenhuma
mudanca de API publica"). O implementador nao deveria decidir sozinho se
o contrato de erro passa a ser publico.

## Sugestao de mudanca de workflow

**Onde:** no ESP e/ou ADR, secao de escopo (Passo 1 do plan).

**O que:** quando o cenario compartilhado depende de um simbolo do
`Source/`, o architect deve declarar explicitamente **se esse simbolo
esta na interface publica**. Se estiver privado, decidir de antemao:
promover ou duplicar o literal — nao deixar para o developer descobrir
no build.

**Concretamente:** adicionar na checklist do `architect` (nos
templates de ESP/ADR) um item:

> [ ] Para cada simbolo do `Source/` referenciado por
> `Test Shared/EclbrSystem/*.pas`, verificar (`grep -n
> "^interface\|^implementation" | ...`) que ele esta no `interface`. Se
> nao estiver, decidir promocao vs. literal duplicado no proprio ADR.

Custo: baixo (dois `grep` por simbolo novo). Beneficio: elimina a
decisao ad-hoc no `implement`, e o architect fica dono da mudanca de
superficie publica quando ela e necessaria.

**Alternativa:** o node `plan` (arquiteto) rodar um smoke-build antes de
publicar o handoff. Custo mais alto, mas pega a classe inteira desses
defeitos (nao so `resourcestring`).

## Escala

Nao foi bloqueante — resolvi na hora com decisao coerente com o ADR —
mas obrigou o developer a tomar decisao de superficie publica, que
excede o seu papel. Se ocorrer em issue mais complexa, com multiplos
simbolos escondidos em `implementation`, o custo cresce e a decisao
fica pior.
